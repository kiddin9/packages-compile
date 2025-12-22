#!/bin/bash

shopt -s extglob

sed -i "/telephony/d" feeds.conf.default

sed -i -E "s#git\.openwrt\.org/(openwrt|feed|project)#github.com/openwrt#" feeds.conf.default

./scripts/feeds update -a
./scripts/feeds install -a

rm -rf package/feeds/packages/{netdata,cloudreve,smartdns,vsftpd,p910nd,aria2,ariang,coremark,watchcat,dockerd,frp}

rm -Rf feeds/base_root/package/kernel/!(cryptodev-linux|bpf-headers)

cp -f devices/common/.config .config

sed -i '/WARNING: Makefile/d' scripts/package-metadata.pl

sed -i "s#false; \\\#true; \\\#" include/download.mk

sed -i "s/+\# \$(foreach/+\$(foreach/" devices/common/patches/luci_mk.patch
sed -i "s/((\$\$1 + 365\*24\*60\*60))/1/" devices/common/patches/luci_mk.patch

cp -f devices/common/po2lmo staging_dir/host/bin/po2lmo
chmod +x staging_dir/host/bin/po2lmo
