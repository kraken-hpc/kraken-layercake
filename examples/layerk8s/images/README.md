# Images

This directory contains some example image configs:

- `centos-base` provides a base SystemD-based CentOS image to build on top of. 
- `centos-k3s` builds on `centos-base` to create k3s agents.
- `centos-slurm` builds on `centos-base` to create Slurm compute nodes.

Images can be built wiht the `build-layer1.sh` script.  You will want to update the "Config" section of the script with some of your site-specific values (e.g. Ceph credentials).

The `build-layer1.sh` script will build an image based on the Dockerfile in a directory.  It will then create an RBD object and write a SquashFS to that object.

Usage: `build-layer1.sh <directory> [<image_name>]`

If `<image_name>` isn't specified, it will default to the name of the directory.

Once images are built, they can be directly consumed by the `imageapi` to load layer1 images in the cluster.
