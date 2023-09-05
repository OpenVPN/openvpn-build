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
 ..\src\openvpn\out\build\win-amd64-release\Release\*.exe^
 ..\src\openvpn\out\build\win-amd64-release\Release\*.dll^
 ..\src\openvpn\out\build\win-amd64-release\src\openvpnmsica\Release\*.exe^
 ..\src\openvpn\out\build\win-amd64-release\src\openvpnserv\Release\*.exe^
 ..\src\openvpn\out\build\win-amd64-release\src\tapctl\Release\*.exe^
 ..\src\openvpn\out\build\win-arm64-release\Release\*.exe^
 ..\src\openvpn\out\build\win-arm64-release\Release\*.dll^
 ..\src\openvpn\out\build\win-arm64-release\src\openvpnmsica\Release\*.exe^
 ..\src\openvpn\out\build\win-arm64-release\src\openvpnserv\Release\*.exe^
 ..\src\openvpn\out\build\win-arm64-release\src\tapctl\Release\*.exe^
 ..\src\openvpn\out\build\win-x86-release\Release\*.exe^
 ..\src\openvpn\out\build\win-x86-release\Release\*.dll^
 ..\src\openvpn\out\build\win-x86-release\src\openvpnmsica\Release\*.exe^
 ..\src\openvpn\out\build\win-x86-release\src\openvpnserv\Release\*.exe^
 ..\src\openvpn\out\build\win-x86-release\src\tapctl\Release\*.exe^
 ..\src\openvpn\out\build\win-amd64-release\vcpkg_installed\x64-windows-ovpn\tools\openssl\openssl.exe^
 ..\src\openvpn\out\build\win-amd64-release\vcpkg_installed\x64-windows-ovpn\bin\*.dll^
 ..\src\openvpn\out\build\win-arm64-release\vcpkg_installed\arm64-windows-ovpn\tools\openssl\openssl.exe^
 ..\src\openvpn\out\build\win-arm64-release\vcpkg_installed\arm64-windows-ovpn\bin\*.dll^
 ..\src\openvpn\out\build\win-x86-release\vcpkg_installed\x86-windows-ovpn\tools\openssl\openssl.exe^
 ..\src\openvpn\out\build\win-x86-release\vcpkg_installed\x86-windows-ovpn\bin\*.dll^
 ..\src\openvpn-gui\out\build\x64\Release\openvpn-gui.exe^
 ..\src\openvpn-gui\out\build\x64\Release\*.dll^
 ..\src\openvpn-gui\out\build\arm64\Release\openvpn-gui.exe^
 ..\src\openvpn-gui\out\build\arm64\Release\*.dll^
 ..\src\openvpn-gui\out\build\x86\Release\openvpn-gui.exe^
 ..\src\openvpn-gui\out\build\x86\Release\*.dll
