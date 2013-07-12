#!/usr/bin/env bash

# A `git submodule -q foreach git pull -q origin master` for situations where
# there are many potential git repositories within a given directory but are
# not part of a larger, single git repositories.

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

verify_base_dir () {
	if [[ ! -d "$base_dir" ]]; then
		error "The base directory does not exist, '${base_dir}'"
	fi
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
		error "Unable to update git directory 'git pull {$git_remote} ${git_branch}:{$git_branch}'"
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

verify_base_dir
find_git_directories
update_each_repository
