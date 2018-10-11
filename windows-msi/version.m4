dnl define the product version
define([PRODUCT_NAME], [OpenVPN])
define([PRODUCT_PUBLISHER], [OpenVPN Technologies, Inc.])
define([PRODUCT_VERSION], [2.4.6])

dnl The version GUID MUST change for each release.
define([PRODUCT_VERSION_GUID], [{80493CF5-3B4C-4B46-9054-BFC3D6E13C0E}])

dnl The upgrade GUID(s) MUST persist for all versions of the same product line.
define([PRODUCT_UPGRADE_GUID_x86],   [{1195A47B-A37A-4055-9D34-B7A691F7E97B}])
define([PRODUCT_UPGRADE_GUID_amd64], [{461BDF86-D389-4471-BF36-99806B64C127}])

dnl OpenVPN configration file extension (e.g. conf, ovpn...)
define([CONFIG_EXTENSION], [ovpn])