rem Building x86 binaries
call "C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Auxiliary\Build\vcvarsall.bat" x64_x86
msbuild "openvpn.sln" /p:Configuration="Release" /p:Platform="Win32" /maxcpucount /t:Build
