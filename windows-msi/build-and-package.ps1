param(
    # Must be top directory of openvpn-build checkout
    [string] $topdir = "${PSScriptRoot}/..",
    # Version of OpenSSL port to use ("ossl1.1.1" or "ossl3")
    [string] $ossl = "ossl3",
    [string] $arch = "all",
    [switch] $nosign
    )

### Preparations
if(-not($topdir)) {
    Write-Host "Usage: build-and-package.ps1 [-topdir <topdir>] [-ossl <ossl1.1.1|ossl3>] [-arch <all|x86|amd64|arm64>] [-nosign]"
    exit 1
}

$allowed_arch = "all", "x86", "amd64", "arm64"
if (-Not($allowed_arch.Contains($arch)))
{
    Write-Host "-arch must be:" $allowed_arch
    exit 1
}

# at the moment signing script doesn't support per-architecture signing
if (-Not($nosign) -And $arch -ne "all")
{
    Write-Host "-arch must be 'all' or omitted when -nosign is not specified"
    exit 1
}

# Convert relative path to absolute to prevent breakages below
$basedir = (Resolve-Path -Path $topdir)

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

Set-Location "${basedir}\src\vcpkg"
& .\bootstrap-vcpkg.bat
& .\vcpkg.exe integrate install

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
    & "$Env:CMAKE" -S . --preset ${platform}-release-${ossl}
    & "$Env:CMAKE" --build --preset ${platform}-release-${ossl}
}

### Build OpenVPN
Set-Location "${basedir}\src\openvpn"

if (($arch -eq "all") -Or ($arch -eq "amd64")) {
    msbuild "openvpn.sln" /p:Configuration="Release" /p:Platform="x64" /maxcpucount /t:Build
}

if (($arch -eq "all") -Or ($arch -eq "x86")) {
    msbuild "openvpn.sln" /p:Configuration="Release" /p:Platform="Win32" /maxcpucount /t:Build
}

if (($arch -eq "all") -Or ($arch -eq "arm64")) {
    msbuild "openvpn.sln" /p:Configuration="Release" /p:Platform="ARM64" /maxcpucount /t:Build
}

### Sign binaries
if (-not $nosign) {
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
if (-not $nosign) {
    $Env:SignScript = "sign-msi.bat"
    & .\sign-binaries.bat
} else {
    Write-Host "Skip signing MSI"
}

Set-Location $cwd
