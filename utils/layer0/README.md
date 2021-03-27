# Layer0 tools

The reference Layer0 is a u-root initramfs, with the included uinit init and the correct kraken build.

The Layer0 is itself usually layered with at least: base (u-root, kraken etc) + kmod (kernel module bundle) + config (configuration files, including uinit script).

These do *not* need to be pre-combined, just comma separate them on the `initramfs=` on the kernel commandline.

## build-layer-*.sh tools

We provide two tools to build the first two bits (base, kmod) of the layer0 bundle:

### build-layer0-base.sh

This builds the base initramfs, including: `kraken-layercake`, `imageapi-server`, `uinit`, `modscan`, `entropy`, and `rbd`.  Additional go commands can be added by adding them to the commandline.  

There are a number of options to `build-layer0-base.sh`:
```bash
$ sh build-layer0-base.sh -h
Usage: build-layer0-base.sh [-kh] [-o <out_file>] [-b <base_dir>] [ -t <tmp_dir> ] <arch> [<additional_go_cmd> ...]
  <arch> should be the GOARCH we want to build (e.g. arm64, amd64...)
  <out_file> is the file the image should be written to.  (default: layer0-00-base.<date>.<arch>.cpio.xz)
  <base_dir> is an optional base directory containing file/directory structure (default: none)
             that should be added to the image
  <tmp_dir> is a temporary directory to use.  This can be used to resume a previous build
            IMPORTANT: tmp_dir cannot sit inside of a moduled go directory!
  <additional_go_cmd> is a go cmd path spec that should be built into the busybox
  [-k] keep temporary directory (do not delete)
  [-h] display this usage information and exit
```

### build-layer0-kmod.sh

This is a helper script to construct kernel module (`kmod`) bundles.  These are intended to be layered on top of `base` bundles.  This script will take a list of modules to include from a file or commandline.  It will resolve all module dependencies and included all requested modules with dependencies.

Alternatively, with `-a`, it will build a complete bundle of all modules available for that kernel version.

There are a number of options to `build-layer0-kmod.sh`:
```bash
$ sh build-layer0-kmod.sh -h
Usage: build-layer0-kmod.sh [-kha] [-o <out_file>] [-c <chroot_dir>] [-t <tmp_dir>] [-f <mod_file>] <kernel_version> [<mod> ...]
  <out_file> file the image should be written to. (default: layer0-10-kmod.<kernel_version>.cpio.xz)
  <chroot_dir> chroot to look for kernel modules in (currently not implemented)
  <tmp_dir> is a temporary directory to use.  This can be used to resume a previous build
  <mod_file> a file to read a list of modules from.  Can contain blank lines and comments beginning with #.
  <kernel_version> the kernel version string to build the kmod bundle for.  For current kernel, use 5.10.22-200.fc33.x86_64.
  <mod> ... modules to be added to the kmod bundle (can be combined with <mod_file>)
  [-k] keep termporary directory (do not delete)
  [-a] install all available modules (ignores <mod_file> and <mod>)
  [-h] display this usage information and exit
```

### build-layer0-config.sh

This is a helper script to create a config overlay bundle.  This script is much simpler than the other build scripts.  It takes a directory of files (config files, typically, but really anything), and builds a comppressed cpio from them.  `build-layer0-config.sh` can also take a list of directories and layer them on top of each other before building the compressed cpio.

The options for `build-layer0-kmod.sh` are:
```bash
$ bash build-layer0-config.sh -h
Usage: build-layer0-config.sh [-kh] [-o <out_file>] [-t <tmp_dir>] <dir> [<dir> ...][
   <out_file> file the image shoudl be written to. (default: layer0-20-config.xz)
   <tmp_dir> is a temporary directory to use.
   <dir> directory containing the config files to overlay. Any additonal directories will be overlayed in order.
  [-k] keep termporary directory (do not delete)
  [-h] display this usage information and exit
```

## Instructions for building a Layer0

In general, you need three steps:
1) run `build-layer0-base.sh`
2) run `build-layer0-kmod.sh`
3) Create a config set directory:
   1) make a directory
   2) put files you want to overaly in that directory, including:
      1) `uinit.script` (mandatory)
      2) `authorized_keys` (a very good idea)
      3) any other config files you want your minOS to have (`/etc/hosts`, `/etc/passwd`, `/etc/group` are good ideas, for one)
   3) create a bundle by running `build-layer0-config.sh` on the config set directory.
4) Finally, make sure you specify these in `initramfs=<base>,<kmod>,<conf>` on the kernel commandline (`pxelinux.cfg/default.tpl`, probably)

***IMPORTANT***: Without a `uinit.script` your Layer0 won't do anything.  Look at the examples or the project [uinit](https://github.com/kraken-hpc/uinit) for details.