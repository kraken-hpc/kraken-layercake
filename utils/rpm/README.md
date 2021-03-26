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
- *initramfs* - This will build a base initramfs.
- *vbox* - This builds a version of layercake that has the vbox extension/module.  This is mostly used for experimentation/testing/examples.
  This will also build the `vboxapi` package and, if `initramfs` is also specified, the `initramfs-vbox` pacakge.

To build all available packages, e.g.:

```bash
$ rpmbuild --with vbox --with initramfs -ta ../kraken-layercake-0.1.0.tar.gz
```

This would would create the following RPMS:

```bash
./x86_64/kraken-layercake-0.1.0-rc1.fc33.x86_64.rpm
./x86_64/kraken-layercake-vbox-0.1.0-rc1.fc33.x86_64.rpm
./x86_64/kraken-layercake-vboxapi-0.1.0-rc1.fc33.x86_64.rpm
./noarch/kraken-layercake-initramfs-vbox-amd64-0.1.0-rc1.fc33.noarch.rpm
./noarch/kraken-layercake-initramfs-amd64-0.1.0-rc1.fc33.noarch.rpm
```