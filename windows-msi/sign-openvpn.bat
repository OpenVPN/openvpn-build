@echo off

rem This script digitally signs openvpn-build outputs.
rem
rem Set `%ManifestCertificateThumbprint%` to SHA-1 thumbprint of your code signing
rem certificate. This thumbprint is used only to locate the certificate in user
rem certificate store. The signing and timestamping will use SHA-256 hashes.
rem
rem Set `%ManifestTimestampRFC3161Url%` to URL of your code signing cerificate provider's
rem RFC3161-compliant web service.
rem
rem Run this script before packaging.

signtool.exe sign /sha1 "%ManifestCertificateThumbprint%" /fd sha256 /tr "%ManifestTimestampRFC3161Url%" /td sha256^
 ..\..\openvpn\x64-Output\Release\*.exe^
 ..\..\openvpn\x64-Output\Release\*.dll^
 ..\..\openvpn\Win32-Output\Release\*.exe^
 ..\..\openvpn\Win32-Output\Release\*.dll^
 ..\..\openvpn\ARM64-Output\Release\*.exe^
 ..\..\openvpn\ARM64-Output\Release\*.dll^
 ..\..\vcpkg\installed\x64-windows-ovpn\tools\openssl\openssl.exe^
 ..\..\vcpkg\installed\x86-windows-ovpn\tools\openssl\openssl.exe^
 ..\..\vcpkg\installed\arm64-windows-ovpn\tools\openssl\openssl.exe^
 ..\..\openvpn-gui\build_x64\Release\openvpn-gui.exe^
 ..\..\openvpn-gui\build_Win32\Release\openvpn-gui.exe^
 ..\..\openvpn-gui\build_arm64\Release\openvpn-gui.exe