#!/bin/sh

### Script which purpose is to try to recover data from inconsistently
### encrypted FCC partitions.
### A format issue in the passphrase generation lead to some partitions
### containing files encrypted with different keys, generated from different
### passphrases. Thus, files that were encrypted with the wrongly formatted
### passphrase are not readable anymore.
###
### This script tries to decrypt the FCC partition using both passphrase
### format and construct the union of files that are readable either with one
### format, or the other. Files that are readable with neither format are
### considered clear files and are directly copied to the sanitized encrypted
### FCC partition.

# Script terminology:
# The variable 'brokencopy' refers to a copy of the encrypted FCC partition from
# which we are trying to recover the data
# The variable 'fixedcopy' refers to the temporary directory in which recovered
# data are stored before copying them into the actual encrypted FCC partition (if
# no error occured).

ENCRYPTED_PATH="/mnt/fcc/encrypted"

error() {
	printf "error: %s\n" "$@"
	exit 1
}

check_fcc_encryption_enabled() {
	if [ "$(mount | grep -c "${ENCRYPTED_PATH%/} .* ecryptfs")" = "0" ]
	then
		error "FCC partition ${ENCRYPTED_PATH} is not encrypted"
	fi
}

fetch_key_fragment() {
	fragment="/sys/vf610-ocotp/$1"
	key_fragment=`sed -e 's/^[ \t]*//g;s/[ \t]*$//g' "${fragment}"`
	key_fragment=`printf "%08x" "0x${key_fragment#0x}"`
	key="${key}${key_fragment}"
}

old_fetch_key_fragment() {
	fragment="/sys/vf610-ocotp/$1"
	key_fragment=`cat ${fragment}`
	key="${key}${key_fragment}"
}

set_ecryptfs_options() {
	key_file=`mktemp`
	echo "passphrase_passwd=${key}" > ${key_file}

	options="key=passphrase:passphrase_passwd_file=$key_file"
	options="$options,ecryptfs_enable_filename_crypto=no"
	options="$options,ecryptfs_cipher=aes"
	options="$options,ecryptfs_key_bytes=16"
	options="$options,ecryptfs_passthrough=no"
	options="$options,no_sig_cache"
}

ecryptfs_mount()
{
	key=""

	fetch_key_fragment "MAC2"
	fetch_key_fragment "MAC3"
	fetch_key_fragment "GP1"
	fetch_key_fragment "GP2"

	set_ecryptfs_options

	mount.ecryptfs $1 $1 -o $options
	rm ${key_file}
}

old_ecryptfs_mount()
{
	key=""

	old_fetch_key_fragment "MAC2"
	old_fetch_key_fragment "MAC3"
	old_fetch_key_fragment "GP1"
	old_fetch_key_fragment "GP2"

	set_ecryptfs_options

	mount.ecryptfs $1 $1 -o $options
	rm ${key_file}
}

# The encryption is disabled before the copy because otherwise the files encrypted with the wrong key won't
# be copied. This behaviour is exploited in the function recover_encrypted_data() to recover files that were
# previously encrypted with different keys.
copy_inconsistent_encrypted_fcc() {
	brokencopy="$(mktemp -d -p /tmp/)" || error "could not create a temp directory to hold a copy of the current FCC partition"

	printf "info: umount the ecryptfs layer for %s (disable encryption)\n" "${ENCRYPTED_PATH}"
	umount "${ENCRYPTED_PATH}" || error "could not unmount ${ENCRYPTED_PATH}"

	cp -a "${ENCRYPTED_PATH}"/* "${brokencopy}"
	printf "info: raw encrypted data from %s copied into %s\n" "${ENCRYPTED_PATH}" "${brokencopy}"

	/etc/ecryptfs-mount.sh "${ENCRYPTED_PATH}"
	printf "info: ecryptfs layer for %s remounted (encryption enabled)\n" "${ENCRYPTED_PATH}"
}

# Tries to recover the files from the copy previously made.
# When triyng to copy a file that were encrypted with an other key than the one currently active, no action is performed. Therefore,
# we try to copy the whole content of the copy of the FCC partition to a directory which will hold the recovered data multiple times
# using different passphrase that could be used in the past.
recover_encrypted_data() {
	fixedcopy="$(mktemp -d -p /tmp/)" || error "could not create a temp directory to hold the data recovered from the current FCC partition"
	/etc/ecryptfs-mount.sh "${fixedcopy}"

	printf "info: decrypt the inconsistent FCC directory (%s) using the old passphrase format\n" "${brokencopy}"
	old_ecryptfs_mount "${brokencopy}"
	cp -a "${brokencopy}"/* "${fixedcopy}/" 2> /dev/null
	find "${fixedcopy}/" ! -type d | sed -e "s%${fixedcopy}/%${brokencopy}/%g" | xargs rm -f
	find "${fixedcopy}/" -type d | sed -e "s%${fixedcopy}/%${brokencopy}/%g" | sort -r | xargs rmdir 2> /dev/null
	printf "info: copied data from the inconsistent FCC directory (%s) that were readable with the old passphrase format to the sanitized FCC directory (%s)\n" "${brokencopy}" "${fixedcopy}"
	printf "info: umount the ecryptfs layer for the inconsistent FCC directory (%s) that were using the old passphrase format\n" "${brokencopy}"
	umount "${brokencopy}" || error "could not unmount the ecryptfs layer for the inconsistent FCC directory (${brokencopy})"

	printf "info: decrypt the inconsistent FCC directory (%s) using the new passphrase format\n" "${brokencopy}"
	ecryptfs_mount "${brokencopy}"
	cp -a "${brokencopy}"/* "${fixedcopy}/" 2> /dev/null
	find "${fixedcopy}/" ! -type d | sed -e "s%${fixedcopy}/%${brokencopy}/%g" | xargs rm -f
	find "${fixedcopy}/" -type d | sed -e "s%${fixedcopy}/%${brokencopy}/%g" | sort -r | xargs rmdir 2> /dev/null
	printf "info: copied data from the inconsistent FCC directory (%s) that were readable with the new passphrase format to the sanitized FCC directory (%s)\n" "${brokencopy}" "${fixedcopy}"
	printf "info: umount the ecryptfs layer for the inconsistent FCC directory (%s) that were using the new passphrase format\n" "${brokencopy}"
	umount "${brokencopy}" || error "could not unmount the ecryptfs layer for the inconsistent FCC directory (${brokencopy})"

	# If neither of the keys above worked, consider the rest as clear data
	cp -a "${brokencopy}"/* "${fixedcopy}/" 2> /dev/null
	find "${fixedcopy}/" ! -type d | sed -e "s%${fixedcopy}/%${brokencopy}/%g" | xargs rm -f
	find "${fixedcopy}/" -type d | sed -e "s%${fixedcopy}/%${brokencopy}/%g" | sort -r | xargs rmdir 2> /dev/null
	printf "info: copied data from the inconsistent FCC directory (%s) that could not be read with ecryptfs layers to the sanitized FCC directory (%s) as if they were unencrypted files\n" "${brokencopy}" "${fixedcopy}"

	if [ -e "${brokencopy}" ]
	then
		error "the inconsistent FCC directory (${brokencopy}) is not empty, some data were not recovered from the old partition"
	fi
}

install_recovered_data() {
	printf "info: umount the ecryptfs layer for %s (disable encryption)\n" "${ENCRYPTED_PATH}"
	umount "${ENCRYPTED_PATH}" || error "could not unmount ${ENCRYPTED_PATH}"

	rm -rf "${ENCRYPTED_PATH:?}"/*
	printf "info: %s cleared\n" "${ENCRYPTED_PATH}"

	/etc/ecryptfs-mount.sh "${ENCRYPTED_PATH}"
	printf "info: ecryptfs layer for %s remounted (encryption enabled)\n" "${ENCRYPTED_PATH}"

        cp -a "${fixedcopy}/"* "${ENCRYPTED_PATH}" 2> /dev/null
        find "${ENCRYPTED_PATH}/" ! -type d | sed -e "s%${ENCRYPTED_PATH}%${fixedcopy}/%g" | xargs rm -f
        find "${ENCRYPTED_PATH}/" -type d | sed -e "s%${ENCRYPTED_PATH}%${fixedcopy}/%g" | sort -r | xargs rmdir 2> /dev/null
	printf "info: moved the recovered data from the sanitized FCC directory (%s) to %s\n" "${fixedcopy}" "${ENCRYPTED_PATH}"

	umount "${fixedcopy}" || error "could not unmount the ecryptfs layer of the sanitized FCC directory (${fixedcopy})"
	rmdir "${fixedcopy}" || error "sanitized FCC directory (${fixedcopy}) is not empty, some data were not copied to the FCC partition"
}

check_fcc_encryption_enabled
copy_inconsistent_encrypted_fcc
recover_encrypted_data
install_recovered_data
sync
