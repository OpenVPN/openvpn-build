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
define([PRODUCT_WINTUN_URL_x86],       [https://build.openvpn.net/downloads/releases/wintun-x86-0.8.1.msm])
define([PRODUCT_WINTUN_URL_amd64],     [https://build.openvpn.net/downloads/releases/wintun-amd64-0.8.1.msm])
dnl This is only to make build script happy - the file is only downloaded but not used, since there is no arm64 wintun MSM (yet)
define([PRODUCT_WINTUN_URL_arm64],     [https://build.openvpn.net/downloads/releases/wintun-amd64-0.8.1.msm])

dnl ovpn-dco binaries
define([PRODUCT_OVPN_DCO_URL_x86],     [https://github.com/OpenVPN/ovpn-dco-win/releases/download/0.8.2/ovpn-dco-win-0.8.2-x86.zip])
define([PRODUCT_OVPN_DCO_URL_amd64],   [https://github.com/OpenVPN/ovpn-dco-win/releases/download/0.8.2/ovpn-dco-win-0.8.2-amd64.zip])
define([PRODUCT_OVPN_DCO_URL_arm64],   [https://github.com/OpenVPN/ovpn-dco-win/releases/download/0.8.2/ovpn-dco-win-0.8.2-arm64.zip])

dnl OpenVPNServ2.exe binary
define([OPENVPNSERV2_URL], [http://build.openvpn.net/downloads/releases/openvpnserv2-1.4.0.1.exe])

dnl Easy RSA binaries (URL to .tar.gz file containing "easy-rsa-[EASYRSA_VERSION]" folder with Easy RSA)
define([EASYRSA_VERSION], [3.1.0])
define([EASYRSA_URL],     [https://github.com/OpenVPN/easy-rsa/releases/download/v3.1.0/EasyRSA-3.1.0-win64.zip])


dnl ============================================================
dnl MSI Provisioning
dnl ============================================================

dnl Define the product name and publisher.
define([PRODUCT_NAME],      [OpenVPN])
define([PRODUCT_PUBLISHER], [OpenVPN, Inc.])

dnl The package version as displayed by UI and used in filenames (no spaces, please).
define([PACKAGE_VERSION], [2.6git])

dnl The MSI product version in the form of n[.n[.n]] (numbers only).
dnl The third field is 100*product release + package version.
dnl The fourth field is ignored by MSI.
define([PRODUCT_VERSION], [2.6.0])

dnl The MSI product code MUST change on each product release.
define([PRODUCT_CODE], [{9122FCB2-2BB5-4115-8C0F-05D9B5EFE8D6}])

dnl The MSI upgrade codes MUST persist for all versions of the same product line.
dnl Please use own upgrade codes when deploying a non-official OpenVPN release.
define([UPGRADE_CODE_x86],   [{1195A47B-A37A-4055-9D34-B7A691F7E97B}])
define([UPGRADE_CODE_amd64], [{461BDF86-D389-4471-BF36-99806B64C127}])
define([UPGRADE_CODE_arm64], [{1E8C4DDC-9E93-4AE2-9495-DF86821EAA3A}])

dnl OpenVPN configration file extension (e.g. conf, ovpn...)
define([CONFIG_EXTENSION], [ovpn])
