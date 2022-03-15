param([string] $basedir)

### Preparations
if(-not($basedir)) {
	Write-Host "Usage: build-and-package.ps1 -basedir <basedir>"
    exit 1
}

# Convert relative path to absolute to prevent breakages below
$basedir = (Resolve-Path -Path $basedir)

$basedir_exists = Test-Path $basedir

if ($basedir_exists -ne $True) {
    Write-Host "ERROR: directory ${basedir} does not exist!"
	exit 1
}

if ((Test-Path "${PSScriptRoot}/build-and-package-env.ps1") -ne $True) {
	Write-Host "ERROR: configuration file (build-and-package-env.ps1I is missing"
	exit 1
}

. "${PSScriptRoot}/build-and-package-env.ps1"

# At the end of the build return to the directory we started from
$cwd = Get-Location

### Ensure that we use latest "contrib" vcpkg ports
cd "${basedir}\openvpn"
& git.exe pull

cd "${basedir}\vcpkg"
& .\bootstrap-vcpkg.bat
& git.exe pull

$architectures = @('x64','x86','arm64')

ForEach ($arch in $architectures) {
	# openssl3:${arch}-windows is required for openvpn-gui builds
    & .\vcpkg.exe --overlay-ports "${basedir}\openvpn\contrib\vcpkg-ports" --overlay-triplets "${basedir}\openvpn\contrib\vcpkg-triplets" install --triplet "${arch}-windows-ovpn" lz4 lzo openssl3  pkcs11-helper tap-windows6 "openssl3:${arch}-windows"

    & .\vcpkg.exe --overlay-ports "${basedir}\openvpn\contrib\vcpkg-ports" --overlay-triplets  "${basedir}\openvpn\contrib\vcpkg-triplets" upgrade --no-dry-run

    & .\vcpkg.exe integrate install
}

### Build OpenVPN-GUI
cd "${basedir}\openvpn-gui"
& git.exe pull
Copy-Item "${basedir}\openvpn-build\windows-msi\build-openvpn-gui.ps1" "${basedir}\openvpn-gui\"
.\build-openvpn-gui.ps1

### Build OpenVPN
cd "${basedir}\openvpn"
& git.exe pull

ForEach ($bat in "msbuild-x64.bat", "msbuild-x64_x86.bat", "msbuild-x64_arm64.bat") {
    If ((Test-Path $bat) -ne $True) {
		Copy-Item "${basedir}\openvpn-build\windows-msi\${bat}" .
	}
}

& .\msbuild-x64.bat
& .\msbuild-x64_x86.bat
& .\msbuild-x64_arm64.bat

### Sign binaries
cd "${basedir}\openvpn-build\windows-msi"

$Env:SignScript = "sign-openvpn.bat"
& .\sign-binaries.bat

### Build MSI
cd "${basedir}\openvpn-build\windows-msi"
& cscript.exe build.wsf msi

### Sign MSI
$Env:SignScript = "sign-msi.bat"
& .\sign-binaries.bat

cd $cwd
