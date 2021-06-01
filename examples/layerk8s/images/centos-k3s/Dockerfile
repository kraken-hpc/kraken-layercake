FROM localhost/centos-base

ARG TOKEN="YOURTOKENHERE"

COPY k3sinstall.sh /root/k3sinstall.sh
RUN INSTALL_K3S_SKIP_ENABLE=true INSTALL_K3S_SKIP_START=true INSTALL_K3S_SKIP_SELINUX_RPM=true K3S_URL=https://moonlight:6443 K3S_TOKEN=$TOKEN sh /root/k3sinstall.sh
COPY pre-k3s.sh /usr/libexec/pre-k3s.sh
COPY k3s-agent.service /etc/systemd/system/k3s-agent.service
RUN systemctl enable k3s-agent 

ENTRYPOINT ["/bin/bash"]
