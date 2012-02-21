@echo off

if "%OPENSSL_VERSION%"=="" set OPENSSL_VERSION=1.0.0g
if "%LZO_VERSION%"=="" set LZO_VERSION=2.06
if "%PKCS11_VERSION%"=="" set PKCS11_VERSION=1.10
if "%TAP_VERSION%"=="" set TAP_VERSION=9.9
if "%OPENVPN_VERSION%"=="" set OPENVPN_VERSION=2.3_alpha1
if "%OPENVPN_BRANCH%"=="" set OPENVPN_BRANCH=build
if "%OPENVPN_SOURCE%"=="" set OPENVPN_SOURCE=tarball

set OPENSSL_URL=http://www.openssl.org/source/openssl-%OPENSSL_VERSION%.tar.gz
set LZO_URL=http://www.oberhumer.com/opensource/lzo/download/lzo-%LZO_VERSION%.tar.gz
set PKCS11_URL=https://github.com/downloads/alonbl/pkcs11-helper/pkcs11-helper-%PKCS11_VERSION%.tar.bz2
set TAP_URL=https://github.com/downloads/OpenVPN/tap-windows/tap-windows-%TAP_VERSION%.zip
set OPENVPN_URL=https://github.com/downloads/OpenVPN/openvpn/openvpn-%OPENVPN_VERSION%.tar.gz
set OPENVPN_GIT=https://github.com/OpenVPN/openvpn.git
set P7ZIP_URL=http://garr.dl.sourceforge.net/project/sevenzip/7-Zip/9.20/7za920.zip

if "%ProgramFiles(x86)%"=="" SET ProgramFiles(x86)=%ProgramFiles%
if "%VSCOMNTOOLS%"=="" SET VSCOMNTOOLS=%ProgramFiles(x86)%\Microsoft Visual Studio 10.0\Common7\Tools
if "%VSCOMNTOOLS%"=="" SET VSCOMNTOOLS=%ProgramFiles(x86)%\Microsoft Visual Studio 9.0\Common7\Tools
if "%VSHOME%"=="" SET VSHOME=%VSCOMNTOOLS%\..\..
if "%VCHOME%"=="" SET VCHOME=%VSHOME%\VC

if "%P7Z%"=="" SET P7Z=tools\7za.exe
if "%GIT%"=="" SET GIT=c:\Program Files\Git\bin\git.exe

if "%TARGET%"=="" SET TARGET=%ROOT%\image
if "%RELEASE%"=="" SET RELEASE=Release
