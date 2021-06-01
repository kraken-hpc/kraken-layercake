# centos-base image

This image is intended to provide a good base to build on for traditional(ish) CentOS based images.

## Usage

You'll want to customize a few things in this directory:

1. Setup kernel modules:
    You need to set `KMOD_VER` in the `Dockerfile`.  You also need to copy your kernel module directory into this directory, e.g.:

    ```bash
    cp -avL /lib/mouldes/4.18.0-240.22.1.el8_3.x86_64 .
    ```

2. Setup SSH keys:
    You should copy your SSH public key to `id_rsa.pub`.  Note: this can contain multiple entries. These keys will have pubkey auth to ssh as root to the node.

3. Setup other custom config:
    The following files can be set up:
    - `chrony.conf` for time sync config
    - `group`/`passwd` for user/group config
    - `resolv.conf` for DNS config

Then you can build your image with `build-layer1 centos-base`.

You should be able to boot nodes into this image to make sure everything in your base image checks out, but it won't do much useful other than run SSH.