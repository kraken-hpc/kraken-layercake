#!/bin/bash

###
# This will build a layer0 kmod bundle that can be layered on the base bundle
###

usage() {
   echo "Usage: $0 [-kha] [-o <out_file>] [-c <chroot_dir>] [-t <tmp_dir>] [-f <mod_file>] <kernel_version> [<mod> ...]"
   echo "  <out_file> file the image should be written to. (default: layer0-10-kmod.<kernel_version>.cpio.xz)"
   echo "  <chroot_dir> chroot to look for kernel modules in (currently not implemented)"
   echo "  <tmp_dir> is a temporary directory to use.  This can be used to resume a previous build"
   echo "  <mod_file> a file to read a list of modules from.  Can contain blank lines and comments beginning with #."
   echo "  <kernel_version> the kernel version string to build the kmod bundle for.  For current kernel, use $(uname -r)."
   echo "  <mod> ... modules to be added to the kmod bundle (can be combined with <mod_file>)"
   echo "  [-k] keep termporary directory (do not delete)"
   echo "  [-a] install all available modules (ignores <mod_file> and <mod>)"
   echo "  [-h] display this usage information and exit"
}

fatal() {
   echo "$1" >&2
   exit 1
}

build_modlist_all() {
   echo "Building modlist (all)"
   shopt -s globstar nullglob
   for m in /lib/modules/"$KVER"/**/*.ko*; do
      MODLIST+=( "$m" )
   done
}

build_modlist() {
   echo "Building modlist"
   if [ -n "${MODFILE+x}" ]; then
      if [ ! -f "$MODFILE" ]; then
         fatal "Modfile does not exist $MODFILE"
      fi
      echo "Reading module list from $MODFILE"
      for m in $( grep -vE '^#|^$' "$MODFILE" || fatal "couldn't read $MODFILE" ); do
         NAMES+=( "$m" )
      done 
   fi
   for n in "${NAMES[@]}"; do
      for m in $( modprobe --set-version="$KVER" --show-depends "$n" | awk '$1=="insmod"{print $2}' || fatal 'could not find module by name '"$n" ); do 
         MODLIST+=( "$m" )
      done
   done

   # shellcheck disable=SC2207
   IFS=$'\n' MODLIST=($( sort -u <<<"${MODLIST[*]}")); unset IFS
}

if ! opts=$(getopt c:f:o:t:kah "$@"); then
   usage
   exit
fi

ORIG_PWD=$PWD
DELETE_TMPDIR=1
ALL_MODS=0
ROOT="/"

# shellcheck disable=SC2086
set -- $opts
for i; do
   case "$i"
   in
      -h)
         usage
         exit
         shift; shift;;
      -c)
         fatal "Chroot is not yet implemented."
         if [ ! -d "$2" ]; then
            fatal "Specified chroot does not exist: $2"
         fi
         echo "Using chroot at $2"
         ROOT="$2"
         shift; shift;;
      -o) 
         echo "Output file is $2" 
         OUTFILE="$2" 
         shift; shift;;
      -b) 
         MODFILE="$2"
         shift; shfit;;
      -t)
         TMPDIR=$( readlink -f "$2" || fatal "no such file $2" )
         shift; shift;;
      -k)
         echo "Will not delete temporary directory at the end"
         DELETE_TMPDIR=0
         shift;;
      -f)
         MODFILE="$2"
         shift; shift;;
      -a)
         echo "Building bundle with all kmods (other specifiers will be ignored)"
         ALL_MODS=1
         shift;;
      --)
         shift; break;;
   esac
done

NAMES=()
MODLIST=()

if [ $# -lt 1 ]; then
   usage
   exit 1
fi

KVER="$1"
shift
echo "Using kernel version: $KVER"
MODDIR=$( readlink -f "$ROOT/lib/modules/$KVER" )

if [ ! -d "$MODDIR" ]; then
   fatal "Module directory does not exist: $KVER"
fi

while (( "$#" )); do
   NAMES+=( "$1" )
   shift
done

if [ $ALL_MODS -eq 1 ]; then
   build_modlist_all
else
   build_modlist
fi

printf "Modlist: %s\n" "${MODLIST[@]}"

if [ -z ${TMPDIR+x} ]; then
   TMPDIR=$(mktemp --tmpdir -d layer0-kmod.XXXXXXXXXXXX)
else
   if [ ! -d "$TMPDIR" ]; then
      echo "Creating $TMPDIR"
      mkdir -p "$TMPDIR" || fatal "failed to create $TMPDIR"
   fi
fi

cd "$TMPDIR" || fatal "could not cd to $TMPDIR"
mkdir -p "root/lib/modules/$KVER" || fatal "could not create module directory"

echo "Installing modules"
for m in "${MODLIST[@]}"; do
   b=$( basename "$m" )
   d=$( dirname "$m" )
   ddir="$TMPDIR/root$d"
   mkdir -p "$ddir" || fatal "could not mkdir $ddir"
   /bin/cp -Lv "$m" "$ddir/$b" || fatal "could not copy module $m"
done

echo "Copying module metadata files"
cp -Lv "/lib/modules/$KVER/modules.order" "$TMPDIR/root/lib/modules/$KVER/"
cp -Lv "/lib/modules/$KVER/modules.builtin" "$TMPDIR/root/lib/modules/$KVER/"

echo "Running depmod"
depmod -w --basedir "$TMPDIR/root" --all --verbose "$KVER"

if [ -z ${OUTFILE+x} ]; then
   OUTFILE="layer0-10-kmod.$KVER.cpio.xz"
fi

echo "Creating compressed cpio at $OUTFILE"
cd "$TMPDIR/root" || fatal "could not cd to $TMPDIR/root"
find . | cpio -oc | xz -c > "$ORIG_PWD"/"$OUTFILE" || fatal "failed to compressec cpio bundle"

if [ $DELETE_TMPDIR -eq 1 ]; then
   echo "Cleaning up $TMPDIR"
fi
