#!/usr/bin/env bash

# The `git submodule` command makes it easy to update all submodules with a 
# call to `git submodule -q foreach git pull -q origin master`.
#
# But this only applies to submodules, that is situations where git repositories
# are part of one larger repository. When deploying with Puppet modules I ran
# into a the situation where it was not optimal to include all modules into
# one umbrella repository, which made `git submodule` unusable.
#
# This script accomplishes the same goal by searching for all `.git` directories
# within a base directory, and updating each repository based on `branch` and
# `remote` arguments.
#
# Usage:
#
# ```sh
# /update-gitmodules.sh -d <base_dir> -r <remote name> -b <branch name>
# # And with real world variables:
# /update-gitmodules.sh -d /vagrant/puppet/modules -r github -b stable
# ```
#
# The real world example would go to `/vagrant/puppet/modules` and execute
# `git pull github stable:stable` from each git repository root within the
# `/vagrant/puppet/modules/*` root directory.

this_file=`basename "$0"`
executing_args="$@"

_git_dirs=''

base_dir="./"
git_remote="origin"
git_branch="master"
parse_options () {
	while getopts "b:d:r:" opt; do
		case $opt in
			b)
				git_branch="$OPTARG"
				;;
			d)
				base_dir="$OPTARG"
				;;
			r)
				git_remote="$OPTARG"
				;;
		esac
	done
} ; parse_options $@

set -o nounset
set -o errtrace
set -o errexit
set -o pipefail

log () {
	printf "$*\n"
}

error () {
	log ""
	log "***WARNING***"
	log "The following error occured while executing '${this_file} ${executing_args}'"
	log "Error: " "$*"
	log ""
	exit 1
}

help () {
	echo "Usage is './${this_file} <module_directory>'"
}

before_exit () {
	# Works like a finally statement
	# Code that must always be run goes here
	return
} ; trap before_exit EXIT

# Application functions

verify_base_dir_exists () {
	if [[ ! -d "$base_dir" ]]; then
		error "The base directory does not exist, '${base_dir}'"
	fi
}

verify_base_dir_is_absolute () {
	local original_pwd=`pwd`
	cd "$base_dir"
	base_dir=`pwd`
	cd "$original_pwd"
}

find_git_directories () {
	_git_dirs=`find ${base_dir} -type d -name .git`

	if [[ -z "$_git_dirs" ]]; then
		log "Could not find any .git directories in the base dir '${base_dir}'"
		exit 0
	fi
}

_update_repository () {
	git_repo_base_dir="$1"

	if ! cd "$git_repo_base_dir" ; then
		error "Unable to cd into git repository base directory '${git_repo_base_dir}'"
	fi

	if ! git pull "$git_remote" "$git_branch":"$git_branch" ; then
		error "Unable to update git directory 'git pull ${git_remote} ${git_branch}:${git_branch}'"
	fi

	echo $git_repo_base_dir
}

update_each_repository () {
	local IFS=$'\n'
	local original_pwd=`pwd`

	for dir in $_git_dirs ; do
		local git_repo_base_dir=`dirname $dir`
		_update_repository "$git_repo_base_dir"
	done

	cd "$original_pwd"
}

# Application execution

verify_base_dir_exists
verify_base_dir_is_absolute
find_git_directories
update_each_repository
