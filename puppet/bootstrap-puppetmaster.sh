#!/usr/bin/env bash

this_file=`basename "$0"`
deb_file_url="http://apt.puppetlabs.com/puppetlabs-release-wheezy.deb"
deb_file_name="puppetlabs-release-wheezy.deb"
deb_file_dir="/tmp"
deb_file_path="${deb_file_dir}/${deb_file_name}"

set -o nounset
set -o errtrace
set -o errexit
set -o pipefail

# General functions

log () {
	printf "$*\n"
}

error () {
	log "ERROR: " "$*\n"
	exit 1
}

verify_root_privileges () {
	if [[ $EUID -ne 0 ]]; then
		fail "Requires root privileges."
	fi
}

before_exit () {
	# Works like a finally statement
	# Code that must always be run goes here
	if [[ -f "$deb_file_path" ]]; then
		/bin/rm "$deb_file_path"
	fi
} ; trap before_exit EXIT

# Application functions

exit_if_already_completed () {
	if dpkg -s puppetlabs-release > /dev/null 2>&1; then
		log "NOTICE: Puppetlabs release package already installed. Exiting successfully."
		exit 0
	fi
}

get_deb_file () {
	if ! wget -P "$deb_file_dir" "$deb_file_url"; then
		error "Failed to download file ${deb_file_url}"
	fi
}

install_deb_file () {
	if ! dpkg -i "$deb_file_path"; then
		error "Failed to install file ${deb_file_path}"
	fi
}

update_apt () {
	if ! apt-get update; then
		error "Apt failed to update"
	fi
}

install_puppetmaster () {
	if ! apt-get install puppetmaster; then
		error "Apt failed to install puppetmaster"
	fi
}

install_puppetdb () {
	if ! apt-get install puppetdb; then
		error "Apt failed to install puppetdb"
	fi
}

# Application execution

verify_root_privileges
exit_if_already_completed
get_deb_file
install_deb_file
update_apt
install_puppetmaster
install_puppetdb
