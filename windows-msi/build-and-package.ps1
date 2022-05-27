param(
    # Must be a directory with openvpn, openvpn-gui, vcpkg and
    # openvpn-build side by side
    [string] $basedir,
    # Version of OpenSSL port to use ("ossl1.1.1" or "ossl3")
    [string] $ossl = "ossl1.1.1",
    [string] $arch = "all",
    [switch] $nosign,
    [switch] $nodevprompt
    )

### Preparations
if(-not($basedir)) {
    Write-Host "Usage: build-and-package.ps1 -basedir <basedir> [-openssl] <ossl1.1.1|ossl3> [-arch] <all|x86|amd64|arm64> [-nosign] [-nodevprompt]"
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
& .\vcpkg.exe integrate install

### Build OpenVPN-GUI
Set-Location "${basedir}\openvpn-gui"
& git.exe pull

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
Set-Location "${basedir}\openvpn"
& git.exe pull

if (($arch -eq "all") -Or ($arch -eq "amd64")) {
    if (-not($nodevprompt))
    {
        & "C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Auxiliary\Build\vcvarsall.bat" x64
    }
    msbuild "openvpn.sln" /p:Configuration="Release" /p:Platform="x64" /maxcpucount /t:Build
}

if (($arch -eq "all") -Or ($arch -eq "x86")) {
    if (-not($nodevprompt))
    {
        & "C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Auxiliary\Build\vcvarsall.bat" x64_x86
    }
    msbuild "openvpn.sln" /p:Configuration="Release" /p:Platform="Win32" /maxcpucount /t:Build
}

if (($arch -eq "all") -Or ($arch -eq "arm64")) {
    if (-not($nodevprompt))
    {
        & "C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Auxiliary\Build\vcvarsall.bat" x64_arm64
    }
    msbuild "openvpn.sln" /p:Configuration="Release" /p:Platform="ARM64" /maxcpucount /t:Build
}

### Sign binaries
if (-not $nosign) {
    Set-Location "${basedir}\openvpn-build\windows-msi"
    $Env:SignScript = "sign-openvpn.bat"
    & .\sign-binaries.bat
} else {
    Write-Host "Skip signing binaries"
}

### Build MSI
Set-Location "${basedir}\openvpn-build\windows-msi"

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
