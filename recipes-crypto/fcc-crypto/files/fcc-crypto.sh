#!/usr/bin/env bash
#
# Copyright (C) 2019 Witekio
# Author: Dragan Cecavac <dcecavac@witekio.com>
#

# Mount point of the active FCC partition. It can be changed if the default mount
# point should have an other name.
MOUNT_POINT="/mnt/fcc"

# Name of the directory under the FCC partition that holds encrypted data
# Its name should not be changed as it would require extra work on systems on
# which encryption is already set up (manually rename the directory with the
# new name and updating all the symbolic links to encrypted data)
ENCRYPTED_DIRECTORY="encrypted"

# List of files or directories to encrypt
# Each time this script is run, at least once per boot, this list is checked and files or
# directories belonging to this list and not yet encrypted become encrypted
#
# Only files or directories under /mnt/fcc should be listed here and no subdirectories of
# an already listed directory should be in the list
# The name of the directory containing the encrypted data ($MOUNT_POINT/$ENCRYPTED_DIRECTORY)
# should NOT be listed here
# Directory names must NOT have a trailing slash (/) appended to them
#
# The directory /mnt/fcc/set is required to be encrypted, as this script relies on an
# heuristic based on this assumption to figure out if encryption is already set up or not
DATA_TO_ENCRYPT="\
	/mnt/fcc/set \
	/mnt/fcc/etc \
	/mnt/fcc/log \
"

set -e

# Compute the prefix to prepend to the path of an encrypted data before creating a symbolic link to it.
# This allows to avoid the creation of symbolic links based on absolute paths, which causes issues when
# the appfs partition is mounted on a temporary mount point (which is needed in this script and during
# the update process).
symlink_path_prefix_for()
{
	path="$1"
	prefix=""

	remaining="$path/"
	while [ "$remaining" != "" ]; do
		filename="${remaining%%/*}"
		remaining="${remaining#*/}"

		if [ "$filename" = ".." ]; then
			prefix="${prefix#../}"
		elif [ -n "$filename" ] && [ "$filename" != "." ]; then
			prefix="../$prefix"
		fi
	done

	printf "%s" "${prefix#../}"
}

enable_encryption_on()
{
	fcc_mountpoint="${1%/}"

	# Ensure that the directory to encrypt exists and encrypt it
	mkdir -p "$fcc_mountpoint/$ENCRYPTED_DIRECTORY"
	/etc/ecryptfs-mount.sh "$fcc_mountpoint/$ENCRYPTED_DIRECTORY"

	for data in $DATA_TO_ENCRYPT; do
		data_relativepath="${data#${MOUNT_POINT%/}/}"
		data_on_mountpoint="$fcc_mountpoint/${data_relativepath%/}"

		[ "$data_relativepath" != "$data" ] && is_data_path_in_appfs=true || is_data_path_in_appfs=false

		if [ -e "$data_on_mountpoint" ] && $is_data_path_in_appfs; then
			# Silence eventual errors with "true" to prevent the script to stop
			# If realpath fails, it means that the targeted data doesn't exist. "data_realpath" will be empty and next loop iteration will follow
			data_realpath="`realpath "$data_on_mountpoint" || true`"
			encrypted_data_path="$fcc_mountpoint/$ENCRYPTED_DIRECTORY/$data_relativepath"

			# This second check on the file location is meant to handle symbolic links
			# This ensures that no file outside of the appfs will be put in the encrypted container, even through symbolic links
			[ "${data_realpath#$fcc_mountpoint/}" != "$data_realpath" ] && is_data_realpath_in_appfs=true || is_data_realpath_in_appfs=false
			[ "${data_realpath#$fcc_mountpoint/${ENCRYPTED_DIRECTORY%/}/}" = "$data_realpath" ] && is_not_already_encrypted=true || is_not_already_encrypted=false

			if [ -e "$data_realpath" ] && [ ! -e "$encrypted_data_path" ] && $is_data_realpath_in_appfs && $is_not_already_encrypted; then
				# Duplicate intermediate tree in the encrypted container if needed and move the data to encrypt in it
				encrypted_data_parent_path="`dirname "$encrypted_data_path"`"

				mkdir -p "$encrypted_data_parent_path"
				mv "$data_realpath" "$encrypted_data_path"

				# Create links to the encrypted data from both real former location and from eventual former symbolic link
				path_prefix="`symlink_path_prefix_for "$data_relativepath"`"
				encrypted_data_relative_location="$path_prefix$ENCRYPTED_DIRECTORY/${data_relativepath%/}"

				ln -sn "$encrypted_data_relative_location" "$data_realpath"
				ln -snf "$encrypted_data_relative_location" "$data_on_mountpoint"
			fi
		fi
	done
}

current_bank_appfs_encryption()
{
	if [ "`mount | grep -c "${MOUNT_POINT%/}/$ENCRYPTED_DIRECTORY .* ecryptfs" || true`" = "0"  ]; then
		# As the mount point is not mounted as ecryptfs yet, being able to find the pattern "nebulaURL"
		# in the file nebula.properties_hachtest is an indication that the system is not encrypted
		grep -c "nebulaURL" "$MOUNT_POINT/set/nebula.properties_hachtest" > /dev/null && encrypted=false || encrypted=true

		# Handle the case in which the reserved directory used for encryption
		# already exists. It would be renamed with a free name generated by mktemp, to backup data
		backuped_unencrypted_data=false
		if [ $encrypted == false ] && [ -e "$MOUNT_POINT/$ENCRYPTED_DIRECTORY" ]; then
			# The flag "-u" means "dry-run"; only the name is generated
			new_name=`mktemp -u "$MOUNT_POINT/$ENCRYPTED_DIRECTORY.XXXXXX"`
			mv "$MOUNT_POINT/$ENCRYPTED_DIRECTORY" "$new_name"
			backuped_unencrypted_data=true
		fi

		enable_encryption_on "$MOUNT_POINT"

		# Restore the unencrypted backuped data into the final encrypted directory, and remove the backuped one
		# || : is added to let script continue in case execution of the commad causes any error
		if [ $backuped_unencrypted_data == true ]; then
			cp -rpf $new_name/. $MOUNT_POINT/$ENCRYPTED_DIRECTORY || :
			rm -rf $new_name || :
		fi

	fi
}

current_bank_appfs_encryption
