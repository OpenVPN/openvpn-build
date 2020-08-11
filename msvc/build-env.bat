@echo off

if "%OPENSSL_VERSION%"=="" set OPENSSL_VERSION=1.1.1f
if "%LZO_VERSION%"=="" set LZO_VERSION=2.10
if "%PKCS11_VERSION%"=="" set PKCS11_VERSION=1.22
if "%TAP_VERSION%"=="" set TAP_VERSION=master
if "%GITHUB_USER%"=="" set GITHUB_USER=OpenVPN
if "%OPENVPN_VERSION%"=="" set OPENVPN_VERSION=master
if "%OPENVPN_BRANCH%"=="" set OPENVPN_BRANCH=build
if "%OPENVPN_SOURCE%"=="" set OPENVPN_SOURCE=tarball

set OPENSSL_URL=http://www.openssl.org/source/openssl-%OPENSSL_VERSION%.tar.gz
set LZO_URL=http://www.oberhumer.com/opensource/lzo/download/lzo-%LZO_VERSION%.tar.gz
set PKCS11_URL=https://github.com/OpenSC/pkcs11-helper/releases/download/pkcs11-helper-%PKCS11_VERSION%/pkcs11-helper-%PKCS11_VERSION%.tar.bz2
set TAP_URL=https://github.com/OpenVPN/tap-windows6/archive/%TAP_VERSION%.zip
set OPENVPN_URL=https://github.com/%GITHUB_USER%/openvpn/archive/%OPENVPN_VERSION%.tar.gz
set OPENVPN_GIT=https://github.com/OpenVPN/openvpn.git
set P7ZIP_URL=https://netcologne.dl.sourceforge.net/project/sevenzip/7-Zip/9.20/7za920.zip

if "%ProgramFiles(x86)%"=="" set ProgramFiles(x86)=%ProgramFiles%
if "%VSCOMNTOOLS%"=="" set VSCOMNTOOLS=%ProgramFiles(x86)%\Microsoft Visual Studio\2019\Professional\Common7\Tools
if not exist "%VSCOMNTOOLS%" set VSCOMNTOOLS=%ProgramFiles(x86)%\Microsoft Visual Studio\2019\Community\Common7\Tools
if not exist "%VSCOMNTOOLS%" set VSCOMNTOOLS=%ProgramFiles(x86)%\Microsoft Visual Studio\2019\Enterprise\Common7\Tools
if "%VSHOME%"=="" SET VSHOME=%VSCOMNTOOLS%\..\..
if "%VCHOME%"=="" SET VCHOME=%VSHOME%\VC
if not exist "%VSCOMNTOOLS%" SET VCHOME=%ProgramFiles(x86)%\Microsoft Visual Studio\2019\BuildTools\VC

if "%P7Z%"=="" SET P7Z=tools\7za.exe
if "%GIT%"=="" SET GIT=c:\Program Files\Git\bin\git.exe
if "%NASM_DIR%"=="" SET NASM_DIR=c:\Program Files\NASM

if "%TARGET%"=="" SET TARGET=%ROOT%\image
if "%RELEASE%"=="" SET RELEASE=Release

rem OpenSSL build defines RC as "1" when undefined on some environments.
if "%RC%"=="" SET RC=rc
