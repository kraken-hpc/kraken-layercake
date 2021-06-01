#!/bin/bash

# The munge key needs to be a real file that's owned by the munge user,
# but kubernetes secrets are mounted as links and owned by root.  This copy
# command gets around that.
cp /data/munge/munge.key /etc/munge/
chown munge:munge /etc/munge/munge.key
chmod 0400 /etc/munge/munge.key

chown munge:munge /run/munge
chmod 0755 /run/munge

exec su munge -s /bin/bash -c "/usr/sbin/munged -F $@"
