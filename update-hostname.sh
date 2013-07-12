#!/usr/bin/env bash

# Renames host on Debian/Ubuntu systems

this_file=`basename "$0"`
new_fqdn="$1"
new_hostname="$2"

current_fqdn=`hostname -f`
current_hostname=`hostname`

# option_force=
# parse_options () {
# 	while getopts "f" opt; do
# 		case $opt in
# 			f)
# 				option_force="true"
# 				;;
# 		esac
# 	done
# } ; parse_options $@

set -o nounset
set -o errtrace
set -o errexit
set -o pipefail

log () {
	printf "$*\n"
}

error () {
	log "ERROR: " "$*\n"
	log "***WARNING***"
	log "An error occured while changing the hostname. Verify the integrity of /etc/hostname, /etc/hosts and the hostname command."
	log "***WARNING***"
	exit 1
}

help () {
	echo "Usage is './${this_file} <fqdn> <hostname>'"
}

# Application functions

before_exit () {
	# Works like a finally statement
	# Code that must always be run goes here
	return
} ; trap before_exit EXIT

verify_root_privileges () {
	if [[ $EUID -ne 0 ]]; then
		error "Requires root privileges."
	fi
}

verify_input () {
	if [[ -z ${new_fqdn} || -z ${new_hostname} ]] ; then
		help
		exit 1
	fi

	if [[ ${new_fqdn} == ${current_fqdn} ]] ; then
		log "NOTICE: New fqdn/hostname matches current hostname. Exiting without error: '${new_fqdn}' '${current_fqdn}'."
		exit 0
	fi
}

update_live_hostname () {
	if ! hostname "${new_hostname}"; then
		error "Failed to update live hostname value using the hostname command."
	fi
}

update_hostname_file () {
	if ! echo "${new_hostname}" > /etc/hostname; then
		error "Failed to update hostname file: /etc/hostname."
	fi
}

update_hosts_file () {
	# Use two commands with interim string replacement to
	# prevent hostname value, which is a subset of the
	# FQDN, from altering modifying part of the FQDN
	# value.

	if ! sed -i"_backup" -e "s/${current_fqdn}/NEW_FQDN/g" -e "s/${current_hostname}/NEW_HOSTNAME/g" /etc/hosts; then
		cp /etc/hosts_backup /etc/hosts
		error "Failed to update hosts file: /etc/hosts"
	fi

	if ! sed -i'' -e "s/NEW_FQDN/${new_fqdn}/g" -e "s/NEW_HOSTNAME/${new_hostname}/g" /etc/hosts; then
		error "Failed to update hosts file: /etc/hosts"
	fi
}

verify_input
verify_root_privileges
update_live_hostname
update_hostname_file
update_hosts_file
