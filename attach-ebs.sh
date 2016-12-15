#!/usr/bin/env bash
#
# Attaches EBS to CoreOS AWS instance
#

# Check if there are any arguments
if [ $# -eq 0 ]; then
  echo "Use -v to set volume name."
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
        echo "Volume name is not set."
        exit 1
      fi
      ;;
    \?)
      echo "Use -v to set volume name."
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
  echo "No EBS volumes found with pattern: ${VOLUME_NAME}."
  exit 0
fi

INSTANCE_ID=$(curl -s ${META_URL}/latest/meta-data/instance-id)
DRIVE_LETTER=$(ls /dev/xvd* | grep -o '[[:alpha:]]' | tail -n 1 | tr "0-9a-z" "2-9a-z")

${AWS_CLI} ec2 attach-volume --volume-id ${EBS_ID} --instance-id ${INSTANCE_ID} --device /dev/xvd${DRIVE_LETTER}

# It takes some time for EBS to be attached. So
# here is some magic to make sure that EBS is in place.
EBS_CHECK=$(${AWS_CLI} ec2 describe-volumes --volume-ids $EBS_ID --query 'Volumes[*].{ID:State}' --output text)
for i in {0..60}; do
   if [ "$EBS_CHECK" == "in-use" ]; then
     echo "Volume ${EBS_ID} attached."
     break
   else
     sleep 1
     EBS_CHECK=$(${AWS_CLI} ec2 describe-volumes --volume-ids $EBS_ID --query 'Volumes[*].{ID:State}' --output text)
   fi
done
