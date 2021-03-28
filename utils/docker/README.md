# docker

This directory contains helpers needed to generate Docker-compatible containers for running kraken.

`Dockerfile` builds a standard container image.
`Dockerfile.vbox` builds a vbox-enabled container image.

# Building

We will use `buildah` and `podman` for all examples.  If you would rather use `docker` the command translations should be easy.

To build the images:

1. Start from the root of the `kraken-layercake` source tree.
2. Run the build (this can take a few minutes):
   ```bash
   $ buildah bud -f utils/docker/Dockerfile -t layercake
   ...
   Getting image source signatures
   Copying blob 0f7b3ff8b310 skipped: already exists  
   Copying blob bedb4aa6455c done  
   Copying config 4fcfed2306 done  
   Writing manifest to image destination
   Storing signatures
   --> 4fcfed2306c
   ...
   ```
   This will build an image named `layercake`.
   To build for VirtualBox and Libvirt support, use `-f utils/docker/Dockerfile.virt` instead.

# Running

You should be able to start your container with:

```bash
$ podman run --name layercake layercake
```

Or, to background:
```bash
$ podman run --name layercake -d layercake
```

To make this useable you'll need:
1. You'll want to have a `layer0-kmod.xz` in `/tftp/<arch>/<platform>`.  This provides kernel modules your nodes need (see: `build-layer0-kmod.sh`)
2. You'll probably also want to have a more realistic `layer0-config.xz`.  There's a stub in `/tftp/layer0/config`.  Add files to it, then run:
   ```bash
   $ cd /tftp/layer0/config
   $ find . | cpio -oc | xz -c > /tftp/<arch>/<platform>/layre0-config.xz
   ```
   You'll probably at least want to set up some more secure ssh keys.
3. You'll need a `vmlinuz` kernel image in `/tftp/<arch>/<platform>`.  Make sure the version matches your `kmod` bundle.
4. You'll want to create a populated `/etc/kraken/state.json` with your kraken state.
5. You may want to update `/etc/kraken/config.yaml` with your preferences.

Finally, you'll need to use `host` networking (so tftp & dhcp will work), and you'll need to run as root (so you can use privileged ports).

Note: We're working on a rootless version, check back for that.

Practically speaking, the best way is probably to keep a local copy of the `/tftp` an `/etc/kraken` that get bind mounted into the container.  You can always copy the existing ones out to have a starting point.

For example:
```
[layercake]$ podman cp layrecake:/tftp tftp
[layercake]$ podman cp layrecake:/etc/kraken etc
[layercake]$ podman stop layercake
[layercake]$ podman rm layercake
<modify files in tftp and etc and become root>
[layercake]# podman run -d --name layercake -v etc:/etc/kraken -v tftp:/tftp --network=host kraken-layercake
```

With appropriately configured `tftp` and `etc` directories, this should boot your cluster.

Note: you may need to have other things like, `powerapi` (or `vboxapi`) and `ceph/rbd` up and configured to have a functional system. See other guides for a more complete overview to how to configure these.