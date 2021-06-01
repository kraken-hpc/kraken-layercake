###
# This was stolen from github.com/cluening/vagrant-k3s-hpccluster
###
FROM centos:8

RUN dnf -y install http://repos.openhpc.community/OpenHPC/2/CentOS_8/x86_64/ohpc-release-2-1.el8.x86_64.rpm \
    && dnf -y install slurm-slurmctld-ohpc sssd-common \
    && dnf clean all

COPY entrypoint.sh /

ENTRYPOINT ["/entrypoint.sh"]
