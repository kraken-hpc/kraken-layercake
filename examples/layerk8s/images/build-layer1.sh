#!/bin/bash

### This script will build images based on dockerfiles in a directory
### Usage: buildlayer1 <directory> [<image_name>]
### If <image_name> isn't specified, the directory name will be used.

### BEGIN: Config -- make sure these values are set for your system!  ###
RBD_MON="192.168.3.253"
RBD_ID="admin"
RBD_SECRET="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
RBD_POOL=rbd
### END: Config ###

# Exit on any non-zero exit code
set -o errexit

# Exit on any unset variable
set -o nounset

# Pipeline's return status is the value of the last (rightmost) command
# to exit with a non-zero status, or zero if all commands exit successfully.
set -o pipefail

if [ $# -lt 1 ]; then
	echo "usage: $0 <dir> <name>"
	exit 1
fi
img=$(basename $1)
name=$img
if [ $# -eq 2 ]; then
	name=$2
fi

cd $img
# build image
echo "Building $img..."
buildah bud -t $img
# create working container & mount
echo "Mounting working container for $img..."
buildah from --name $img-wc $img
mnt_dir=$(buildah mount $img-wc)

echo "Creating RBD object $name for $img..."
kubectl -n rook-ceph exec -it deploy/rook-ceph-tools -- rbd create --image-feature layering --image-shared -s 100G $name

echo "Attaching image..."
modprobe rbd
$HOME/go/bin/rbd device map --monitor "$RBD_MON" --pool "$RBD_POOL" --image $name --id "$RBD_ID" --secret "$RBD_SECRET" 
rbd_dev=$($HOME/go/bin/rbd device list | grep $name | awk '{print $1}')
echo "Mapped to /dev/rbd$rbd_dev"

echo "Makeing squashfs..."
mksquashfs "$mnt_dir" "/dev/rbd$rbd_dev" -noI -noX -noappend

echo "Detaching /dev/rbd$rbd_dev..."
$HOME/go/bin/rbd device unmap -d "$rbd_dev"

echo "Cleaning up working mount/container..."
buildah unmount $img-wc
buildah rm $img-wc

echo "Done.  Your image is available as $name ."
