@echo off

if "%OPENSSL_VERSION%"=="" set OPENSSL_VERSION=1.0.2p
if "%LZO_VERSION%"=="" set LZO_VERSION=2.06
if "%PKCS11_VERSION%"=="" set PKCS11_VERSION=1.11
if "%TAP_VERSION%"=="" set TAP_VERSION=master
if "%GITHUB_USER%"=="" set GITHUB_USER=OpenVPN
if "%OPENVPN_VERSION%"=="" set OPENVPN_VERSION=master
if "%OPENVPN_BRANCH%"=="" set OPENVPN_BRANCH=build
if "%OPENVPN_SOURCE%"=="" set OPENVPN_SOURCE=tarball

set OPENSSL_URL=http://www.openssl.org/source/openssl-%OPENSSL_VERSION%.tar.gz
set LZO_URL=http://www.oberhumer.com/opensource/lzo/download/lzo-%LZO_VERSION%.tar.gz
set PKCS11_URL=https://vorboss.dl.sourceforge.net/project/opensc/pkcs11-helper/pkcs11-helper-%PKCS11_VERSION%.tar.bz2
set TAP_URL=https://github.com/OpenVPN/tap-windows6/archive/%TAP_VERSION%.zip
set OPENVPN_URL=https://github.com/%GITHUB_USER%/openvpn/archive/%OPENVPN_VERSION%.tar.gz
set OPENVPN_GIT=https://github.com/OpenVPN/openvpn.git
set P7ZIP_URL=https://datapacket.dl.sourceforge.net/project/sevenzip/7-Zip/9.20/7za920.zip

if "%ProgramFiles(x86)%"=="" set ProgramFiles(x86)=%ProgramFiles%
if "%VSCOMNTOOLS%"=="" set VSCOMNTOOLS=%ProgramFiles(x86)%\Microsoft Visual Studio\2017\Professional\Common7\Tools
if not exist "%VSCOMNTOOLS%" set VSCOMNTOOLS=%ProgramFiles(x86)%\Microsoft Visual Studio\2017\Community\Common7\Tools
if not exist "%VSCOMNTOOLS%" set VSCOMNTOOLS=%ProgramFiles(x86)%\Microsoft Visual Studio\2017\Enterprise\Common7\Tools
if "%VSHOME%"=="" SET VSHOME=%VSCOMNTOOLS%\..\..
if "%VCHOME%"=="" SET VCHOME=%VSHOME%\VC

if "%P7Z%"=="" SET P7Z=tools\7za.exe
if "%GIT%"=="" SET GIT=c:\Program Files\Git\bin\git.exe

if "%TARGET%"=="" SET TARGET=%ROOT%\image
if "%RELEASE%"=="" SET RELEASE=Release
