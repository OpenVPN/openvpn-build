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

### Ensure that OpenVPN and OpenVPN GUI are using the latest dependencies
cd "${basedir}\openvpn"
& git.exe pull

cd "${basedir}\vcpkg"
& git.exe pull
& .\bootstrap-vcpkg.bat
& .\vcpkg.exe upgrade --overlay-ports "${basedir}\openvpn\contrib\vcpkg-ports" --overlay-triplets "${basedir}\openvpn\contrib\vcpkg-triplets" --no-dry-run


### Build OpenVPN-GUI
Copy-Item "${basedir}\openvpn-build\windows-msi\build-openvpn-gui.ps1" "${basedir}\openvpn-gui\"
cd "${basedir}\openvpn-gui"
.\build-openvpn-gui.ps1


### Build OpenVPN
cd "${basedir}\openvpn"

ForEach ($bat in "msbuild-x64.bat", "msbuild-x64_x86.bat", "msbuild-x64_arm64.bat") {
    If ((Test-Path $bat) -ne $True) {
		Invoke-Webrequest -Uri "https://raw.githubusercontent.com/${openvpn_vagrant_owner}/openvpn-vagrant/${openvpn_vagrant_branch}/buildbot-host/buildmaster/${bat}" -Outfile $bat
	}
}

& .\msbuild-x64.bat
& .\msbuild-x64_x86.bat
& .\msbuild-x64_arm64.bat

### Sign binaries
cd "${basedir}\openvpn-build\windows-msi"

if ((Test-Path "sign-binaries.bat") -ne $True) {
	Invoke-Webrequest -Uri "https://raw.githubusercontent.com/${openvpn_vagrant_owner}/openvpn-vagrant/${openvpn_vagrant_branch}/buildbot-host/buildmaster/sign-binaries.bat" -Outfile sign-binaries.bat
}

$Env:SignScript = "sign-openvpn.bat"
& .\sign-binaries.bat

### Build MSI
cd "${basedir}\openvpn-build\windows-msi"
& cscript.exe build.wsf msi

### Sign MSI
$Env:SignScript = "sign-msi.bat"
& .\sign-binaries.bat

cd $cwd
