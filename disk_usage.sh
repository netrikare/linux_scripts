#!/usr/bin/env bash
DISKS=$(awk '$4 ~ /^sd.$/ { print $4 }' /proc/partitions)

for d in $DISKS
do
	echo "/dev/$d"
	HOURS=$(sudo smartctl -A /dev/$d | awk '/^  9/ { print $10 }')
	GBYTES=$(sudo smartctl -A /dev/$d | awk '/^241/ { print ($10 * 512) * 1.0e-9 }')

	if [ $HOURS ]; then
		echo Total hours:$'\t\t' $HOURS [h]
	fi
	if [ $GBYTES ]; then
		GPH=$(echo $GBYTES $HOURS | awk '{ print $1/$2 }')
		echo GB written:$'\t\t' $GBYTES [GB]
		echo GB written per hour:$'\t' $GPH [GB/h]
	fi

	echo ""
done

