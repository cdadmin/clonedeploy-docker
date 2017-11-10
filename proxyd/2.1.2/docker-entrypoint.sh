#!/bin/bash

echo "[settings] 
listen-dhcp=$LISTEN_DHCP
listen-proxy=$LISTEN_PROXY 
listen-apple-bsdp=$LISTEN_APPLE_BSDP
allow-all-mac=true
interface=$INTERFACE
next-server=$NEXT_SERVER
clonedeploy-base-url=$CLONEDEPLOY_BASE_URL
check-web-reservations=$CHECK_WEB_RESERVATIONS
check-tftp-cluster=$CHECK_TFTP_CLUSTER
tftp-polling-interval=$TFTP_POLLING_INTERVAL
bios-bootfile=$BIOS_BOOTFILE
efi32-bootfile=$EFI32_BOOTFILE
efi64-bootfile=$EFI64_BOOTFILE
apple-efi-boot-file=$APPLE_EFI_BOOT_FILE
apple-boot-file=$APPLE_BOOT_FILE
apple-root-path=$APPLE_ROOT_PATH
apple-vendor-specific-information=$APPLE_VENDOR_SPECIFIC_INFORMATION
server-identifier-override=$SERVER_IDENTIFIER_OVERRIDE" > /opt/cd_proxyd/config.ini

exec "$@"