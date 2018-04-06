#!/usr/bin/env bash
#
# Attaches ENI with 'NAT' description to CoreOS AWS instance
#

ENI_LABEL="NAT"
META_URL="http://169.254.169.254"
AWS_CLI="docker run --rm balaclavalab/awscli"
ZONE=$(curl -s ${META_URL}/latest/meta-data/placement/availability-zone)
REGION=${ZONE::-1}

ENI_ID=$(${AWS_CLI} --region ${REGION} ec2 describe-network-interfaces \
                    --filters Name="description",Values="${ENI_LABEL}" \
                              Name="availability-zone",Values="${ZONE}" \
                    --query 'NetworkInterfaces[*].{ID:NetworkInterfaceId}' \
                    --output text)

INSTANCE_ID=$(curl -s ${META_URL}/latest/meta-data/instance-id)

${AWS_CLI} --region ${REGION} ec2 attach-network-interface --network-interface-id ${ENI_ID} --instance-id ${INSTANCE_ID} --device-index 1

# It takes some time for ENI to be attached. So
# here is some magic to make sure that is up.
for i in {0..30}; do
  sudo ip link set eth0 down && \
  sudo ip link set eth1 up && break
  sleep 1
done
