rem Building ARM64 binaries
call "C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Auxiliary\Build\vcvarsall.bat" x64_arm64
msbuild "openvpn.sln" /p:Configuration="Release" /p:Platform="ARM64" /maxcpucount /t:Build