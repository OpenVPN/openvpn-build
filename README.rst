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
    operatingsystem.

    Thorough documentation is available in the OpenVPN wiki:

    <https://community.openvpn.net/openvpn>

Directories
**************************************************

    The "generic" subdir contains scripts to cross-compile
    OpenVPN using mingw_w64 (e.g. Linux -> Windows).

    The "msvc" subdir is used to compile OpenVPN on Windows
    for Windows using Microsoft Visual Studio 2017.

    The "windows-nsis" subdir contains scripts to
    cross-compile and package OpenVPN for Windows.

    Please refer to the README files in the subdirectories
    for further information.
