#!/usr/bin/env bash

while getopts "d:m:" opt; do
  case "$opt" in
    d)
      DRIVE_ID=$OPTARG
      if [ -z "$DRIVE_ID" ]; then
        errcho "Drive ID is not set."
        exit 1
      fi
      ;;
    m)
      MOUNT_POINT=$OPTARG
      if [ -z "$MOUNT_POINT" ]; then
        errcho "Mount point is not set."
        exit 1
      fi
      ;;
    \?)
      errcho "Use -v to set volume name, -m for mount point."
      exit 0
      ;;
  esac
done

if [[ ${DRIVE_ID} = *"No EBS volumes found"* ]]; then
    echo ${DRIVE_ID}
    exit 1
fi

DRIVE_FS=$(sudo file -s ${DRIVE_ID})
if [[ ${DRIVE_FS} = *"ext4"* ]];then
    echo "ext4 fs is in place"
else
    echo "EBS volume is empty. Will format it with ext4 fs."
    sudo mkfs -t ext4 ${DRIVE_ID}
fi

if mount | grep ${DRIVE_ID} > /dev/null; then
    echo "Drive is already mounted"
else
    sudo mkdir -p ${MOUNT_POINT}
    sudo mount ${DRIVE_ID} ${MOUNT_POINT}
fi

DRIVE_UUID=$(sudo blkid -s UUID -o export ${DRIVE_ID} | tail -n1)

grep ${DRIVE_UUID} /etc/fstab
if [ $? -eq 0 ]; then
    echo "Drive is present in fstab, no action required"
else
    echo "Drive is not in fstab, adding it there"
    echo -e "${DRIVE_UUID} \t\t ${MOUNT_POINT} \t\t ext4 \t\t defaults,nofail \t\t 0 \t\t 2" | sudo tee -a /etc/fstab > /dev/null
fi
