OpenVPN MSI Packaging
=====================

This folder contains scripts and binaries required to build and package OpenVPN
2.5+ and its dependencies to a set of platform-dependent MSI packages.

Requirements for building MSI packages
--------------------------------------

These are the tools used directly by this buildsystem. For
the dependencies of building OpenVPN itself see the next
section.

This buildsystem only works on Windows machines, it should
work on Windows 10 and newer and Windows Server 2019 and newer.

1. CMake 3.20 or later
2. `WiX Toolset`_ - tested with 3.14.1

Requirements for building OpenVPN and its dependencies
------------------------------------------------------

These tools are required for building OpenVPN and OpenVPN-GUI

1. Visual Studio build tools
2. Git
3. Powershell Core (pwsh)
4. Python 3 + docutils package

All other dependencies are built via vcpkg.

Signing
-------

If you want to do code signing, set the following environment variables (shown
here for ``cmd.exe``) before building with ``-DSIGN_BINARIES=ON``::

    set JsignJar=path\to\jsign.jar
    set SigningStoreType=GOOGLECLOUD
    set SigningKeyStore=your-keyring
    set SigningStoreKeyName=your-key
    set SigningCertificateFile=path\to\certificate.pem
    set SigningStorePass=your-access-token
    set ManifestTimestampRFC3161Url=http://timestamp.digicert.com

Or for PowerShell::

    $env:JsignJar = "path\to\jsign.jar"
    $env:SigningStoreType = "GOOGLECLOUD"
    $env:SigningKeyStore = "your-keyring"
    $env:SigningStoreKeyName = "your-key"
    $env:SigningCertificateFile = "path\to\certificate.pem"
    $env:SigningStorePass = "your-access-token"
    $env:ManifestTimestampRFC3161Url = "http://timestamp.digicert.com"

Building and packaging
----------------------

First adjust ``version.cmake``. It is important to increment
``PRODUCT_VERSION`` *and* ``PRODUCT_CODE`` on each release. MSI
upgrading logic relies on this. You can use ``bump-version.ps1``
script for this purpose.

To build and package::

    cd openvpn-build\windows-msi
    cmake -B build
    cmake --build build

To build a single architecture or with signing::

    cmake -B build -DOPENVPN_ARCH=amd64 -DSIGN_BINARIES=ON
    cmake --build build

If everything was set up correctly you should see MSI packages in the
``build\image`` subfolder.

Individual targets can be built directly::

    cmake --build build --target msi_amd64

Cleaning up
-----------

Remove the ``build`` directory to clean all build artefacts, or use::

    cmake --build build --target clean

.. _`WiX Toolset`: http://wixtoolset.org/
