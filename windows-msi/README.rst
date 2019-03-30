OpenVPN MSI Packaging
=====================

This folder contains scripts and binaries required to package OpenVPN 2.4+ to
a set of platform-dependent MSI packages and an all-in-one EXE installer.


Requirements
------------

1. `WiX Toolset`_ - tested with 3.11.1
2. ``unzip.exe`` - tested with UnZip 6.00 of 20 April 2009, by Info-ZIP
3. GNU ``tar.exe`` - tested with 1.30
4. ``gzip.exe`` - tested with 1.9
5. ``bzip2.exe`` - tested with 1.0.6, 6-Sept-2010

Note: ``unzip.exe``, ``tar.exe``, ``gzip.exe``, and ``bzip2.exe`` must be in
``%PATH%``.


Usage
-----

1. Cross compile OpenVPN using ``openvpn-build/generic`` build system on
   Linux.

2. Digitally sign binaries in ``openvpn-build/generic/image-win(32|64)/openvpn/
   bin`` folder. The ``tapctl.exe`` requires elevation, therefore it should be
   digitally signed at least.

   If the code signing is performed on Windows, see ``sign-openvpn.bat`` as a
   suggestion.

3. Adjust ``version.md4``. It is important to increment ``PRODUCT_VERSION``
   *and* ``PRODUCT_VERSION_GUID`` on each release. MSI upgrading logic relies
   on this.

4. Open Command Prompt on Windows and ``cd`` to ``openvpn-build\windows-msi``
   folder.

   To transfer the openvpn-build site to a Windows computer, you can copy it,
   or share it using Samba on the Linux box. On a Windows computer mount the
   Samba share as a drive (e.g. ``Z:``), since you cannot ``cd`` to a UNC path
   of form ``\\computer\share\path``.

5. Run ``cscript build.wsf`` to build the packages. The ``build.wsf`` is a
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

   If the code signing is performed on Windows, the following command order is
   suggested::

    cscript build.wsf msi
    sign-msi
    cscript build.wsf exe
    sign-exe

6. The MSI packages and EXE installer will be put to ``image`` subfolder.


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
  optional, but recommended to decrease the chance Windows SmartScreen will
  treat our EXE installer as malware on downloads.

- When signing MSI packages, set a signature description (``/d`` flag with
  ``signtool.exe`` utility). The ``msiexec.exe`` saves the MSI package under
  some random name and launches an elevated process to install it. When the
  signature on the MSI package contains no description, Windows displays the
  MSI filename instead on the UAC prompt. Now MSI having a random filename,
  the UAC prompt gets quite confusing. Therefore, we strongly encourage you to
  set a description in the MSI signature accurately describing the package
  content.


.. _`WiX Toolset`: http://wixtoolset.org/
