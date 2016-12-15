#!/usr/bin/env bash
#
# Attaches EBS to CoreOS AWS instance
#

errcho() { echo "$@" 1>&2; }

# Check if there are any arguments
if [ $# -eq 0 ]; then
  errcho "Use -v to set volume name."
  exit 1
fi

# A POSIX variable reset in case getopts has been used previously in the shell.
OPTIND=1

VOLUME_NAME=""
while getopts "v:" opt; do
  case "$opt" in
    v)
      VOLUME_NAME=$OPTARG
      if [ -z "$VOLUME_NAME" ]; then
        errcho "Volume name is not set."
        exit 1
      fi
      ;;
    \?)
      errcho "Use -v to set volume name."
      exit 0
      ;;
  esac
done

META_URL="http://169.254.169.254"
ZONE=$(curl -s ${META_URL}/latest/meta-data/placement/availability-zone)
REGION=${ZONE::-1}
AWS_CLI="$(which docker) run --rm balaclavalab/docker-awscli --region ${REGION}"

EBS_ID=$(${AWS_CLI} ec2 describe-volumes \
                    --filters Name="availability-zone",Values="${ZONE}" \
                              Name=tag-value,Values="*${VOLUME_NAME}*" \
                    --query 'Volumes[*].{ID:VolumeId}' \
                    --output text)

if [ -z $EBS_ID ]; then
  errcho "No EBS volumes found with pattern: ${VOLUME_NAME}."
  exit 0
fi

INSTANCE_ID=$(curl -s ${META_URL}/latest/meta-data/instance-id)
EBS_CHECK=$(${AWS_CLI} ec2 describe-volumes --volume-ids $EBS_ID --query 'Volumes[*].{ID:State}' --output text)

if [ "$EBS_CHECK" == "in-use" ]; then
  DRIVE_ID=$(ls /dev/xvd* | grep -o '[[:alpha:]]' | tail -n 1)
  DRIVE_ID="/dev/xvd${DRIVE_ID}"
  blockdev --setra 32 $DRIVE_ID
  echo $DRIVE_ID
  exit 0
else
  DRIVE_ID=$(ls /dev/xvd* | grep -o '[[:alpha:]]' | tail -n 1 | tr "0-9a-z" "2-9a-z")
  DRIVE_ID="/dev/xvd${DRIVE_ID}"
  ${AWS_CLI} ec2 attach-volume --volume-id ${EBS_ID} --instance-id ${INSTANCE_ID} --device ${DRIVE_ID} > /dev/null
fi

# It takes some time for EBS to be attached. So
# here is some magic to make sure that EBS is in place.
for i in {0..60}; do
   if [ "$EBS_CHECK" == "in-use" ]; then
     break
   else
     sleep 1
     EBS_CHECK=$(${AWS_CLI} ec2 describe-volumes --volume-ids $EBS_ID --query 'Volumes[*].{ID:State}' --output text)
   fi
done

blockdev --setra 32 $DRIVE_ID
echo $DRIVE_ID
