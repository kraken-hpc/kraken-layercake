# Scripts

This directory contains a few helper scripts for the layerk8s project.

- `aliases.sh` contains some useful bash aliases.  Just `source aliases.sh` to be able to use `ceph`, `rbd`, `pm`, and `krakenctl` behave like native commands (though they all run in containers).
- `clean-vda.sh` can be used to wipe a disk so that rook-ceph sees it as a clean, blank disk.  Note: this is *dangerous*, you can easily wipe out a disk you didn't intend to.
- `delete-from-registry.sh` is intended to delete images from the internal Docker registry.
- `k3s.sh` is a simple wrapper around the `k3sinstall.sh` that makes sure config files in `rancher` are copied into place prior to install.
- `k3sinstall.sh` is just a local copy of the k3s install script.  You can get a fresh copy with `curl -sfL -o k3sinstall.sh https://get.k3s.io` .
