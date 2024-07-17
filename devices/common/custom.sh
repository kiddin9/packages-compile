#!/bin/bash

shopt -s extglob
rm -rf feeds/kiddin9/{diy,mt-drivers,shortcut-fe,luci-app-mtwifi,base-files}

curl -sfL https://raw.githubusercontent.com/openwrt/packages/master/lang/golang/golang/Makefile -o feeds/packages/lang/golang/golang/Makefile

for ipk in $(find feeds/kiddin9/* -maxdepth 0 -type d);
do
	[[ "$(grep "KernelPackage" "$ipk/Makefile")" && ! "$(grep "BuildPackage" "$ipk/Makefile")" ]] && rm -rf $ipk || true
done

#<<'COMMENT'
rm -Rf feeds/luci/{applications,collections,protocols,themes,libs,docs,contrib}
rm -Rf feeds/luci/modules/!(luci-base)
rm -Rf feeds/packages/!(lang|libs|devel|utils|net|multimedia)
rm -Rf feeds/packages/multimedia/!(gstreamer1|ffmpeg)
rm -Rf feeds/packages/net/!(mosquitto|curl)
rm -Rf feeds/base/package/firmware
rm -Rf feeds/base/package/network/!(services|utils)
rm -Rf feeds/base/package/network/services/!(ppp)
rm -Rf feeds/base/package/system/!(opkg|ubus|uci|ca-certificates)
rm -Rf feeds/base/package/kernel/!(cryptodev-linux)
#COMMENT

status=$(curl -H "Authorization: token $REPO_TOKEN" -s "https://api.github.com/repos/kiddin9/openwrt-packages/actions/runs" | jq -r '.workflow_runs[0].status')
while [[ "$status" == "in_progress" || "$status" == "queued" ]];do
echo "wait 5s"
sleep 5
status=$(curl -H "Authorization: token $REPO_TOKEN" -s "https://api.github.com/repos/kiddin9/openwrt-packages/actions/runs" | jq -r '.workflow_runs[0].status')
done

./scripts/feeds update -a
./scripts/feeds install -a -p kiddin9 -f
./scripts/feeds install -a

sed -i 's/\(page\|e\)\?.acl_depends.*\?}//' `find package/feeds/kiddin9/luci-*/luasrc/controller/* -name "*.lua"`
# sed -i 's/\/cgi-bin\/\(luci\|cgi-\)/\/\1/g' `find package/feeds/kiddin9/luci-*/ -name "*.lua" -or -name "*.htm*" -or -name "*.js"` &
sed -i 's/Os/O2/g' include/target.mk

sed -i \
	-e "s/+\(luci\|luci-ssl\|uhttpd\)\( \|$\)/\2/" \
	-e "s/+nginx\( \|$\)/+nginx-ssl\1/" \
	-e 's/+python\( \|$\)/+python3/' \
	-e 's?../../lang?$(TOPDIR)/feeds/packages/lang?' \
	-e 's,$(STAGING_DIR_HOST)/bin/upx,upx,' \
	package/feeds/kiddin9/*/Makefile

cp -f devices/common/.config .config
mv -f feeds/base feeds/base.bak
mv -f feeds/packages feeds/packages.bak
make defconfig
rm -Rf feeds/base
mv -f feeds/base.bak feeds/base
mv -f feeds/packages.bak feeds/packages
sed -i 's/CONFIG_ALL=y/CONFIG_ALL=n/' .config
sed -i '/PACKAGE_kmod-/d' .config

sed -i "/mediaurlbase/d" package/feeds/*/luci-theme*/root/etc/uci-defaults/*

sed -i '/WARNING: Makefile/d' scripts/package-metadata.pl


cp -f devices/common/po2lmo staging_dir/host/bin/po2lmo
chmod +x staging_dir/host/bin/po2lmo
