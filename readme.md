About
================================================================================

A collection of system-utilities written primarily in bash, though there may
be a few in sh, python, or perl.

update-hostname.sh
--------------------------------------------------------------------------------

A simple shell script for updating the system hostname in Debian based systems.
Helps a lot when deploying virtual machines, especially since I prefer fresh
installs and automated deployment instead of backups and golden images. Testing in
Debian Squeeze (6.0+) and Ubuntu Server (10.04+).

update-gitmodules.sh
--------------------------------------------------------------------------------

The `git submodule` command makes it easy to update all submodules with a 
call to `git submodule -q foreach git pull -q origin master`.

But this only applies to submodules, that is situations where git repositories
are part of one larger repository. When deploying with Puppet modules I ran
into a the situation where it was not optimal to include all modules into
one umbrella repository, which made `git submodule` unusable.

This script accomplishes the same goal by searching for all `.git` directories
within a base directory, and updating each repository based on `branch` and
`remote` arguments.

Usage:

```sh
/update-gitmodules.sh -d <base_dir> -r <remote name> -b <branch name>
# And with real world variables:
/update-gitmodules.sh -d /vagrant/puppet/modules -r github -b stable
```

The real world example would go to `/vagrant/puppet/modules` and execute
`git pull github stable:stable` from each git repository root within the
`/vagrant/puppet/modules/*` root directory.

Puppet Utilities
--------------------------------------------------------------------------------

### bootstrap-puppetmaster.sh ###

Adds the Puppet Labs official package repository, then installs the latest
puppetmaster and puppetdb packages.

### recreate-ssl-certs.sh ###

Recreates SSL certs on a Puppet Master. Includes syncing PuppetDB SSL certs too.

### truncate-puppetdb.sh ###

Clear all data from an existing PuppetDB installation. Creates a data dump prior
to truncating all tables. Useful for early versions of PuppetDB which can
sometimes store stale data indefinitely.


License
================================================================================

All code is released under MIT license. See the attached LICENSE.txt file for
more information, including commentary on license choice.
