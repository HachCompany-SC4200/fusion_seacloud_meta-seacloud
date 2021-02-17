#!/usr/bin/env bash
#
# Copyright (C) 2019 Witekio
# Author: Dragan Cecavac <dcecavac@witekio.com>
#

set -e

current_bank_appfs_encryption()
{
	mount_point="/mnt/fcc/set"

	# As the mount point is not mounted as ecryptfs yet, being able to find the pattern "nebulaURL"
	# in the file /mnt/fcc/set/nebula.properties_hachtest is an indication that the system is not encrypted
	cat $mount_point/nebula.properties_hachtest | grep -c "nebulaURL" > /dev/null && encrypted=false || encrypted=true

	if [ $encrypted == false ]; then
		# Ensure that job logs don't cause storage overflow
		#/bin/garbage-collector.sh $mount_point

		# Backup data if partition is not yet encrypted
		backup_dir=`mktemp -d`
		cp -rpf $mount_point/. $backup_dir
	fi

	# Encrypt the partition
	/etc/ecryptfs-mount.sh $mount_point

	if [ $encrypted == false ]; then
		set +e
		rm -rf $mount_point/{*,.*}
		set -e
		cp -rpf $backup_dir/. $mount_point
		rm -rf $backup_dir
	fi
}

other_bank_appfs_encryption()
{
	other_bank_mount_point=`mktemp -d`

	# Mount the other bank appfs
	if mount | grep "ubi0:appfs-1" > /dev/null ; then
		other_bank_device="/dev/ubi0_4"
	elif mount | grep "ubi0_5" > /dev/null ; then
		other_bank_device="/dev/ubi0_4"
	elif mount | grep "ubi0:appfs-0" > /dev/null ; then
		other_bank_device="/dev/ubi0_5"
	elif mount | grep "ubi0_4" > /dev/null ; then
		other_bank_device="/dev/ubi0_5"
	else
		other_bank_device=""
	fi

	if [[ $other_bank_device != "" ]]; then
		mount -t ubifs $other_bank_device $other_bank_mount_point

		# As the mount point is not mounted as ecryptfs yet, being able to find the pattern "nebulaURL"
		# in the file /mnt/fcc/set/nebula.properties_hachtest is an indication that the system is not encrypted
		cat $other_bank_mount_point/set/nebula.properties_hachtest | grep -c "nebulaURL" > /dev/null && encrypted=false || encrypted=true

		if [ $encrypted == false ]; then
			# Ensure that job logs don't cause storage overflow
			#/bin/garbage-collector.sh $other_bank_mount_point/set

			# Backup data if partition is not yet encrypted
			backup_dir=`mktemp -d`
			cp -rpf $other_bank_mount_point/set/. $backup_dir

			# Encrypt the partition
			/etc/ecryptfs-mount.sh $other_bank_mount_point/set
			set +e
			rm -rf $other_bank_mount_point/set/{*,.*}
			set -e
			cp -rpf $backup_dir/. $other_bank_mount_point/set
			rm -rf $backup_dir
			umount $other_bank_mount_point/set
		fi

		umount $other_bank_mount_point
	fi
}

current_bank_appfs_encryption
other_bank_appfs_encryption
