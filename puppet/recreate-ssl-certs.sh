#!/usr/bin/env bash

# This script fixes SSL certs on a Puppetmaster server by removing existin
# certs and regenerating new ones.

hostname=`hostname -f`
timestamp=`date -d "today" +"%Y%m%d-%H%M"`
puppet_cert_dir="/var/lib/puppet/ssl"
puppetdb_dir="/etc/puppetdb"
puppetdb_cert_dir="${puppetdb_dir}/ssl"
puppetdb_user="puppetdb"
puppetdb_group="puppetdb"
puppetdb_private_key_source="${puppet_cert_dir}/private_keys/${hostname}.pem"
puppetdb_public_key_source="${puppet_cert_dir}/certs/${hostname}.pem"
puppetdb_ca_key_source="${puppet_cert_dir}/certs/ca.pem"
if test -d "$puppetdb_dir"; then
	has_puppetdb=true
else
	has_puppetdb=false
fi

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

# before_exit () {
# 	# Works like a finally statement
# 	# Code that must always be run goes here
# 	if [[ -f "$deb_file_path" ]]; then
# 		/bin/rm "$deb_file_path"
# 	fi
# } ; trap before_exit EXIT

# Application functions

remove_existing_certs_from_certificate_authority () {
	log "Removing existing certs from puppet ca"
	if ! puppet cert --clean --all; then
		error "Failed remove existing certs from puppet ca"
	fi
}

stop_service_puppetmaster () {
	log "Stopping puppetmaster service"
	if ! invoke-rc.d puppetmaster stop; then
		error "Failed to stop puppetmaster service"
	fi
}

stop_service_puppetdb () {
	if ! $has_puppetdb; then
		return 0
	fi

	log "Stopping puppetdb service"
	if ! invoke-rc.d puppetdb stop; then
		error "Failed to stop puppetdb service"
	fi
}

remove_puppet_cert_directory () {
	log "Removing puppet cert directory"
	if ! test -d "$puppet_cert_dir"; then
		log "WARNING: Could not find puppet cert directory, ${puppet_cert_dir}"
		return 0
	fi

	if ! mv "$puppet_cert_dir" "${puppet_cert_dir}.bak-${timestamp}"; then
		error "Failed to remove puppet cert directory"
	fi
}

remove_puppetdb_cert_directory () {
	if ! $has_puppetdb; then
		return 0
	fi

	log "Removing puppetdb cert directory"
	if ! test -d "$puppetdb_cert_dir"; then
		log "WARNING: Could not find puppetdb cert directory, ${puppetdb_cert_dir}"
		return 0
	fi

	if ! mv "$puppetdb_cert_dir" "${puppetdb_cert_dir}.bak-${timestamp}"; then
		error "Failed to remove cert directory"
	fi
}

start_service_puppetmaster () {
	log "Starting puppetmaster service and regenerating keys"
	if ! invoke-rc.d puppetmaster start; then
		error "Failed to start puppetmaster service"
	fi
}

create_puppetdb_cert_directory () {
	if ! $has_puppetdb; then
		return 0
	fi

	log "Creating puppetdb cert directory"
	if ! mkdir "$puppetdb_cert_dir"; then
		error  "Could not create puppetdb cert directory, ${puppetdb_cert_dir}"
	fi

	if ! chmod 0750 "$puppetdb_cert_dir"; then
		error  "Could not create puppetdb cert directory, ${puppetdb_cert_dir}"
	fi
}

fix_puppetdb_cert_directory_file_permissions () {
	if ! $has_puppetdb; then
		return 0
	fi

	log "Creating puppetdb public.pem"
	if ! chown -R "$puppetdb_user":"$puppetdb_group" "$puppetdb_cert_dir"; then
		error  "Could not update user and group puppetdb file permissions for puppetdb cert directory, ${puppetdb_cert_dir}"
	fi
}

create_puppetdb_private_key () {
	if ! $has_puppetdb; then
		return 0
	fi

	log "Creating puppetdb private.pem"
	if ! test -f "$puppetdb_private_key_source"; then
		error  "Could not find private key for puppetdb, ${puppetdb_private_key_source}"
	fi

	if ! cp -p "$puppetdb_private_key_source" "${puppetdb_cert_dir}/private.pem"; then
		error  "Could not copy private key for puppetdb, ${puppetdb_private_key_source}"
	fi

	if ! chmod 0640 "${puppetdb_cert_dir}/private.pem"; then
		error  "Could not update file permissions for puppetdb private key, ${puppetdb_private_key_source}"
	fi
}

create_puppetdb_public_key () {
	if ! $has_puppetdb; then
		return 0
	fi

	log "Creating puppetdb public.pem"
	if ! test -f "$puppetdb_public_key_source"; then
		error  "Could not find public key for puppetdb, ${puppetdb_public_key_source}"
	fi

	if ! cp -p "$puppetdb_public_key_source" "${puppetdb_cert_dir}/public.pem"; then
		error  "Could not copy public key for puppetdb, ${puppetdb_public_key_source}"
	fi

	if ! chmod 0640 "${puppetdb_cert_dir}/public.pem"; then
		error  "Could not update file permissions for puppetdb public key, ${puppetdb_public_key_source}"
	fi
}

create_puppetdb_ca_key () {
	if ! $has_puppetdb; then
		return 0
	fi

	log "Creating puppetdb ca.pem"
	if ! test -f "$puppetdb_ca_key_source"; then
		error  "Could not find ca key for puppetdb, ${puppetdb_ca_key_source}"
	fi

	if ! cp -p "$puppetdb_ca_key_source" "${puppetdb_cert_dir}/ca.pem"; then
		error  "Could not copy ca key for puppetdb, ${puppetdb_ca_key_source}"
	fi

	if ! chmod 0640 "${puppetdb_cert_dir}/ca.pem"; then
		error  "Could not update file permissions for puppetdb ca key, ${puppetdb_ca_key_source}"
	fi
}

fix_puppetdb_cert_directory_file_permissions () {
	if ! $has_puppetdb; then
		return 0
	fi

	log "Updating user and group file permissions for puppetdb cert directory"
	if ! chown -R "$puppetdb_user":"$puppetdb_group" "$puppetdb_cert_dir"; then
		error  "WARNING: Could not update user and group puppetdb file permissions for puppetdb cert directory, ${puppetdb_cert_dir}"
	fi
}

start_service_puppetdb () {
	if ! $has_puppetdb; then
		return 0
	fi

	log "Starting puppetdb service"
	if ! invoke-rc.d puppetdb start; then
		error "Failed to start puppetdb service"
	fi
}

# Application execution

verify_root_privileges
remove_existing_certs_from_certificate_authority
stop_service_puppetmaster
stop_service_puppetdb
remove_puppet_cert_directory
remove_puppetdb_cert_directory
start_service_puppetmaster
create_puppetdb_cert_directory
fix_puppetdb_cert_directory_file_permissions
create_puppetdb_private_key
create_puppetdb_public_key
create_puppetdb_ca_key
fix_puppetdb_cert_directory_file_permissions
start_service_puppetdb
