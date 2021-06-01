#!/bin/bash

# some useful aliases for layerk8s

alias krakenctl="podman run --rm -it --name krakenctl --net=host krakenctl"
alias rbd="kubectl -n rook-ceph exec -it deploy/rook-ceph-tools -- rbd"
alias ceph="kubectl -n rook-ceph exec -it deploy/rook-ceph-tools -- ceph"
alias pm="kubectl exec -it \$(kubectl get pods -lapp=powerman -o json | jq -r .items[].metadata.name) -c powerman -- pm"
