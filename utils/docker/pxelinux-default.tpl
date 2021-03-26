DEFAULT menu.c32
PROMPT 0
TIMEOUT 50
MENU TITLE Main Menu

LABEL node
    MENU LABEL Boot x86_64 Compute Node (diskless)
    KERNEL vmlinuz
    APPEND console=tty1 root=/dev/ram0 initrd=layer0-base.xz,layer0-kmod.xz,layer0-config.xz kraken.iface={{.Iface}} kraken.ip={{.IP}} kraken.net={{.CIDR}} kraken.id={{.ID}} kraken.parent={{.ParentIP}} kraken.name={{.Nodename}} kraken.loglevel=7
