#!/bin/bash

cp -av rancher/ /etc
INSTALL_K3S_SKIP_START=true $HOME/scripts/k3sinstall.sh

echo 'K3S should be good to go... now `systemctl start k3s` to start'
