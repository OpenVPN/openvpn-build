param(
    # Must be top directory of openvpn-build checkout
    [string] $topdir = "${PSScriptRoot}/..",
    [string] $arch = "all",
    [switch] $sign
    )

### Preparations
if(-not($topdir)) {
    Write-Host "Usage: build-and-package.ps1 [-topdir <topdir>] [-arch <all|x86|amd64|arm64>] [-sign]"
    exit 1
}

$allowed_arch = "all", "x86", "amd64", "arm64"
if (-Not($allowed_arch.Contains($arch)))
{
    Write-Host "-arch must be:" $allowed_arch
    exit 1
}

# at the moment signing script doesn't support per-architecture signing
if ($sign -And $arch -ne "all")
{
    Write-Host "-arch must be 'all' or omitted when -sign is specified"
    exit 1
}

# Convert relative path to absolute to prevent breakages below
$basedir = (Resolve-Path -Path $topdir)

$basedir_exists = Test-Path $basedir

if ($basedir_exists -ne $True) {
    Write-Host "ERROR: directory ${basedir} does not exist!"
    exit 1
}

# sane defaults
$Env:VCPKG_ROOT = "${basedir}\src\vcpkg"
$Env:VCPKG_OVERLAY_PORTS = "${basedir}\windows-msi\vcpkg-ports"
$Env:CMAKE = "C:\\Program Files\\CMake\\bin\\cmake.exe"
$Env:ManifestTimestampRFC3161Url = "http://timestamp.digicert.com"

if ((Test-Path "${PSScriptRoot}/build-and-package-env.ps1") -ne $True) {
    Write-Host "WARNING: configuration file (build-and-package-env.ps1) is missing"
} else {
    . "${PSScriptRoot}/build-and-package-env.ps1"
}

if ($sign -And -not($Env:ManifestCertificateThumbprint)) {
    Write-Host "ERROR: signing requested but Env:ManifestCertificateThumbprint not set"
    exit 1
}

# At the end of the build return to the directory we started from
$cwd = Get-Location

Set-Location "$Env:VCPKG_ROOT"
& .\bootstrap-vcpkg.bat

### Build OpenVPN-GUI
Set-Location "${basedir}\src\openvpn-gui"

$gui_arch = @()
switch ($arch)
{
    'all'
    {
        $gui_arch = "x64", "arm64", "x86"
    }
    'x86'
    {
        $gui_arch += "x86"
    }
    'amd64'
    {
        $gui_arch += "x64"
    }
    'arm64'
    {
        $gui_arch += "arm64"
    }
}

$gui_arch | ForEach-Object  {
	$platform = $_
    Write-Host "Building openvpn-gui ${platform}"
    & "$Env:CMAKE" --preset ${platform}
    & "$Env:CMAKE" --build --preset ${platform}-release
}

### Build OpenVPN
Set-Location "${basedir}\src\openvpn"

$ovpn_arch = @("amd64", "arm64", "x86")
if ($arch -ne "all") {
    $ovpn_arch = @($arch)
}

$ovpn_arch | ForEach-Object  {
	$platform = $_
    Write-Host "Building openvpn ${platform}"
    # VCPKG_HOST_TRIPLET required to use host tools like pkgconf
    & "$Env:CMAKE" --preset "win-${platform}-release"
    & "$Env:CMAKE" --build --preset "win-${platform}-release"
}

### Sign binaries
if ($sign) {
    Set-Location "${basedir}\windows-msi"
    $Env:SignScript = "sign-openvpn.bat"
    & .\sign-binaries.bat
} else {
    Write-Host "Skip signing binaries"
}

### Build MSI
Set-Location "${basedir}\windows-msi"

switch ($arch)
{
    'all'
    {
        & cscript.exe build.wsf msi
    }
    'amd64'
    {
        & cscript.exe build.wsf msi-amd64
    }
    'x86'
    {
        & cscript.exe build.wsf msi-x86
    }
    'arm64'
    {
        & cscript.exe build.wsf msi-arm64
    }
}

### Sign MSI
if ($sign) {
    $Env:SignScript = "sign-msi.bat"
    & .\sign-binaries.bat
} else {
    Write-Host "Skip signing MSI"
}

Set-Location $cwd
