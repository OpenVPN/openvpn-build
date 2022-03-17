param(
    # Must be a directory with openvpn, openvpn-gui, vcpkg and
    # openvpn-build side by side
    [string] $basedir,
    # Version of OpenSSL port to use ("openssl" or "openssl3")
    [string] $openssl = "openssl3"
    )

### Preparations
if(-not($basedir)) {
    Write-Host "Usage: build-and-package.ps1 -basedir <basedir> [-openssl] <openssl|openssl3>"
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
    Write-Host "ERROR: configuration file (build-and-package-env.ps1) is missing"
    exit 1
}

. "${PSScriptRoot}/build-and-package-env.ps1"

# At the end of the build return to the directory we started from
$cwd = Get-Location

### Ensure that we use latest "contrib" vcpkg ports
Set-Location "${basedir}\openvpn"
& git.exe pull

Set-Location "${basedir}\vcpkg"
& git.exe pull
& .\bootstrap-vcpkg.bat

$architectures = @('x64','x86','arm64')
ForEach ($arch in $architectures) {
    # openssl:${arch}-windows is required for openvpn-gui builds
    & .\vcpkg.exe `
        --overlay-ports "${basedir}\openvpn\contrib\vcpkg-ports" `
        --overlay-ports "${basedir}\openvpn-build\windows-msi\vcpkg-ports" `
        --overlay-triplets "${basedir}\openvpn\contrib\vcpkg-triplets" `
        install --triplet "${arch}-windows-ovpn" lz4 lzo $openssl pkcs11-helper tap-windows6 "${openssl}:${arch}-windows"

    # Our contrib ports may be more recent that what are available upstream, so
    # ensure that those are taken into account when upgrading
    & .\vcpkg.exe `
        --overlay-ports "${basedir}\openvpn\contrib\vcpkg-ports" `
        --overlay-ports "${basedir}\openvpn-build\windows-msi\vcpkg-ports" `
        --overlay-triplets  "${basedir}\openvpn\contrib\vcpkg-triplets" `
        upgrade --no-dry-run

    & .\vcpkg.exe integrate install
}

### Build OpenVPN-GUI
Set-Location "${basedir}\openvpn-gui"
& git.exe pull
Copy-Item "${basedir}\openvpn-build\windows-msi\build-openvpn-gui.ps1" "${basedir}\openvpn-gui\"
.\build-openvpn-gui.ps1

### Build OpenVPN
Set-Location "${basedir}\openvpn"
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
Set-Location "${basedir}\openvpn-build\windows-msi"

$Env:SignScript = "sign-openvpn.bat"
& .\sign-binaries.bat

### Build MSI
Set-Location "${basedir}\openvpn-build\windows-msi"
& cscript.exe build.wsf msi

### Sign MSI
$Env:SignScript = "sign-msi.bat"
& .\sign-binaries.bat

Set-Location $cwd
