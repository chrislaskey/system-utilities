#!/bin/bash

# Drop all PuppetDB database tables by running DROP <tables> CASCADE.
# 
# Since this is a very destructive action, must pass '--force' argument for
# script to execute.

tables="${tables} catalog_resources,"
tables="${tables} catalogs,"
tables="${tables} certname_catalogs,"
tables="${tables} certname_facts,"
tables="${tables} certname_facts_metadata,"
tables="${tables} certnames,"
tables="${tables} edges,"
tables="${tables} latest_reports,"
tables="${tables} reports,"
tables="${tables} resource_events,"
tables="${tables} resource_params,"
tables="${tables} schema_migrations" #Note: no trailing , on last table name

timestamp=$(date +"%m_%d_%Y")
dumpfile="./puppetdb-data-backup-${timestamp}.sql"

if ! [[ $1 == '--force' ]]; then
	echo ""
	echo "Are you sure you want to DROP all database tables?"
	echo "If so, use the --force flag to proceed."
	echo ""
	exit 1
fi

if ! sudo -u postgres pg_dump puppetdb > "$dumpfile"; then
	echo ""
	echo "Error exporting data using pg_dump. See output above"
	exit 1
fi

if ! sudo -u postgres psql puppetdb -c "DROP TABLE ${tables} CASCADE"; then
	echo ""
	echo "Error dropping table. See output above"
	exit 1
fi

echo "Dropped puppetdb tables: ${tables}"
exit 0
