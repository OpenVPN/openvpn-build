#!/usr/bin/python
#
# freight-add-all.py
#
# A small Python script for importing Debian packages from localtempdir 
# (default: /tmp/output) into a freight-managed apt repository.
#
# NOTE: this script should be run locally on the node hosting the freight apt 
# repository. It is stored here primarily for versioning purposes.
#
# This script expects to find a directory structure like this on the apt 
# repository host:
#
#.
#├── debian
#│   ├── squeeze
#│   │   ├── openvpn_2.3.2-debian0_amd64.deb
#│   │   └── openvpn_2.3.2-debian0_i386.deb
#│   └── wheezy
#│       ├── openvpn_2.3.2-debian0_amd64.deb
#│       └── openvpn_2.3.2-debian0_i386.deb
#└── ubuntu
#    ├── lucid
#    │   ├── openvpn_2.3.2-debian0_amd64.deb
#    │   └── openvpn_2.3.2-debian0_i386.deb
#    ├── precise
#    │   ├── openvpn_2.3.2-debian0_amd64.deb
#    │   └── openvpn_2.3.2-debian0_i386.deb
#    ├── raring
#    │   ├── openvpn_2.3.2-debian0_amd64.deb
#    │   └── openvpn_2.3.2-debian0_i386.deb
#    └── saucy
#        ├── openvpn_2.3.2-debian0_amd64.deb
#        └── openvpn_2.3.2-debian0_i386.deb
#
# The script will walk through the directory structure and call freight-add with 
# appropriate parameters.

import os
from subprocess import call

if __name__ == '__main__':

    localtempdir="/tmp/output"

    for root, dirs, files in os.walk(localtempdir):
        if files:
            # This will return i386, amd64, noarch or similar
            oscodename = os.path.split(root)[1]
            # This will retrun lucid, squeeze or similar
            osarchitecture = os.path.split(os.path.split(root)[0])[1]

            # Add all files found to the apt repository
            for file in files:
                filepath = root+"/"+file
                call(['freight-add', filepath, 'apt/'+oscodename])

    # Update freight cache
    call(['freight-cache'])
