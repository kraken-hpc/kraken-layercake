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
        echo "Usage: $0 [-kh] [-o <out_file>] [-b <base_dir>] [ -t <tmp_dir> ] <arch> [<additional_go_cmd> ...]"
        echo "  <arch> should be the GOARCH we want to build (e.g. arm64, amd64...)"
        echo "  <out_file> is the file the image should be written to.  (default: layer0-00-base.<date>.<arch>.cpio.xz)"
        echo "  <base_dir> is an optional base directory containing file/directory structure (default: none)"
        echo "             that should be added to the image"
        echo "  <tmp_dir> is a temporary directory to use.  This can be used to resume a previous build"
        echo "            IMPORTANT: tmp_dir cannot sit inside of a moduled go directory!"
        echo "  <additional_go_cmd> is a go cmd path spec that should be built into the busybox"
        echo "  [-k] keep temporary directory (do not delete)"
        echo "  [-h] display this usage information and exit"
}

# Exit with a failure message
fatal() {
    echo "$1" >&2
    exit 1
}

if ! opts=$(getopt o:b:t:kh "$@"); then
    usage
    exit
fi

DELETE_TMPDIR=1
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
        -k) echo "Will not delete temporary directory at the end"
            DELETE_TMPDIR=0
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
EXTRA_COMMANDS+=( github.com/kraken-hpc/kraken-layercake/cmd/kraken-layercake )
EXTRA_COMMANDS+=( github.com/kraken-hpc/uinit/cmds/uinit )
EXTRA_COMMANDS+=( github.com/kraken-hpc/imageapi/cmd/imageapi-server )
EXTRA_COMMANDS+=( github.com/jlowellwofford/entropy/cmd/entropy )
EXTRA_COMMANDS+=( github.com/bensallen/modscan/cmd/modscan )
EXTRA_COMMANDS+=( github.com/bensallen/rbd/cmd/rbd )

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

# fixup mod deps
for c in "${EXTRA_COMMANDS[@]}"; do
    (
        cd "$GOPATH/src/$c" || fatal "couldn't cd to $GOPATH/src/$c"
        if [ -d "vendor" ]; then
            echo "Removing vendor folder $PWD/vendor"
            rm -rf "$PWD/vendor"
        fi
        for m in "${EXTRA_MODS[@]}"; do 
            go mod edit -replace="$m=$GOPATH/src/$m"
        done
    )
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
printf "Command list: %s" "${BB_COMMANDS[@]}"
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

echo "Creating base cpio..."
(
    cd "$TMPDIR"/base || exit 1
    find . | cpio -oc > "$TMPDIR"/base.cpio
) || fatal "Creating base cpio failed"

echo "Creating image..."
# shellcheck disable=SC2068
GOARCH="$ARCH" "$GOPATH"/bin/u-root -nocmd -initcmd=/bbin/init -uinitcmd=/bbin/uinit -defaultsh=/bbin/elvish -base "$TMPDIR"/base.cpio -o "$TMPDIR"/initramfs.cpio 2>&1

echo "CONTENTS:"
cpio -itv < "$TMPDIR"/initramfs.cpio

echo "Compressing..."
xz "$TMPDIR"/initramfs.cpio

if [ -z "${OUTFILE+x}" ]; then
    D=$(date +%Y%m%d.%H%M)
    OUTFILE="layer0-00-base.${D}.${ARCH}.cpio.xz"
fi
mv -v "$TMPDIR"/initramfs.cpio.xz "$ORIG_PWD"/"$OUTFILE"

if [ $DELETE_TMPDIR -eq 1 ]; then
    echo "Removing temporary directory"
    rm -rf "$TMPDIR"
fi

echo "Image built as $OUTFILE"
