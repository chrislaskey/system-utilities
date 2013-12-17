#! /bin/bash

# When cloning virtual machines the hypervisor will change the VMs MAC address
# automatically. RedHat distributions store MAC address information and bind
# network interfaces to them. This causes the ethX number to increase each time
# the system is cloned.
#
# This script fixes this behavior by:
# - Removing the MAC address information from the kernel
# - Removing MAC and UUID addresses from eth0 configuration file
# - Installing this script as an init script to be executed on system
#   start/stop/resets.
#
# Combined this ensures networking on all cloned VMs will work automatically.
#
# From: http://www.envision-systems.com.au/blog/2012/09/21/fix-eth0-network-interface-when-cloning-redhat-centos-or-scientific-virtual-machines-using-oracle-virtualbox-or-vmware/

kernel_rules="/etc/udev/rules.d/70-persistent-net.rules"
eth0_cfg="/etc/sysconfig/network-scripts/ifcfg-eth0"

init_file="/etc/rc.d/init.d/fixVirtualMachineNetworking.sh"
init_rc0="/etc/rc0.d/S12fixVirtualMachineNetworking.sh"
init_rc3="/etc/rc3.d/S12fixVirtualMachineNetworking.sh"
init_rc5="/etc/rc5.d/S12fixVirtualMachineNetworking.sh"
init_rc6="/etc/rc6.d/S12fixVirtualMachineNetworking.sh"

# Fix networking files

if test -f "$kernel_rules"; then
	rm -rf "$kernel_rules"
fi

if test -f "$eth0_cfg"; then
	sed -i'' -e '/HWADDR/d' "$eth0_cfg"
	sed -i'' -e '/UUID/d' "$eth0_cfg"
	grep "# Note:" "$eth0_cfg" || echo "# Note: HWADDR and UUID values automatically removed on reboot by ${init_file}" >> "$eth0_cfg"
fi

# Install as init script

if ! test -f "$init_file"; then
	mv "$0" "$init_file"
fi

if ! test -L "$init_rc0"; then
	ln -s "$init_file" "$init_rc0"
fi

if ! test -L "$init_rc3"; then
	ln -s "$init_file" "$init_rc3"
fi

if ! test -L "$init_rc5"; then
	ln -s "$init_file" "$init_rc5"
fi

if ! test -L "$init_rc6"; then
	ln -s "$init_file" "$init_rc6"
fi
