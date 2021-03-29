#!/bin/bash

###
# This script will build a config set overlay for the layre0 (minOS) stage.
###

usage() {
   echo "Usage: $0 [-kh] [-o <out_file>] [-t <tmp_dir>] <dir> [<dir> ...]["
   echo "   <out_file> file the image shoudl be written to. (default: layer0-20-config.xz)"
   echo "   <tmp_dir> is a temporary directory to use."
   echo "   <dir> directory containing the config files to overlay. Any additonal directories will be overlayed in order."
   echo "  [-k] keep termporary directory (do not delete)"
   echo "  [-h] display this usage information and exit"
}

fatal() {
   echo "$1" >&2
   exit 1
}

if ! opts=$(getopt o:t:hk "$@"); then
   usage
   exit
fi

ORIG_PWD=$PWD
OUTFILE="layer0-20-config.xz"
DELETE_TMPDIR=1
# shellcheck disable=SC2086
set -- $opts
for i; do
   case "$i"
   in
      -h)
         usage
         exit
         shift;;
      -o)
         OUTFILE="$2"
         shift; shift;;
      -t)
         TMPDIR="$2"
         shift; shift;;
      -k)
         echo "Will not delete temporary directory at the end"
         DELETE_TMPDIR=0
         shift;;
      --)
         shift; break;;
   esac
done

echo "Output file is $OUTFILE"

if [ $# -lt 1 ]; then
   usage
   exit 1
fi

DIRS=()

while (( "$#" )); do
   # shellcheck disable=SC2207
   DIRS+=( $(readlink -f "$1") )
   shift
done

printf "Using directory: %s\n" "${DIRS[@]}"

if [ -z ${TMPDIR+x} ]; then
   TMPDIR=$(mktemp --tmpdir -d layer0-config.XXXXXXXXXXXX)
else
   if [ ! -d "$TMPDIR" ]; then
      echo "Creating $TMPDIR"
      mkdir -p "$TMPDIR" || fatal "failed to create $TMPDIR"
   fi
fi

mkdir -p "$TMPDIR/root"

for d in "${DIRS[@]}"; do
   echo "Syncing $d"
   rsync -av "$d/" "$TMPDIR/root/" || fatal "Failed to synchronize $d"
done

echo "Making compressed cpio"
cd "$TMPDIR/root" || fatal "could not cd to $TMPDIR/root"
find . | cpio -oc | xz -c > ../conf.cpio.xz || fatal "failed to create compressed cpio"

cd "$ORIG_PWD" || fatal "failed to cd to $ORIG_PWD"
cp -v "$TMPDIR/conf.cpio.xz" "$OUTFILE" || fatal "failed to copy archive to $OUTFILE"

if [ $DELETE_TMPDIR -eq 1 ]; then
   echo "Cleaning up $TMPDIR"
   rm -rf "$TMPDIR" || fatal "failed to remove $TMPDIR"
fi

echo "Image built as $OUTFILE"

echo "Done."