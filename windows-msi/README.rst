﻿OpenVPN MSI Packaging
=====================

This folder contains scripts and binaries required to build and package OpenVPN
2.5+ and its dependencies to a set of platform-dependent MSI packages and an
all-in-one EXE installer.

Requirements for building MSI packages
--------------------------------------

1. `WiX Toolset`_ - tested with 3.11.1
2. ``unzip.exe`` - tested with UnZip 6.00 of 20 April 2009, by Info-ZIP
3. GNU ``tar.exe`` - tested with 1.30
4. ``gzip.exe`` - tested with 1.9
5. ``bzip2.exe`` - tested with 1.0.6, 6-Sept-2010

Note: ``unzip.exe``, ``tar.exe``, ``gzip.exe``, and ``bzip2.exe`` must be in
``%PATH%``.

Requirements for building OpenVPN and its dependencies
------------------------------------------------------

Building and packaging OpenVPN on Windows is a fairly complex process with lots
of dependencies. If you're starting from scratch it is recommended to use the
"msibuilder" VM in `openvpn-vagrant <https://github.com/OpenVPN/openvpn-vagrant/>`_.

If using Vagrant and Virtualbox is not an option you should be able to run the
Vagrant provisioning scripts with suitable parameters on a fresh Windows 10-based system,
though only Windows Server 2019 is tested.

In either case you will end up with a directory layout such as this: 

- openvpn-build

- vcpkg (openssl etc.)

- openvpn-gui

- openvpn

Once the directories are laid out properly you need to add your code-signing
PFX certificate into the certificate store::

    Import-PfxCertificate -FilePath .\mycert.pfx -CertstoreLocation Cert:\Currentuser\My -Password (ConvertTo-SecureString -String "mypass" -Force -AsPlainText)

This command will print out the certificate thumbprint which you'll need later.

Now create a config file, ``build-and-package-env.ps1``, next to ``build-and-package.ps1``::
    
    # Used by build scripts build-and-package.sh calls
    $Env:VCPKG_ROOT = "${basedir}\vcpkg" 
    $Env:VCPKG_OVERLAY_PORTS="${basedir}\openvpn-build\windows-msi\vcpkg-ports"
    $Env:CMAKE = "C:\\Program Files\\CMake\\bin\\cmake.exe"
    $Env:ManifestCertificateThumbprint = "cert thumbprint" 
    $Env:ManifestTimestampRFC3161Url = "http://timestamp.digicert.com" 

Building and packaging
----------------------

First step adjust ``version.m4``. It is important to increment
``PRODUCT_VERSION`` *and* ``PRODUCT_VERSION_GUID`` on each release. MSI
upgrading logic relies on this.

To build and package::

    cd openvpn-build\windows-msi
    .\build-and-package.ps1 -basedir ..\..

You can also define which OpenSSL vcpkg port to use:

    .\build-and-package.ps1 -basedir ..\.. -openssl openssl
    .\build-and-package.ps1 -basedir ..\.. -openssl openssl3

If everything was set up correctly you should see three MSI packages in
``image`` subfolder, each signed and containing signed binaries.

build.wsf
---------

The ``build.wsf`` is a simple Makefile type building tool used to generate MSI
packages and EXE installers. It expects OpenVPN and its dependencies to be
built and in the directory layout described above. It was developed to avoid
Microsoft Visual Studio or GNU Make requirements. Refer to ``build.wsf`` for
exact usage::

    C:\openvpn-build\windows-msi>cscript build.wsf /?
    Microsoft (R) Windows Script Host Version 5.812
    Copyright (C) Microsoft Corporation. All rights reserved.
    
    Packages OpenVPN for Windows.
    Usage: build.wsf [<command>] [/a]
    
    Options:
    
    <command> : Command to execute (default: "all")
    a         : Builds all targets even if output is newer than input
    
    Commands:
    all     Builds MSI packages and EXE installer
    msi     Builds MSI packages only
    exe     Builds EXE installer only
    clean   Cleans intermediate and output files

The ``cscript build.wsf exe`` command does not build MSI packages. This is a
safety feature to prevent accidental rebuild of already signed MSI files,
should something accidentally touch any of the MSI package source files.

Digital signing
---------------

The ``build.wsf`` tool does not support digital signing of MSI and EXE files
(yet). The ``sign-openvpn.bat`` and ``sign-msi.bat`` scripts handle that part.

The EXE installer does not ask for elevation. It extracts and launches
appropriate MSI package unelevated. The UAC elevation is requested only later
when MSI package actually starts the install process. Therefore, it is vital to
digitally sign MSI packages.

When signing MSI packages, set a signature description (``/d`` flag with
``signtool.exe`` utility). The ``msiexec.exe`` saves the MSI package under some
random name and launches an elevated process to install it. When the signature
on the MSI package contains no description, Windows displays the MSI filename
instead on the UAC prompt. Now MSI having a random filename, the UAC prompt
gets quite confusing. Therefore, we strongly encourage you to set a description
in the MSI signature accurately describing the package content.

Digital signing of EXE installer is optional, but recommended to decrease the
chance Windows SmartScreen will treat our EXE installer as malware on
downloads.

Signing of ``tapctl.exe`` is mandatory as it requires elevation of privileges.

.. _`WiX Toolset`: http://wixtoolset.org/
