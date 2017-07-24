#!/bin/bash

PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/bin
export PATH
 
blockprefix=sd
xenprefix=xvd
stripes=0
lvmdevs=
vg=ec2
lv=ephemeral
ec2_api_url="http://169.254.169.254/latest"
 
if ! vgs ${vg} >/dev/null 2>&1; then
  ephdevs=$( curl -s -XGET ${ec2_api_url}/meta-data/block-device-mapping/ |grep ephemeral )
 
  for tdev in $ephdevs; do
    dev=$( curl -s -XGET ${ec2_api_url}/meta-data/block-device-mapping/$tdev )
    dev="/dev/"${dev/$blockprefix/$xenprefix}
    if [ -b "$dev" ]; then
      stripes=$[ $stripes + 1 ]
      lvmdevs=${lvmdevs}" $dev"
    fi
  done
fi
 
pvcreate $lvmdevs
vgcreate ${vg} $lvmdevs
lvcreate -n ${lv} -l 100%FREE -i $stripes ${vg}
 
mkfs.ext4 -L ${lv} /dev/mapper/${vg}-${lv}
mkdir -p /opt/${lv}
mount /dev/mapper/${vg}-${lv} /opt/${lv}
 
# local initialization
if [ -f /etc/default/ec2-prepare-ephemeral-storage ]; then
  . /etc/default/ec2-prepare-ephemeral-storage
fi
 
exit 0