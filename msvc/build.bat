@echo off
rem OpenVPN Project MSVC Compile Build
rem Copyright (C) 2008-2012 Alon Bar-Lev <alon.barlev@gmail.com>
rem
rem This program is free software: you can redistribute it and/or modify
rem it under the terms of the GNU General Public License as published by
rem the Free Software Foundation, either version 3 of the License, or
rem (at your option) any later version.
rem
rem This program is distributed in the hope that it will be useful,
rem but WITHOUT ANY WARRANTY; without even the implied warranty of
rem MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
rem GNU General Public License for more details.
rem
rem You should have received a copy of the GNU General Public License
rem along with this program.  If not, see <http://www.gnu.org/licenses/>.
rem

rem Required software:
rem - Visual Studio 2017
rem - perl
rem
rem To build only openvpn, run
rem    set MODE=OPENVPN&& build.bat
rem To build only dependencies, run
rem    set MODE=DEPS&& build.bat

setlocal ENABLEDELAYEDEXPANSION

cd /d %0\..
SET ROOT=%CD%

call build-env.bat
if exist build-env-local.bat call build-env-local.bat

if exist "%VCHOME%\vcvarsall.bat" (
	call "%VCHOME%\vcvarsall.bat"
) else if exist "%VCHOME%\bin\vcvars64.bat" (
	call "%VCHOME%\bin\vcvars64.bat"
) else if exist "%VCHOME%\Auxiliary\Build\vcvars64.bat" (
	call "%VCHOME%\Auxiliary\Build\vcvars64.bat"
) else (
	echo Cannot detect visual studio environment
	goto error
)

perl -e "exit 0" > nul 2>&1
if not errorlevel 1 goto cont1
echo perl is required
goto error
:cont1

if "%MODE%" == "OPENVPN" goto build_openvpn

echo Cleanup

rmdir /q /s "%TARGET%" > nul 2>&1
rmdir /q /s download.tmp > nul 2>&1
rmdir /q /s build.tmp > nul 2>&1
mkdir download.tmp
mkdir build.tmp
mkdir sources > nul 2>&1

echo Download

if not exist "%P7Z%" (
	echo Downloading 7-zip
	cscript //nologo wget.js "%P7ZIP_URL%" download.tmp\7zip.zip
	if errorlevel 1 goto error
	mkdir tools > nul 2>&1
	cscript //nologo unzip.js download.tmp\7zip.zip tools
	if errorlevel 1 goto error
)

set download_list=openssl lzo pkcs11 tap
if "%OPENVPN_SOURCE%"=="tarball" set download_list=%download_list% openvpn
for %%f in (%download_list%) do (
	set URL=!%%f_URL!
	for /f %%i in ("!URL!") do set NAME=%%~ni%%~xi
	set found=
	for %%i in (sources\%%f*) do set found=1
	if "!found!" == "" (
		echo Downloading !URL!
		cscript //nologo wget.js !URL! sources/!NAME!
		if errorlevel 1 goto error
	)
)

if "%OPENVPN_SOURCE%"=="git" "%GIT%" clone --branch "%OPENVPN_BRANCH%" "%OPENVPN_GIT%" build.tmp/openvpn

echo Extract

for %%f in (sources\*.gz sources\*.bz2) do "%P7Z%" x -odownload.tmp "%%f"
if errorlevel 1 goto error
for %%f in (download.tmp\*) do "%P7Z%" x -obuild.tmp "%%f"
if errorlevel 1 goto error
for %%f in (sources\*.zip) do "%P7Z%" x -obuild.tmp "%%f"
if errorlevel 1 goto error

echo Build OpenSSL

cd build.tmp\openssl*
perl Configure VC-WIN64A --prefix="%TARGET%"
if errorlevel 1 goto error
call ms\do_win64a.bat
if errorlevel 1 goto error
nmake -f ms\ntdll.mak
if errorlevel 1 goto error
nmake -f ms\ntdll.mak install
if errorlevel 1 goto error
cd %ROOT%

echo Build LZO

cd build.tmp\lzo*
call B\win64\vc_dll.bat
rem if errorlevel 1 goto error - returns 1!!
xcopy include\lzo "%TARGET%\include\lzo" /e /i /y
if errorlevel 1 goto error
copy *.dll* "%TARGET%\bin"
if errorlevel 1 goto error
copy *.lib "%TARGET%\lib"
if errorlevel 1 goto error
cd %ROOT%

echo Build pkcs11-helper

cd build.tmp\pkcs11-helper*
cd lib
nmake -f Makefile.w32-vc OPENSSL=1 OPENSSL_HOME="%TARGET%" all
if errorlevel 1 goto error
copy *.dll* "%TARGET%\bin"
if errorlevel 1 goto error
del "%TARGET%\bin"\pkcs11-helper*.def
del "%TARGET%\bin"\pkcs11-helper*.lib
copy *.lib "%TARGET%\lib"
if errorlevel 1 goto error
cd ..
xcopy include\pkcs11-helper-1.0 "%TARGET%\include\pkcs11-helper-1.0" /e /i /y
if errorlevel 1 goto error
del "%TARGET%\include\pkcs11-helper-1.0"\Makefile.*
cd %ROOT%

echo TAP

copy build.tmp\tap-windows6-%TAP_VERSION%\src\tap-windows.h "%TARGET%\include"
if errorlevel 1 goto error

if "%MODE%" == "DEPS" goto end

:build_openvpn

echo Build OpenVPN

cd build.tmp\openvpn*
if exist "%ROOT%\config\config-msvc-local.h" copy "%ROOT%\config\config-msvc-local.h" .
set OPENVPN_DEPROOT=%TARGET%
call msvc-build.bat
if errorlevel 1 goto error
copy "x64-Output\%RELEASE%"\*.exe "%TARGET%\bin"
if errorlevel 1 goto error
copy include\openvpn-*.h "%TARGET%\include"
if errorlevel 1 goto error
cd %ROOT%

echo SUCCESS
set rc=0
goto end
:error
echo FAILED!
set rc=1
:end
cd %ROOT%
endlocal
exit /b %rc%
