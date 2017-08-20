#!/bin/bash
echo "##### Cryptsetup $TARGET_PART_ROOT ######"

echo "# Encrypt root"
cryptsetup luksFormat -c aes-xts-plain64 -s 512 -h sha512 "$TARGET_PART_ROOT"

echo "# Open partition"
cryptsetup open --type luks "$TARGET_PART_ROOT" $ENC_NAME
