OpenVPN project buildsystems
#####################################################
.. image:: https://travis-ci.org/OpenVPN/openvpn-build.svg?branch=master
  :target: https://travis-ci.org/OpenVPN/openvpn-build
  :alt: TravisCI status
.. image:: https://ci.appveyor.com/api/projects/status/github/OpenVPN/openvpn-build?branch=master&svg=true
  :target: https://ci.appveyor.com/project/mattock/openvpn-build
  :alt: AppVeyor status

About
**************************************************

    These directories contain scripts to help build and
    package OpenVPN and its dependencies for various
    hardware platforms and operating systems (e.g. Windows,
    ARM). You do not need any of these scripts if you're
    building a native version of OpenVPN on a UNIX-like
    operating system.

    Thorough documentation is available in the OpenVPN wiki:

    <https://community.openvpn.net/openvpn>

Directories
**************************************************

    The "generic" subdir contains scripts to cross-compile
    OpenVPN using mingw_w64 (e.g. Linux -> Windows).

    The "msvc" subdir is used to compile OpenVPN on Windows
    for Windows using Microsoft Visual Studio 2019.

    The "windows-msi" subdir contains scripts to
    package OpenVPN for Windows.

    The "windows-nsis" subdir contains scripts to
    cross-compile and package OpenVPN for Windows.

    Please refer to the README files in the subdirectories
    for further information.

Patches
**************************************************

    The "generic/patches" directory contains patches applied
    to OpenVPN or its dependencies ("products") before
    starting the build. The product name is determined from
    the first part of the patch filename before a dash ("-").

    Currently patches are blindly applied regardless of the
    production version. This is mostly a problem with OpenSSL
    where differences between releases may be large enough to
    cause patching failures. In those cases the offending
    patch can be safely disabled. In particular, OpenSSL
    1.1.0j requires a Makefile patch that will fail on
    OpenSSL 1.1.1. That patch will be removed once upstream
    has fixed the problem.
