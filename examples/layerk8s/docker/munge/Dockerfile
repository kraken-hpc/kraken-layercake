### 
# This was stolen from github.com/cluening/vagrant-k3s-hpccluster
##
FROM centos:8

RUN dnf -y install munge \
    && dnf clean all

COPY entrypoint.sh /

ENTRYPOINT ["/entrypoint.sh"]
