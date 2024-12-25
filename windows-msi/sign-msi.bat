@echo off

rem This script digitally signs MSI packages.
rem
rem Set `%ManifestTimestampRFC3161Url%` to URL of your code signing cerificate provider's
rem RFC3161-compliant web service.
rem
rem Run this script after `cscript build.wsf msi` and before
rem `cscript build.wsf exe`.

java -jar %JsignJar%^
    --storetype %SigningStoreType%^
    --storepass %SigningStorePass%^
    --keystore %SigningKeyStore%^
    --alias %SigningStoreKeyName%^
    --certfile %SigningCertificateFile%^
    --tsmode RFC3161^
    --tsaurl %ManifestTimestampRFC3161Url%^
 image\*.msi
