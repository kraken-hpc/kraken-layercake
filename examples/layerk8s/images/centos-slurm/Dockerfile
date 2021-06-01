FROM localhost/centos-base

# Install repos/extra packages
RUN dnf -y install http://repos.openhpc.community/OpenHPC/2/CentOS_8/x86_64/ohpc-release-2-1.el8.x86_64.rpm \
    && dnf -y install \
	slurm-slurmd-ohpc \
    && dnf clean all

# config munge/slurm
COPY munge.key /etc/munge/munge.key
COPY slurm.conf /etc/slurm/slurm.conf
RUN chown munge:munge /etc/munge/munge.key \ 
    && chmod 400 /etc/munge/munge.key \
    && systemctl enable munge slurmd 

ENTRYPOINT ["/bin/bash"]
