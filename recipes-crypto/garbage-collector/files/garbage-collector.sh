#!/usr/bin/env bash
#
# Copyright (C) 2020 Witekio
# Author: Dragan Cecavac <dcecavac@witekio.com>
#
# This script ensures that appfs partition size doesn't
# get overfilled in a way that it could not be encrypted or that
# all the available space of an encrypted partition is used by job and log files.
#
# This is achieved by deleting job files older than ~6 months (180 days)
# and by deleting log files one by one until a certain threshold is reached.
# The threshold is lower in case of an unencrypted appfs, because due to
# ecryptfs overhead and reduced compression rate, encrypted files will in
# general use more storage.
# In the particular use case where these statistics were observed,
# usage grew from 55% to 99% after encryption. By deleting a several log files
# and repeating the test, it grew from 42% to 81%.
# appfs should always be left with enough free space to store new files
# and that's the main reason why the usage is not maximized.
# That's also the reasoning for setting $allowed_unencrypted_fcc_usage
# to a value lower than 55%, as it reduces the chance to overflow the storage during
# encryption. After all, the size which will be used depends on the particular
# data set, and it could even lead to an increase of e.g. 52% to 100%.
#
# It's important to point out that if there is and overflow caused by files
# in a different location (not $mounting_point/log or $mounting_point/job/active),
# this script will not provide the desired functionality and should be adjusted.
#
# Usage garbage-collector.sh [mounting-point]
#

if [ -z "$1" ]; then
	mounting_point="/mnt/fcc"
else
	mounting_point="$1"
fi

function clean_outdated_jobs()
{
	job_dir="$mounting_point/job/active"
	days_before_archiving="180"

	if [ -d "$job_dir" ]; then
		# Delete outdated files
		find $job_dir -type f -mtime +$days_before_archiving -exec rm {}  \;
		sync
	fi
}

function get_usage()
{
	usage=`df -h | grep "$mounting_point" | tail -n 1 | sed -n "s/ \+/ /gp" | cut -d " " -f5 | cut -d "%" -f1`
}

function clean_overflowing_logs()
{
	log_dir="$mounting_point/log"
	allowed_encrypted_fcc_usage="82"
	allowed_unencrypted_fcc_usage="45"

	if [ -d "$log_dir" ]; then
		if grep -qs "$mounting_point ecryptfs" /proc/mounts; then
			# FCC encrypted
			allowed_usage="$allowed_encrypted_fcc_usage"
		else
			# FCC not yet encrypted
			allowed_usage="$allowed_unencrypted_fcc_usage"
		fi

		logs=($(ls -rt $log_dir))
		for i in "${logs[@]}"
		do
			get_usage

			if [ "$usage" -gt "$allowed_usage" ]; then
				log_file="$log_dir/$i"
				rm $log_file
				sync
			else
				break
			fi
		done
	fi
}

clean_outdated_jobs
clean_overflowing_logs
