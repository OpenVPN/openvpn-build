dnl ============================================================
dnl Downloadables
dnl ============================================================

dnl TAP-Windows binaries
dnl renovate: datasource=github-releases depName=OpenVPN/tap-windows6
define([PRODUCT_TAP_WIN_VERSION],           [9.26.0])
dnl Note: Not handled by renovate
define([PRODUCT_TAP_WIN_INSTALLER_VERSION], [I0])
define([PRODUCT_TAP_WIN_COMPONENT_ID],      [tap0901])
define([PRODUCT_TAP_WIN_NAME],              [TAP-Windows])

dnl Wintun binaries
define([PRODUCT_WINTUN_URL_x86],       [https://build.openvpn.net/downloads/releases/wintun-x86-0.8.1.msm])
define([PRODUCT_WINTUN_URL_amd64],     [https://build.openvpn.net/downloads/releases/wintun-amd64-0.8.1.msm])
dnl This is only to make build script happy - the file is only downloaded but not used, since there is no arm64 wintun MSM (yet)
define([PRODUCT_WINTUN_URL_arm64],     [https://build.openvpn.net/downloads/releases/wintun-amd64-0.8.1.msm])

dnl ovpn-dco binaries
dnl renovate: datasource=github-releases depName=OpenVPN/ovpn-dco-win
define([PRODUCT_OVPN_DCO_VERSION],     [1.0.0])

dnl OpenVPNServ2.exe binary
define([OPENVPNSERV2_URL], [http://build.openvpn.net/downloads/releases/openvpnserv2-1.4.0.1.exe])

dnl Easy-RSA binaries:
dnl URL to .zip file containing "easy-rsa-[EASYRSA_VERSION]" folder with Easy-RSA.
dnl The OpenSSL binaries, which come with Easy-RSA, are not used by Openvpn-build.
dnl The only binaries which Openvpn-build uses from Easy-RSA, are the *nix style
dnl (32bit only) binaries for Windows, from easy-rsa/distro/windows/bin.
dnl Further details: easy-rsa/distro/windows/Licensing/mksh-Win32.txt
dnl renovate: datasource=github-releases depName=OpenVPN/easy-rsa
define([EASYRSA_VERSION], [3.1.7])

dnl ============================================================
dnl MSI Provisioning
dnl ============================================================

dnl Define the product name and publisher.
define([PRODUCT_NAME],      [OpenVPN])
define([PRODUCT_PUBLISHER], [OpenVPN, Inc.])

dnl The package version as displayed by UI and used in filenames (no spaces, please).
define([PACKAGE_VERSION], [2.7git])

dnl The MSI product version in the form of n[.n[.n]] (numbers only).
dnl The third field is 100*openvpn bugfix release + MSI build number.
dnl So for the 2nd MSI build for OpenVPN 2.6.3 use 2.6.302
define([PRODUCT_VERSION], [2.7.0])

dnl The MSI product code MUST change on each product release.
define([PRODUCT_CODE], [{9122FCB2-2BB5-4115-8C0F-05D9B5EFE8D6}])

dnl The MSI upgrade codes MUST persist for all versions of the same product line.
dnl Please use own upgrade codes when deploying a non-official OpenVPN release.
define([UPGRADE_CODE_x86],   [{1195A47B-A37A-4055-9D34-B7A691F7E97B}])
define([UPGRADE_CODE_amd64], [{461BDF86-D389-4471-BF36-99806B64C127}])
define([UPGRADE_CODE_arm64], [{1E8C4DDC-9E93-4AE2-9495-DF86821EAA3A}])

dnl OpenVPN configration file extension (e.g. conf, ovpn...)
define([CONFIG_EXTENSION], [ovpn])
