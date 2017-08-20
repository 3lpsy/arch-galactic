#!/bin/bash

echo "##### Partition $TARGET_DISK ######"
echo "# partining disk"
(
echo o # Create a new empty DOS partition table
echo Y
echo n # Add a new partition
echo 1 # Partition number
echo   # First sector (Accept default: 1)
echo +512MiB  # Last sector (Accept default: varies)
echo ef00 # EFI SYSTEM
echo n # Add a new partition
echo 2 # Second Partiion
echo # First Sector (Accept default: next available)
echo # Last sector (Accept default: end of disk)
echo bf00 # Solaris Root
echo w # Write changes
echo Y
) | gdisk "$TARGET_DISK"

echo "# creating fat filesystem on $TARGET_PART_BOOT"

mkfs.fat -F32 "$TARGET_PART_BOOT"
