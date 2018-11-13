dnl ============================================================
dnl Downloadables
dnl ============================================================

dnl TAP-Windows binaries (URL to .zip file containing "tap-windows-[PRODUCT_TAP_WIN_VERSION]" folder with driver)
define([PRODUCT_TAP_WIN_VERSION],      [9.21.2])
define([PRODUCT_TAP_WIN_URL],          [http://build.openvpn.net/downloads/releases/tap-windows-9.21.2.zip])
define([PRODUCT_TAP_WIN_COMPONENT_ID], [tap0901])

dnl OpenVPNServ2.exe binary
define([OPENVPNSERV2_URL], [http://build.openvpn.net/downloads/releases/openvpnserv2-1.3.0.0.exe])

dnl Easy RSA binaries (URL to .tar.gz file containing "easy-rsa-[EASYRSA_VERSION]" folder with Easy RSA)
define([EASYRSA_VERSION], [2.3.3_master])
define([EASYRSA_URL],     [http://build.openvpn.net/downloads/releases/easy-rsa-2.3.3_master.tar.gz])


dnl ============================================================
dnl MSI Provisioning
dnl ============================================================

dnl Define the product version
define([PRODUCT_NAME],      [OpenVPN])
define([PRODUCT_PUBLISHER], [OpenVPN Technologies, Inc.])
define([PRODUCT_VERSION],   [2.4.6])
define([PRODUCT_TAP_NAME],  [TAP-Windows])

dnl The version GUID MUST change for each release.
define([PRODUCT_VERSION_GUID], [{80493CF5-3B4C-4B46-9054-BFC3D6E13C0E}])

dnl The upgrade GUIDs MUST persist for all versions of the same product line.
dnl Please use own upgrade GUIDs when deploying a non-official OpenVPN release.
define([PRODUCT_UPGRADE_GUID_x86],   [{1195A47B-A37A-4055-9D34-B7A691F7E97B}])
define([PRODUCT_UPGRADE_GUID_amd64], [{461BDF86-D389-4471-BF36-99806B64C127}])

dnl OpenVPN configration file extension (e.g. conf, ovpn...)
define([CONFIG_EXTENSION], [ovpn])
