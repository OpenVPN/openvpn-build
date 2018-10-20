OpenVPN MSI Packaging
=====================

This folder contains scripts and binaries required to package OpenVPN 2.5 to a
set of platform-dependent MSI packages and an all-in-one EXE installer.


Requirements
------------

1. `WiX Toolset`_ - tested with 3.11.1
2. `unzip.exe`, `tar.exe` and `gunzip.exe` in path


Usage
-----

1. Prepare compiled and signed OpenVPN binaries in ``windows-msi`` folder::

    windows-msi
    ├── image-easy-rsa
    │   ├── 2.0
    │   │   └── openssl-1.0.0.cnf
    │   └── Windows
    │       ├── build-ca.bat
    │       ├── build-dh.bat
    │       ├── build-key.bat
    │       ├── build-key-pass.bat
    │       ├── build-key-pkcs12.bat
    │       ├── build-key-server.bat
    │       ├── clean-all.bat
    │       ├── index.txt.start
    │       ├── init-config.bat
    │       ├── README.txt
    │       ├── revoke-full.bat
    │       ├── serial.start
    │       └── vars.bat.sample
    ├── image-i686
    │   ├── bin
    │   │   ├── libcrypto-1_1.dll
    │   │   ├── liblzo2-2.dll
    │   │   ├── libopenvpnmsica.dll
    │   │   ├── libpkcs11-helper-1.dll
    │   │   ├── libssl-1_1.dll
    │   │   ├── openssl.exe
    │   │   ├── openvpn.exe
    │   │   ├── openvpn-gui.exe
    │   │   ├── openvpnserv.exe
    │   │   └── tapctl.exe
    │   └── share
    │       └── doc
    │           └── openvpn
    │               ├── sample
    │               │   ├── client.ovpn
    │               │   ├── sample.ovpn
    │               │   └── server.ovpn
    │               ├── license.txt
    │               └── openvpn.8.html
    ├── image-openvpnserv2
    │   └── openvpnserv2.exe
    ├── image-tap-windows6
    │   ├── amd64
    │   │   ├── attsgn
    │   │   │   ├── OemVista.inf
    │   │   │   ├── signed_by.cer
    │   │   │   ├── tap0901.cat
    │   │   │   └── tap0901.sys
    │   │   ├── whql
    │   │   │   ├── OemVista.inf
    │   │   │   ├── signed_by.cer
    │   │   │   ├── tap0901.cat
    │   │   │   └── tap0901.sys
    │   │   ├── OemVista.inf
    │   │   ├── signed_by.cer
    │   │   ├── tap0901.cat
    │   │   └── tap0901.sys
    │   ├── i386
    │   │   ├── attsgn
    │   │   │   ├── OemVista.inf
    │   │   │   ├── signed_by.cer
    │   │   │   ├── tap0901.cat
    │   │   │   └── tap0901.sys
    │   │   ├── OemVista.inf
    │   │   ├── signed_by.cer
    │   │   ├── tap0901.cat
    │   │   └── tap0901.sys
    │   └── include
    │       └── tap-windows.h
    └── image-x86_64
        ├── bin
        │   ├── libcrypto-1_1-x64.dll
        │   ├── liblzo2-2.dll
        │   ├── libopenvpnmsica.dll
        │   ├── libpkcs11-helper-1.dll
        │   ├── libssl-1_1-x64.dll
        │   ├── openssl.exe
        │   ├── openvpn.exe
        │   ├── openvpn-gui.exe
        │   ├── openvpnserv.exe
        │   └── tapctl.exe
        └── share
            └── doc
                └── openvpn
                    ├── sample
                    │   ├── client.ovpn
                    │   ├── sample.ovpn
                    │   └── server.ovpn
                    ├── license.txt
                    └── openvpn.8.html

2. Adjust ``version.md4``. It is important to increment ``PRODUCT_VERSION``
   *and* ``PRODUCT_VERSION_GUID`` on each release. MSI upgrading logic relies
   on this.

3. Open Command Prompt and ``cd`` to ``windows-msi`` folder.

4. Run ``cscript build.wsf`` to build the packages. The ``build.wsf`` is a
   simple Makefile type building tool developed to avoid Microsoft Visual
   Studio or GNU Make requirements. Refer to ``build.wsf`` for exact usage::

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

5. The MSI packages and EXE installer will be put to ``image`` subfolder.


Digital Signing
~~~~~~~~~~~~~~~

The ``build.wsf`` tool does not support digital signing of MSI and EXE files
(yet). For official packages, please keep the following guidelines in mind:

- Build MSI packages first: ``cscript build.wsf msi``. Sign them. Build EXE
  installer next: ``cscript build.wsf exe``. Sign it. This ensures the MSI
  packages inside EXE installer payload are signed.

- The ``cscript build.wsf exe`` does not build MSI packages. This is a safety
  feature to prevent accidental rebuild of already signed MSI files, should
  something accidentally touch any of the MSI package source files.

- EXE installer does not ask for elevation. It extracts and launches
  appropriate MSI package unelevated. The UAC elevation is requested only
  later when MSI package actually starts the install process. Therefore, it is
  vital to digitally sign MSI packages. Digital signing of EXE installer is
  optional.

- When signing MSI packages, add a signature description (``/d`` flag with
  ``signtool.exe`` utility). The ``msiexec.exe`` saves the MSI package under
  some random name and launches an elevated process to install it. When the
  signature on the MSI package contains no description, Windows displays the
  MSI filename instead on the UAC prompt. Now MSI having a random filename the
  UAC prompt gets quite confusing. Therefore, we strongly encourage you to add
  a description to the MSI signature accurately describing the package
  content.


.. _`WiX Toolset`: http://wixtoolset.org/
