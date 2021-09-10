# Used internally by build-and-package.sh
$openvpn_vagrant_owner = "OpenVPN"
$openvpn_vagrant_branch = "master"

# Used by build scripts build-and-package.sh calls
$Env:CMAKE_TOOLCHAIN_FILE = "${basedir}\vcpkg\scripts\buildsystems\vcpkg.cmake"
$Env:CMAKE = "C:\\Program Files\\CMake\\bin\\cmake.exe"
$Env:ManifestCertificateThumbprint = "thumbprint"
$Env:ManifestTimestampRFC3161Url = "http://timestamp.digicert.com"
