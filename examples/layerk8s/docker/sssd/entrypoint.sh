#!/bin/bash

# Set up expected directories
mkdir -p /var/lib/sss
mkdir -p /var/lib/sss/db
mkdir -p /var/lib/sss/deskprofile
mkdir -p /var/lib/sss/gpo_cache
mkdir -p /var/lib/sss/mc
mkdir -p /var/lib/sss/pipes
mkdir -p /var/lib/sss/pipes/private
mkdir -p /var/lib/sss/pubconf
mkdir -p /var/lib/sss/secrets

exec /sbin/sssd -i --logger=stderr $@
