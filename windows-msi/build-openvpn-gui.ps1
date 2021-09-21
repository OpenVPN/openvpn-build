# Build openvpn-gui with MSVC
#
# Example of setting the environment variables:
#
# $Env:CMAKE_TOOLCHAIN_FILE = "C:\Users\john\vcpkg\scripts\buildsystems\vcpkg.cmake"
# $Env:CMAKE = "C:\Program Files\CMake\bin\cmake.exe"

$CWD = Get-Location
$CMAKE=$Env:CMAKE
$CMAKE_TOOLCHAIN_FILE=$Env:CMAKE_TOOLCHAIN_FILE

# Enable running this script from anywhere
cd $PSScriptRoot

# Architecture names taken from here:
#
# https://docs.microsoft.com/en-us/cpp/build/cmake-presets-vs?view=msvc-160
"x64", "arm64", "Win32" | ForEach  {
	$platform = $_
    Write-Host "Building openvpn-gui ${platform}"
    if ( ( Test-Path "build_${platform}" ) -eq $False )
	{
        mkdir build_$platform
	}
    cd build_$platform
    & "$CMAKE" -A $platform -DCMAKE_TOOLCHAIN_FILE="$CMAKE_TOOLCHAIN_FILE" ..
    & "$CMAKE" --build . --config Release
    cd $PSScriptRoot
}

cd $CWD
