# Kraken/Layercake RPM building

This directory contains the necessary files to build RPMs.

The spec file, `kraken-layercake.spec`, allows for building cross-architecture RPMs.

Here's an example.  Suppose you have the layercake source in `$HOME/kraken-kraken` and you want to build an `arm64` binary.

```bash
$ cd $HOME/kraken-layercake
$ git archive -o ../kraken-layercake-0.1.0.tar.gz --prefix=kraken-layercake-0.1.0/ HEAD
$ rpmbuild --target aarch64-generic-linux -ta ../kraken-layercake-0.1.0.tar.gz
```

This will build an aarch64 RPM that can be found under `$HOME/rpmbuild/RPMS/aarch64` named `kraken-layercake-0.1.0-0.aarch64.rpm`.

If `--target` is not specified `rpmbuild` will build a native architecture build.

There are three optional packages that can be built with the `--with` option:
- *vbox* - This builds a version of layercake that has the vbox extension/module.  This is mostly used for experimentation/testing/examples.
- *vboxapi* - This will build the vboxapi service which provides a restful wrapper around vboxmanage.  This is used by the vbox build.
- *initramfs* - This will build a base initramfs.

To build all available packages, e.g.:

```bash
$ rpmbuild --with vbox --with vboxapi --with initramfs -ta ../kraken-layercake-0.1.0.tar.gz
```
