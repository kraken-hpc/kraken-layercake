#!/bin/bash

echo "Add /dev/kmsg"
mknod /dev/kmsg c 1 11

echo "Mounting /sys rw"
mount -o rw,remount /sys

echo  "Setting up /var/lib/rancher tmpfs mount"
if [ ! -d /var/lib/rancher ]; then
	mkdir -p /var/lib/rancher
fi
if ! mountpoint /var/lib/rancher; then
	mount -t tmpfs tmpfs /var/lib/rancher
fi

echo "Loading a bunch of modules"
while read -r mod; do
	modprobe $mod
done << EOF
dm_mod
dm_log
dm_region_hash
dm_mirror
failover
serio_raw
net_failover
virtio_blk
virtio_net
libata
ata_piix
ata_generic
sg
sd_mod
cdrom
sr_mod
libcrc32c
xfs
ip_tables
sunrpc
fuse
binfmt_misc
grace
lockd
nfs_acl
auth_rpcgss
nfsd
pcspkr
joydev
i2c_piix4
llc
stp
bridge
br_netfilter
overlay
nf_defrag_ipv4
nf_defrag_ipv6
nf_conntrack
nf_nat
iptable_nat
nfnetlink
ip_set
ip_vs
ip_vs_rr
ip_vs_wrr
ip_vs_sh
nf_tables
nft_compat
xt_comment
nft_counter
xt_addrtype
nft_chain_nat
xt_multiport
xt_conntrack
xt_mark
ipt_MASQUERADE
xt_nat
xt_statistic
nf_conntrack_netlink
udp_tunnel
ip6_udp_tunnel
vxlan
veth
nbd
nf_reject_ipv4
ipt_REJECT
dns_resolver
libceph
rbd
inet_diag
tcp_diag
nf_tables_set
nft_ct
nft_reject
nf_reject_ipv6
nft_reject_inet
nft_masq
EOF

