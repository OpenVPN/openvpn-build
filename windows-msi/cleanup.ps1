# Script that cleans up temporary build files and artefacts to ensure clean builds.

param([string] $basedir)

function Remove-IfExists {
    param (
        [string]$path
    )

    if (Test-Path $path) {
        Remove-Item -Recurse -Force $path
    }
}

$cwd = Get-Location

#  Check parameters
if(-not($basedir)) {
    Write-Host "Usage: cleanup.ps1 -basedir <basedir>"
    exit 1
}

$basedir = (Resolve-Path -Path $basedir)
$basedir_exists = Test-Path $basedir

# Ensure that base directory exists
if ($basedir_exists -ne $True) {
    Write-Host "ERROR: directory ${basedir} does not exist!"
    exit 1
}

# Ensure that the base directory contains the subdirectories it should contain
$subdirs = "openvpn", "openvpn-gui", "openvpn-build", "vcpkg"
$all_dirs_present = $True

ForEach ($dir in $subdirs) {
    if (-Not(Test-Path "${basedir}\${dir}")) {
        Write-Host "ERROR: did not find directory `"${dir}`""
        $all_dirs_present = $False
    }
}

if ($all_dirs_present -ne $True) {
    Write-Host "One or more directories this script expected to clean up were not found. Please check that `$basedir is set correctly."
    exit 1
}

# Clean up openvpn
Set-Location "${basedir}\openvpn"
Remove-IfExists -Path Win32-Output
Remove-IfExists -Path ARM64-Output
Remove-IfExists -Path x64-Output
Remove-IfExists -Path src\openvpn\vcpkg_installed

# Clean up openvpn-gui
Set-Location "${basedir}\openvpn-gui"
Remove-IfExists -Path out

# Clean up openvpn-build
Set-Location "${basedir}\openvpn-build\windows-msi"
Remove-IfExists -Path image
Remove-IfExists -Path sources
Remove-IfExists -Path tmp

# Clean up vcpkg
Set-Location "${basedir}\vcpkg"
if (Test-Path vcpkg.exe) {
    & .\vcpkg.exe integrate remove
}
Set-Location $basedir
Remove-IfExists -Path vcpkg
git clone https://github.com/microsoft/vcpkg.git
Remove-IfExists -Path "${HOME}\AppData\Local\vcpkg"

Set-Location $cwd