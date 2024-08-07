@echo off

rem This script digitally signs openvpn-build outputs.
rem
rem Set `%ManifestTimestampRFC3161Url%` to URL of your code signing cerificate provider's
rem RFC3161-compliant web service.
rem
rem Run this script before packaging.

java -jar %JsignJar%^
    --storetype %SigningStoreType%^
    --storepass %SigningStorePass%^
    --keystore %SigningKeyStore%^
    --alias %SigningStoreKeyName%^
    --certfile %SigningCertificateFile%^
    --tsmode RFC3161^
    --tsaurl %ManifestTimestampRFC3161Url%^
 ..\src\openvpn\out\build\win-%SignArch%-release\Release\openvpn.exe^
 ..\src\openvpn\out\build\win-%SignArch%-release\Release\lib*.dll^
 ..\src\openvpn\out\build\win-%SignArch%-release\src\openvpnmsica\Release\*.dll^
 ..\src\openvpn\out\build\win-%SignArch%-release\src\openvpnserv\Release\*.exe^
 ..\src\openvpn\out\build\win-%SignArch%-release\src\tapctl\Release\*.exe^
 ..\src\openvpn\out\build\win-%SignArch%-release\vcpkg_installed\%SignArchAlt%-windows-ovpn\tools\openssl\openssl.exe^
 ..\src\openvpn\out\build\win-%SignArch%-release\vcpkg_installed\%SignArchAlt%-windows-ovpn\bin\*.dll^
 ..\src\openvpn-gui\out\build\%SignArchAlt%\Release\openvpn-gui.exe^
 ..\src\openvpn-gui\out\build\%SignArchAlt%\Release\*.dll
