# Build openvpn-gui with MSVC
#
# Example of setting the environment variables:
#
# $Env:VCPKG_ROOT = "C:\Users\john\vcpkg"
# $Env:CMAKE = "C:\Program Files\CMake\bin\cmake.exe"

$CWD = Get-Location
$CMAKE=$Env:CMAKE
$OSSL=$Env:OSSL

# Enable running this script from anywhere
Set-Location $PSScriptRoot

"x64", "arm64", "x86" | ForEach  {
	$platform = $_
    Write-Host "Building openvpn-gui ${platform}"
    & "$CMAKE" -S . --preset ${platform}-release-${OSSL}
    & "$CMAKE" --build --preset ${platform}-release-${OSSL}
}

Set-Location $CWD
