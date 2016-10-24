#!/bin/sh

OPENVPN=/etc/init.d/openvpn

if [ ! -x $OPENVPN ]; then
  exit 0
fi

if [ -n "$IF_OPENVPN" ]; then
  for vpn in $IF_OPENVPN; do
    $OPENVPN stop $vpn
  done
fi
