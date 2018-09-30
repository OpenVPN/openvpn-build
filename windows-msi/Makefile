#
#  openvpn-build — OpenVPN packaging
#
#  Copyright (C) 2018 Simon Rozman <simon@rozman.si>
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License version 2
#  as published by the Free Software Foundation.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License along
#  with this program; if not, write to the Free Software Foundation, Inc.,
#  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#
#

PRODUCT_PUBLISHER=OpenVPN Technologies, Inc.
PRODUCT_NAME=OpenVPN
PRODUCT_VERSION=2.4.6
PRODUCT_VERSION_GUID={6094AE77-0BCA-407E-B30E-747E7AABCA81}
CONFIG_EXTENSION=ovpn

#
# Folder with compiled OpenVPN
# ("-x86_64" or "-i686" is appended)
#
!IFNDEF SOURCE_DIR
SOURCE_DIR=image
!ENDIF

#
# Folder with Easy RSA
#
!IFNDEF EASYRSA_DIR
EASYRSA_DIR=image-easy-rsa
!ENDIF

#
# Folder with openvpnserv2.exe
#
!IFNDEF OPENVPNSERV2_DIR
OPENVPNSERV2_DIR=image-openvpnserv2
!ENDIF

#
# Folder to store intermmediate files while building
#
!IFNDEF BUILD_DIR
BUILD_DIR=build.tmp
!ENDIF

#
# Folder to store output files
#
!IFNDEF OUTPUT_DIR
OUTPUT_DIR=image
!ENDIF

#
# Platform to build (i386 or amd64)
#
!IFNDEF PLAT
PLAT=amd64
!ENDIF

#
# Platform-specific parameters
#
!IF "$(PLAT)" == "i386"
SOURCE_DIR=$(SOURCE_DIR)-i686
PROGRAM_FILES_DIR=ProgramFilesFolder
OPENSSL_PLAT=
WIX_PLAT=x86
PRODUCT_UPGRADE_GUID={30B0C64D-FEF6-4A4E-ABBA-750531E0F3FB}
!ELSEIF "$(PLAT)" == "amd64"
SOURCE_DIR=$(SOURCE_DIR)-x86_64
PROGRAM_FILES_DIR=ProgramFiles64Folder
OPENSSL_PLAT=-x64
WIX_PLAT=x64
PRODUCT_UPGRADE_GUID={E5B5C1A4-F5CE-4010-90DD-7984AC8B5FF2}
!ELSE
!ERROR Unknown platform. Please, set PLAT to "i386" or "amd64".
!ENDIF


#
# WiX flags
#
WIX_CANDLE_FLAGS=$(WIX_CANDLE_FLAGS) \
	-nologo \
	-ext WixUtilExtension \
	-arch "$(WIX_PLAT)" \
	-dPRODUCT_PUBLISHER="$(PRODUCT_PUBLISHER)" \
	-dPRODUCT_NAME="$(PRODUCT_NAME)" \
	-dPRODUCT_VERSION="$(PRODUCT_VERSION)" \
	-dPRODUCT_VERSION_GUID="$(PRODUCT_VERSION_GUID)" \
	-dCONFIG_EXTENSION="$(CONFIG_EXTENSION)" \
	-dPROGRAM_FILES_DIR="$(PROGRAM_FILES_DIR)" \
	-dOPENSSL_PLAT="$(OPENSSL_PLAT)" \
	-dPRODUCT_UPGRADE_GUID="$(PRODUCT_UPGRADE_GUID)"
WIX_LIGHT_FLAGS=$(WIX_LIGHT_FLAGS) \
	-nologo \
	-dcl:high \
	-spdb \
	-ext WixUtilExtension \
	-b build="$(BUILD_DIR)" \
	-b openvpn="$(SOURCE_DIR)" \
	-b easyrsa="$(EASYRSA_DIR)" \
	-b openvpnserv2="$(OPENVPNSERV2_DIR)"


#
# Main Targets
# (Default one first)
#

All ::

Clean ::


#
# WiX Sources
#

"$(BUILD_DIR)\gui.wixobj" : "gui.wxs" "$(BUILD_DIR)"
	"$(WIX)bin\candle.exe" $(WIX_CANDLE_FLAGS) -out $@ "gui.wxs"

"$(BUILD_DIR)\$(PLAT)\msi.wixobj" : "msi.wxs" "$(BUILD_DIR)\$(PLAT)"
	"$(WIX)bin\candle.exe" $(WIX_CANDLE_FLAGS) -out $@ "msi.wxs"

"$(OUTPUT_DIR)\$(PRODUCT_NAME)-$(PLAT).msi" : \
	"artwork\info.ico" \
	"artwork\folder_new.ico" \
	"artwork\folder_up.ico" \
	"artwork\header.bmp" \
	"artwork\openvpn.ico" \
	"$(SOURCE_DIR)\bin\libcrypto-1_1$(OPENSSL_PLAT).dll" \
	"$(SOURCE_DIR)\bin\liblzo2-2.dll" \
	"$(SOURCE_DIR)\bin\libpkcs11-helper-1.dll" \
	"$(SOURCE_DIR)\bin\libssl-1_1$(OPENSSL_PLAT).dll" \
	"$(SOURCE_DIR)\bin\openssl.exe" \
	"$(SOURCE_DIR)\bin\openvpn.exe" \
	"$(SOURCE_DIR)\bin\openvpn-gui.exe" \
	"$(SOURCE_DIR)\bin\openvpnserv.exe" \
	"$(OPENVPNSERV2_DIR)\openvpnserv2.exe" \
	"$(BUILD_DIR)\README-config.txt" \
	"..\windows-nsis\INSTALL-win32.txt" \
	"$(SOURCE_DIR)\share\doc\openvpn\license.txt" \
	"$(SOURCE_DIR)\share\doc\openvpn\openvpn.8.html" \
	"$(EASYRSA_DIR)\Windows\build-ca.bat" \
	"$(EASYRSA_DIR)\Windows\build-dh.bat" \
	"$(EASYRSA_DIR)\Windows\build-key.bat" \
	"$(EASYRSA_DIR)\Windows\build-key-pass.bat" \
	"$(EASYRSA_DIR)\Windows\build-key-pkcs12.bat" \
	"$(EASYRSA_DIR)\Windows\build-key-server.bat" \
	"$(EASYRSA_DIR)\Windows\clean-all.bat" \
	"$(EASYRSA_DIR)\Windows\index.txt.start" \
	"$(EASYRSA_DIR)\Windows\init-config.bat" \
	"$(EASYRSA_DIR)\2.0\openssl-1.0.0.cnf" \
	"$(EASYRSA_DIR)\Windows\README.txt" \
	"$(EASYRSA_DIR)\Windows\revoke-full.bat" \
	"$(EASYRSA_DIR)\Windows\serial.start" \
	"$(EASYRSA_DIR)\Windows\vars.bat.sample" \
	"$(BUILD_DIR)\README-log.txt" \
	"$(SOURCE_DIR)\share\doc\openvpn\sample\client.ovpn" \
	"$(SOURCE_DIR)\share\doc\openvpn\sample\sample.ovpn" \
	"$(SOURCE_DIR)\share\doc\openvpn\sample\server.ovpn" \
	"$(BUILD_DIR)\gui.wixobj" \
	"$(BUILD_DIR)\$(PLAT)\msi.wixobj" \
	"$(OUTPUT_DIR)"
	"$(WIX)bin\light.exe" $(WIX_LIGHT_FLAGS) -out "$(@:"=).tmp" "$(BUILD_DIR)\gui.wixobj" "$(BUILD_DIR)\$(PLAT)\msi.wixobj"
!IFDEF MANIFESTCERTIFICATETHUMBPRINT
	signtool.exe sign /sha1 "$(MANIFESTCERTIFICATETHUMBPRINT)" /fd sha256 /tr "$(MANIFESTTIMESTAMPRFC3161URL)" /d "$(PRODUCT_NAME) $(PRODUCT_VERSION) Setup" /q "$(@:"=).tmp"
!ENDIF
	attrib.exe +r "$(@:"=).tmp"
	if exist $@ attrib.exe -r $@
	move /y "$(@:"=).tmp" $@ > NUL

All :: "$(OUTPUT_DIR)\$(PRODUCT_NAME)-$(PLAT).msi"

Clean ::
	-if exist "$(BUILD_DIR)\gui.wixobj"                   del /f /q "$(BUILD_DIR)\gui.wixobj"
	-if exist "$(BUILD_DIR)\$(PLAT)\msi.wixobj"           del /f /q "$(BUILD_DIR)\$(PLAT)\msi.wixobj"
	-if exist "$(OUTPUT_DIR)\$(PRODUCT_NAME)-$(PLAT).msi" del /f /q "$(OUTPUT_DIR)\$(PRODUCT_NAME)-$(PLAT).msi"


#
# README files
#

"$(BUILD_DIR)\README-config.txt" : "$(BUILD_DIR)"
	move /y << $@ > NUL
This directory or its subdirectories should contain $(PRODUCT_NAME)
configuration files each having an extension of .$(CONFIG_EXTENSION)

When $(PRODUCT_NAME) is started as a service, a separate $(PRODUCT_NAME)
process will be instantiated for each configuration file.

When $(PRODUCT_NAME) GUI is started configs in this directory are added
to the list of available connections.
<<NOKEEP

"$(BUILD_DIR)\README-log.txt" : "$(BUILD_DIR)"
	move /y << $@ > NUL
This directory will contain the log files for $(PRODUCT_NAME)
sessions which are being run as a service.
Logs for connections started by the GUI are kept in USERPROFILE\OpenVPN\log
<<NOKEEP

Clean ::
	-if exist "$(BUILD_DIR)\README-config.txt" del /f /q "$(BUILD_DIR)\README-config.txt"
	-if exist "$(BUILD_DIR)\README-log.txt"    del /f /q "$(BUILD_DIR)\README-log.txt"


#
# Folder Creation
#

"$(BUILD_DIR)" \
"$(BUILD_DIR)\$(PLAT)" \
"$(OUTPUT_DIR)" :
	if not exist $@ md $@

"$(BUILD_DIR)\$(PLAT)" : "$(BUILD_DIR)"
