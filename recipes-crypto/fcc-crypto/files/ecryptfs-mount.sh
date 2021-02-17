#!/usr/bin/env bash
#
# Copyright (C) 2019 Witekio
# Author: Dragan Cecavac <dcecavac@witekio.com>
#
# Usage: ecryptfs-mount.sh mounting-point
#

set -e

function fetch_key_fragment() {
	fragment="/sys/vf610-ocotp/$1"
	key_fragment=`cat ${fragment}`

	while [[ ${key_fragment} == "0" ]]; do
		# Generate random non-zero 32-bit key fragment
		key_fragment_file=`mktemp`
		dd if=/dev/urandom of=${key_fragment_file} bs=4 count=1
		key_fragment=`hexdump ${key_fragment_file} | head -n 1 | awk '{print $2$3}'`
		rm ${key_fragment_file}

		# Burn the key fragment to the corresponding general purpose fuse
		echo ${key_fragment} > ${fragment}
	done

	# Build the key using the key fragments
	key="${key}${key_fragment}"
}

function fetch_encryption_key() {
	fetch_key_fragment "MAC2"
	fetch_key_fragment "MAC3"
	fetch_key_fragment "GP1"
	fetch_key_fragment "GP2"

	key_file=`mktemp`
	echo "passphrase_passwd=${key}" > ${key_file}
}

function init()
{
	fetch_encryption_key

	options="key=passphrase:passphrase_passwd_file=$key_file"
	options="$options,ecryptfs_enable_filename_crypto=no"
	options="$options,ecryptfs_cipher=aes"
	options="$options,ecryptfs_key_bytes=32"
	options="$options,ecryptfs_passthrough=no"
	options="$options,no_sig_cache"

	mkdir -p /mnt/fcc/set
}

init
keyctl link @u @s
mount.ecryptfs $1 $1 -o $options

# Delete the key
rm ${key_file}
