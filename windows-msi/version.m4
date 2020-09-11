dnl ============================================================
dnl Downloadables
dnl ============================================================

dnl TAP-Windows binaries
define([PRODUCT_TAP_WIN_URL_x86],      [https://build.openvpn.net/downloads/releases/tap-windows-9.24.4-I601-i386.msm])
define([PRODUCT_TAP_WIN_URL_amd64],    [https://build.openvpn.net/downloads/releases/tap-windows-9.24.4-I601-amd64.msm])
define([PRODUCT_TAP_WIN_COMPONENT_ID], [tap0901])
define([PRODUCT_TAP_WIN_NAME],         [TAP-Windows])

dnl Wintun binaries
define([PRODUCT_WINTUN_URL_x86],       [https://www.wintun.net/builds/wintun-x86-0.8.1.msm])
define([PRODUCT_WINTUN_URL_amd64],     [https://www.wintun.net/builds/wintun-amd64-0.8.1.msm])

dnl OpenVPNServ2.exe binary
define([OPENVPNSERV2_URL], [http://build.openvpn.net/downloads/releases/openvpnserv2-1.4.0.1.exe])

dnl Easy RSA binaries (URL to .tar.gz file containing "easy-rsa-[EASYRSA_VERSION]" folder with Easy RSA)
define([EASYRSA_VERSION], [2.3.3_master])
define([EASYRSA_URL],     [http://build.openvpn.net/downloads/releases/easy-rsa-2.3.3_master.tar.gz])


dnl ============================================================
dnl MSI Provisioning
dnl ============================================================

dnl Define the product name and publisher.
define([PRODUCT_NAME],      [OpenVPN])
define([PRODUCT_PUBLISHER], [OpenVPN, Inc.])

dnl The package version as displayed by UI and used in filenames (no spaces, please).
define([PACKAGE_VERSION], [2.5-beta4-I601])

dnl The MSI product version in the form of n[.n[.n]] (numbers only).
dnl The third field is 100*product release + package version.
dnl The fourth field is ignored by MSI.
define([PRODUCT_VERSION], [2.5.014])

dnl The MSI product code MUST change on each product release.
define([PRODUCT_CODE], [{E5931AF4-2A8F-48A5-AFC8-3E048AC137B9}])

dnl The MSI upgrade codes MUST persist for all versions of the same product line.
dnl Please use own upgrade codes when deploying a non-official OpenVPN release.
define([UPGRADE_CODE_x86],   [{1195A47B-A37A-4055-9D34-B7A691F7E97B}])
define([UPGRADE_CODE_amd64], [{461BDF86-D389-4471-BF36-99806B64C127}])

dnl OpenVPN configration file extension (e.g. conf, ovpn...)
define([CONFIG_EXTENSION], [ovpn])
