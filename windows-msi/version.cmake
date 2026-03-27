# ============================================================
# Downloadables
# ============================================================

# TAP-Windows binaries
# renovate: datasource=github-releases depName=OpenVPN/tap-windows6
set(PRODUCT_TAP_WIN_VERSION           "9.27.0")
# Note: Not handled by renovate
set(PRODUCT_TAP_WIN_INSTALLER_VERSION "I0")
set(PRODUCT_TAP_WIN_COMPONENT_ID      "tap0901")
set(PRODUCT_TAP_WIN_NAME              "TAP-Windows")

# ovpn-dco binaries
# renovate: datasource=github-releases depName=OpenVPN/ovpn-dco-win
set(PRODUCT_OVPN_DCO_VERSION     "2.8.2")

# OpenVPNServ2.exe binary
# renovate: datasource=github-releases depName=OpenVPN/openvpnserv2 versioning=loose
set(OVPNSERV2_VERSION "2.0.1.0")

# Easy-RSA binaries:
# URL to .zip file containing "easy-rsa-[EASYRSA_VERSION]" folder with Easy-RSA.
# The OpenSSL binaries, which come with Easy-RSA, are not used by Openvpn-build.
# The only binaries which Openvpn-build uses from Easy-RSA, are the *nix style
# (32bit only) binaries for Windows, from easy-rsa/distro/windows/bin.
# Further details: easy-rsa/distro/windows/Licensing/mksh-Win32.txt
# renovate: datasource=github-releases depName=OpenVPN/easy-rsa
set(EASYRSA_VERSION "3.2.5")

# ============================================================
# MSI Provisioning
# ============================================================

# Define the product name and publisher.
set(PRODUCT_NAME      "OpenVPN")
set(PRODUCT_PUBLISHER "OpenVPN, Inc.")

# The package version as displayed by UI and used in filenames (no spaces, please).
set(PACKAGE_VERSION "2.8_git-I001")

# The MSI product version in the form of n[.n[.n]] (numbers only).
# The third field is 100*openvpn bugfix release + MSI build number.
# So for the 2nd MSI build for OpenVPN 2.6.3 use 2.6.302
set(PRODUCT_VERSION "2.8.0")

# The MSI product code MUST change on each product release.
set(PRODUCT_CODE "{AFB9E34B-0126-474A-AF75-A7C69AB91905}")

# The MSI upgrade codes MUST persist for all versions of the same product line.
# Please use own upgrade codes when deploying a non-official OpenVPN release.
set(UPGRADE_CODE_x86   "{1195A47B-A37A-4055-9D34-B7A691F7E97B}")
set(UPGRADE_CODE_amd64 "{461BDF86-D389-4471-BF36-99806B64C127}")
set(UPGRADE_CODE_arm64 "{1E8C4DDC-9E93-4AE2-9495-DF86821EAA3A}")

# OpenVPN configuration file extension (e.g. conf, ovpn...)
set(CONFIG_EXTENSION "ovpn")
