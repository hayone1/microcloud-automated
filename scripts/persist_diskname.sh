#!/bin/bash

# Ensure the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# Backup the current fstab
cp /etc/fstab /etc/fstab.bak

# Get the list of all disk partitions
partitions=$(lsblk -o NAME,UUID -r | grep -E '^sd' | awk '{print $1,$2}')

echo "Updating /etc/fstab with UUIDs..."

while IFS= read -r partition; do
    name=$(echo "$partition" | awk '{print $1}')
    uuid=$(echo "$partition" | awk '{print $2}')

    # Skip partitions without UUID
    if [[ -z $uuid ]]; then
        continue
    fi

    # Get the current mount point
    mount_point=$(grep "^/dev/$name" /etc/fstab | awk '{print $2}')

    if [[ -n $mount_point ]]; then
        # Update the fstab entry with UUID
        sed -i "s|^/dev/$name|UUID=$uuid|" /etc/fstab
        echo "Updated /dev/$name to UUID=$uuid in fstab"
    fi
done <<< "$partitions"

echo "All applicable entries in /etc/fstab have been updated with UUIDs."

# Optionally, print the new fstab for verification
echo "New /etc/fstab:"
cat /etc/fstab
