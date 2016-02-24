#!/usr/bin/env bash
#
# Attaches ENI with 'NAT interface' description to CoreOS AWS instance
#

META_URL="http://169.254.169.254"
AWS_CLI="$(which docker) run --rm juris/awscli"
ZONE=$(curl -s ${META_URL}/latest/meta-data/placement/availability-zone)
REGION=${ZONE::-1}

ENI_ID=$(${AWS_CLI} --region ${REGION} ec2 describe-network-interfaces \
                    --filters Name="description",Values="NAT interface" \
                              Name="availability-zone",Values="${ZONE}" \
                    --query 'NetworkInterfaces[*].{ID:NetworkInterfaceId}' \
                    --output text)

INSTANCE_ID=$(curl -s ${META_URL}/latest/meta-data/instance-id)

${AWS_CLI} --region ${REGION} ec2 attach-network-interface --network-interface-id ${ENI_ID} --instance-id ${INSTANCE_ID} --device-index 1

# It takes some time for ENI to be attached. So
# here is some magic to make sure that is up.
IP_CMD=$(which ip)
for i in {0..30}; do
  sudo $IP_CMD link set eth0 down && \
  sudo $IP_CMD link set eth1 up && break
  sleep 1
done
