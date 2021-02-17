#!/bin/sh

ENCRYPTED_PATH="/mnt/fcc/encrypted"

if [ "$(mount | grep -c "${ENCRYPTED_PATH%/} .* ecryptfs")" = "0" ]
then
        echo "FCC partition ${ENCRYPTED_PATH} is not encrypted"
        exit 0
fi

tmplist="$(mktemp)"
find "${ENCRYPTED_PATH}" | xargs touch 2>&1 | cut -d ':' -f 2 | tee "${tmplist}"
wc -l "${tmplist}" | cut -d ' ' -f 1 | xargs printf "The files listed above could not be read, total: %d files\n"

rm "${tmplist}"
