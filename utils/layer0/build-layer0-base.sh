#!/bin/bash

###
# This will build a layer0 image.
#
# Notes:
# - We build in a dedicated "tmp_dir", including a separate GOPATH.  This helps ensure consistent builds.
# - You can keep (-k) and reuse a tmp_dir (-t <tmp_dir>), which can speed up builds significantly when frequently rebuilding/testing.
# - You can overlay a base directory by providing a second argument.  However, we recommend concatinated CPIOs instead.
#
###

usage() {
        echo "Usage: $0 [-gkxh] [-o <out_file>] [-b <base_dir>] [ -t <tmp_dir> ] <arch> [<additional_go_cmd> ...]"
        echo "  <arch> should be the GOARCH we want to build (e.g. arm64, amd64...)"
        echo "  <out_file> is the file the image should be written to.  (default: layer0-00-base.<date>.<arch>.cpio.<xz|gz>)"
        echo "  <base_dir> is an optional base directory containing file/directory structure (default: none)"
        echo "             that should be added to the image"
        echo "  <tmp_dir> is a temporary directory to use.  This can be used to resume a previous build"
        echo "            IMPORTANT: tmp_dir cannot sit inside of a moduled go directory!"
        echo "  <additional_go_cmd> is a go cmd path spec that should be built into the busybox"
        echo "  [-g] use gzip instead of xz (needed for kernels with no xz support)"
        echo "  [-k] keep temporary directory (do not delete)"
        echo "  [-x] don't include the default list of extra commands (u-root commands only)"
        echo "  [-h] display this usage information and exit"
}

# Exit with a failure message
fatal() {
    echo "$1" >&2
    exit 1
}

if ! opts=$(getopt o:b:t:s:khg "$@"); then
    usage
    exit
fi

DELETE_TMPDIR=1
NO_EXTRAS=0
COMPRESS=xz
# shellcheck disable=SC2086
set -- $opts
for i; do
    case "$i"
    in
        -h)
            usage
            exit
            shift; shift;;
        -o)
            echo "Output file is $2"
            OUTFILE="$2"
            shift; shift;;
        -b)
            echo "Using base dir $2"
            BASEDIR="$2"
            shift; shift;;
        -t) echo "Using tmp dir $2"
            TMPDIR=$(readlink -f "$2")
            shift; shift;;
        -s)
            echo "Copying local src $2"
            LOCALSRC="$2"
            shift; shift;;
        -k) echo "Will not delete temporary directory at the end"
            DELETE_TMPDIR=0
            shift;;
        -x) echo "Will not include default extra commands"
            NO_EXTRAS=1
            shift;;
        -g) echo "Will use gzip instead of xz"
            COMPRESS=gzip
            shift;;
        --)
            shift; break;;
    esac
done

if [ $# -lt 1 ]; then
    usage
    exit 1
fi

ARCH=$1
shift

# Commands to build into u-root busybox
EXTRA_COMMANDS=()
if [ $NO_EXTRAS -eq 0 ]; then
    EXTRA_COMMANDS+=( github.com/kraken-hpc/kraken-layercake/cmd/kraken-layercake )
    EXTRA_COMMANDS+=( github.com/kraken-hpc/uinit/cmds/uinit )
    EXTRA_COMMANDS+=( github.com/kraken-hpc/imageapi/cmd/imageapi-server )
    EXTRA_COMMANDS+=( github.com/jlowellwofford/entropy/cmd/entropy )
    EXTRA_COMMANDS+=( github.com/bensallen/modscan/cmd/modscan )
    EXTRA_COMMANDS+=( github.com/bensallen/rbd/cmd/rbd )
fi

while (( "$#" )); do 
    echo "Adding command $1"
    EXTRA_COMMANDS+=( "$1" )
    shift
done

UROOT="github.com/u-root/u-root"

# make a temporary directory for our base
if [ -z ${TMPDIR+x} ]; then
    TMPDIR="$(mktemp --tmpdir -d layer0-base.XXXXXXXXXXXX)"
else 
    if [ ! -d "$TMPDIR" ]; then
        echo "Creating $TMPDIR"
        mkdir -p "$TMPDIR" || fatal "failed to create $TMPDIR"
    fi
fi
echo "Using tmpdir: $TMPDIR"
ORIG_PWD="$PWD"
cd "$TMPDIR" || fatal "couldn't cd to $TMPDIR"
GOPATH="$TMPDIR/gopath"

if [ -d "${LOCALSRC}" ]; then
    mkdir -p "${GOPATH}"/src
    cp -a "${LOCALSRC}/." "${GOPATH}"/src/
fi

EXTRA_MODS=()
# Make sure commands are available
for c in "${EXTRA_COMMANDS[@]}"; do
   if [ ! -d "$GOPATH/src/$c" ]; then
    echo "installing $c"
    GOPATH=$GOPATH GO111MODULE=off go get "$c" || fatal "failed to install $c"
   fi
    cd "$GOPATH/src/$c" || fatal "couldn't cd to $GOPATH/src/$c"
    go mod edit -replace=github.com/u-root/u-root="$GOPATH/src/$UROOT"
    MOD=$(go mod edit -print | awk '$1=="module"{print $2}')
    echo "mod: $MOD"
    EXTRA_MODS+=( "$MOD" )
done

# make our extra mods list unique
# shellcheck disable=SC2207
IFS=$'\n' EXTRA_MODS=($( sort -u <<<"${EXTRA_MODS[*]}")); unset IF

# fixup mod deps
for m in "${EXTRA_MODS[@]}"; do
    echo "Processing module $m"
    cd "$GOPATH/src/$m" || fatal "couldn't cd to $GOPATH/src/$m"
    if [ -d "vendor" ]; then
        echo "Removing vendor folder $PWD/vendor"
        rm -rf "$PWD/vendor"
    fi
    for mm in "${EXTRA_MODS[@]}"; do 
        go mod edit -replace="$mm=$GOPATH/src/$mm"
    done
done

# Check that gobusybox is installed, clone it if not
if [ ! -x "$GOPATH"/bin/makebb ]; then
    echo "installing gobusybox"
    GOPATH="$GOPATH" GO111MODULE=off go get github.com/u-root/gobusybox/src/cmd/makebb || fatal "failed to install gobusybox"
fi

# Check that u-root is installed, clone it if not
if [ ! -x "$GOPATH"/bin/u-root ]; then
    echo "installing u-root"
    GOPATH="$GOPATH" GO111MODULE=off go get "$UROOT" || fatal "failed to install u-root"
fi

# Generate the array of commands to add to BusyBox binary
BB_COMMANDS=( "$GOPATH/src/$UROOT"/cmds/{core,boot,exp}/* )
# shellcheck disable=SC2068
for cmd in ${EXTRA_COMMANDS[@]}; do
    BB_COMMANDS+=( "$GOPATH"/src/"$cmd" )
done

# Create BusyBox binary (outside of u-root)
echo "Creating BusyBox binary..."
mkdir -p "$TMPDIR"/base/bbin
printf "Command list: %s\n" "${BB_COMMANDS[@]}"
# shellcheck disable=SC2068
"$GOPATH"/bin/makebb -o "$TMPDIR"/base/bbin/bb ${BB_COMMANDS[@]} || fatal "makebb: failed to create BusyBox binary"

# Create symlinks of included programs to BusyBox binary
echo "Creating links to BusyBox binary..."
# shellcheck disable=SC2068
for cmd in ${BB_COMMANDS[@]}; do
    ln -s bb "$TMPDIR"/base/bbin/"$(basename "$TMPDIR"/base/bbin/"$cmd")"
done

# copy base_dir over tmpdir if it's set
if [ -n "${BASEDIR+x}" ]; then
        echo "Overlaying ${BASEDIR}..."
        rsync -av "$BASEDIR"/ "$TMPDIR"/base
fi

# This is a base64 encoded, xz compressed, cpio archive containing a base layout, including some needed /dev files. 
# We do things this way becaus mknod would require root...
BASE_CPIO="
/Td6WFoAAATm1rRGAgAhARYAAAB0L+Wj4An/AchdABgN3weEa2dQnNrpI3XOhOilM2KI2YlAURV6
k+7+u2dCSHfVCr8VtGoq3dyYtyLgQUmqh88Y0UyDRotUtMlBlIo9t+EJCkDbLTIKaBBxCY0C9yYB
DUnoUsGjK8eL/w7YTqAUE0kXI+ZiUcPlY3RczW1hG56tLOQEFLEMGXulDQrXB0BxRuD1MBCfJEB3
RnHKJkq3DMQGtmWWEM25zud5zlTCrFVsXteIO/lxgDgUJpaUAEKMTB3NoP6ViJFmlrv+wvGOD5vT
2Za1CXjhcRSSUr0p5or3A4B8ATM8Llutsvt6VdL1ivRWn9echbRW5F/y1l1nrMj585ZEKWPCkhnh
ADEcrXFPRFZjzmpC5IzxcNKc0XCyVD4OPLymmcs9thmmB4Yy80cyPuu4I8y3DqcpwPu6DzK2o3Sq
8t96OHvMOoEqLJoaz4QybaesQdFYR0bFg0+tKFGfFmcHjFRXDSbiVMGIoCDscKRtfj48zf74dCdO
qa4MDOZ8FPswipHRw+0++wM7st45QFpGTZK0e5QjrhEwY4Gxbopp/R9WxkvKlWnBIsQj1QGzsjxP
LSDw7WN63is9CNJ4Sisn/Ps6gVy9kRHr20shA3BXAABUfVGEm0ZtDwAB5AOAFAAADkpW/7HEZ/sC
AAAAAARZWg==
"

echo "Extracting cpio base..."
echo "$BASE_CPIO" | base64 -di - | xz -dc > "$TMPDIR/initramfs.cpio" || fatal "failed to extract base cpio"

echo "Creating compressed cpio..."
(
    cd "$TMPDIR/base"
    find . | cpio -ocA -R root:root -O "$TMPDIR/initramfs.cpio"
) || fatal "Creating base cpio failed"

echo "Compressing..."
cd "$TMPDIR" || fatal "could not cd to $TMPDIR"
EXTENSION=$([[ $COMPRESS == "xz" ]] && echo "xz" || echo "gz" )
$COMPRESS initramfs.cpio

if [ -z "${OUTFILE+x}" ]; then
    D=$(date +%Y%m%d.%H%M)
    OUTFILE="layer0-00-base.${D}.${ARCH}.cpio.$EXTENSION"
fi
cd "$ORIG_PWD" || fatal "could not cd to $ORIG_PWD"
cp -v "$TMPDIR/initramfs.cpio.$EXTENSION" "$OUTFILE" || fatal "failed to copy archive to $ORIG_PWD"

if [ $DELETE_TMPDIR -eq 1 ]; then
    echo "Removing temporary directory"
    rm -rf "$TMPDIR" || falal "failed to remove $TMPDIR"
fi

echo "Image built as $OUTFILE"

echo "Done."