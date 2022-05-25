# Used by build scripts build-and-package.sh calls
$Env:VCPKG_ROOT = "${basedir}\vcpkg"
$Env:VCPKG_OVERLAY_PORTS="${basedir}\openvpn-build\windows-msi\vcpkg-ports"
$Env:CMAKE = "C:\\Program Files\\CMake\\bin\\cmake.exe"
$Env:ManifestCertificateThumbprint = "thumbprint"
$Env:ManifestTimestampRFC3161Url = "http://timestamp.digicert.com"
$Env:OSSL=${ossl}
