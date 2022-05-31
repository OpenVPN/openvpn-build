dnl ============================================================
dnl Downloadables
dnl ============================================================

dnl TAP-Windows binaries
define([PRODUCT_TAP_WIN_URL_x86],      [https://build.openvpn.net/downloads/releases/tap-windows-9.24.6-I601-i386.msm])
define([PRODUCT_TAP_WIN_URL_amd64],    [https://build.openvpn.net/downloads/releases/tap-windows-9.24.6-I601-amd64.msm])
define([PRODUCT_TAP_WIN_URL_arm64],    [https://build.openvpn.net/downloads/releases/tap-windows-9.24.6-I601-arm64.msm])
define([PRODUCT_TAP_WIN_COMPONENT_ID], [tap0901])
define([PRODUCT_TAP_WIN_NAME],         [TAP-Windows])

dnl Wintun binaries
define([PRODUCT_WINTUN_URL_x86],       [https://www.wintun.net/builds/wintun-x86-0.8.1.msm])
define([PRODUCT_WINTUN_URL_amd64],     [https://www.wintun.net/builds/wintun-amd64-0.8.1.msm])
dnl This is only to make build script happy - the file is only downloaded but not used, since there is no arm64 wintun MSM (yet)
define([PRODUCT_WINTUN_URL_arm64],     [https://www.wintun.net/builds/wintun-amd64-0.8.1.msm])

dnl OpenVPNServ2.exe binary
define([OPENVPNSERV2_URL], [http://build.openvpn.net/downloads/releases/openvpnserv2-1.4.0.1.exe])

dnl Easy RSA binaries (URL to .tar.gz file containing "easy-rsa-[EASYRSA_VERSION]" folder with Easy RSA)
define([EASYRSA_VERSION], [3.0.8])
define([EASYRSA_URL],     [https://github.com/OpenVPN/easy-rsa/releases/download/v3.0.8/EasyRSA-3.0.8-win64.zip])


dnl ============================================================
dnl MSI Provisioning
dnl ============================================================

dnl Define the product name and publisher.
define([PRODUCT_NAME],      [OpenVPN])
define([PRODUCT_PUBLISHER], [OpenVPN, Inc.])

dnl The package version as displayed by UI and used in filenames (no spaces, please).
define([PACKAGE_VERSION], [2.5.7-I602])

dnl The MSI product version in the form of n[.n[.n]] (numbers only).
dnl The third field is 100*product release + package version.
dnl The fourth field is ignored by MSI.
define([PRODUCT_VERSION], [2.5.036])

dnl The MSI product code MUST change on each product release.
define([PRODUCT_CODE], [{C57B257B-3D92-4AC0-8FE8-7D6FF81AEF73}])

dnl The MSI upgrade codes MUST persist for all versions of the same product line.
dnl Please use own upgrade codes when deploying a non-official OpenVPN release.
define([UPGRADE_CODE_x86],   [{1195A47B-A37A-4055-9D34-B7A691F7E97B}])
define([UPGRADE_CODE_amd64], [{461BDF86-D389-4471-BF36-99806B64C127}])
define([UPGRADE_CODE_arm64], [{1E8C4DDC-9E93-4AE2-9495-DF86821EAA3A}])

dnl OpenVPN configration file extension (e.g. conf, ovpn...)
define([CONFIG_EXTENSION], [ovpn])
