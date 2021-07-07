@echo off

rem This script digitally signs MSI packages.
rem
rem Set `%ManifestCertificateThumbprint%` to SHA-1 thumbprint of your code signing
rem certificate. This thumbprint is used only to locate the certificate in user
rem certificate store. The signing and timestamping will use SHA-256 hashes.
rem
rem Set `%ManifestTimestampRFC3161Url%` to URL of your code signing cerificate provider's
rem RFC3161-compliant web service.
rem
rem Run this script after `cscript build.wsf msi` and before
rem `cscript build.wsf exe`.

signtool.exe sign /sha1 "%ManifestCertificateThumbprint%" /fd sha256 /tr "%ManifestTimestampRFC3161Url%" /td sha256 /d "OpenVPN Setup" image\*.msi
