FROM centos:8

ARG KMOD_VER="4.18.0-240.22.1.el8_3.x86_64"

# Pre-build copy-in
COPY $KMOD_VER /lib/modules/$KMOD_VER
COPY passwd /etc/passwd
COPY group /etc/group
# Install base packages
RUN dnf -y install \
	systemd \
	chrony \
	sssd-common \
	openssh openssh-clients openssh-server \
	bash \
    && dnf clean all

# Post-install config
COPY hosts /etc/hosts
COPY id_rsa.pub /root/.ssh/authorized_keys
COPY chrony.conf /etc/chrony.conf
COPY resolv.conf /etc/resolv.conf
RUN systemctl enable sshd chronyd \
    && systemctl disable kdump \
    && chmod 700 /root/.ssh \
    && chmod 600 /root/.ssh/authorized_keys \
    && rm -f /etc/hostname 

ENTRYPOINT ["/bin/bash"]
