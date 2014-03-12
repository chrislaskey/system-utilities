#!/bin/bash

# Reset all Puppetdb data by running TRUNCATE <tables> CASCADE on puppetdb tables
# 
# This is a hack. PuppetDB is still a bit buggy, holding on to old resources
# and not updating new resources.
#
# For a kinder solution that does not involve nuking the entire database see:
# https://ask.puppetlabs.com/question/88/how-can-i-purge-exported-resources-from-puppetdb/?answer=417#post-id-417
#
# (this still left stale SSH key resources in PuppetDB 1.5)

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

if ! sudo -u postgres pg_dump puppetdb > "$dumpfile"; then
	echo ""
	echo "Error exporting data using pg_dump. See output above"
	exit 1
fi

if ! sudo -u postgres psql puppetdb -c "TRUNCATE TABLE ${tables} CASCADE"; then
	echo ""
	echo "Error truncating table. See output above"
	exit 1
fi

echo "Truncated puppetdb tables: ${tables}"
exit 0
