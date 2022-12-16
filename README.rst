OpenVPN project buildsystems
#####################################################
.. image:: https://github.com/OpenVPN/openvpn-build/actions/workflows/build.yaml/badge.svg
  :target: https://https://github.com/OpenVPN/openvpn-build/actions
  :alt: GitHub Actions status

About
**************************************************

    These directories contain scripts to help build and
    package OpenVPN and its dependencies for various
    hardware platforms and operating systems. You do not
    need any of these scripts if you're building a native
    version of OpenVPN on a UNIX-like or Windows operating
    system.

    Thorough documentation is available in the OpenVPN wiki:

    <https://community.openvpn.net/openvpn>

Directories
**************************************************

    The "windows-msi" subdir contains scripts to
    build and package OpenVPN on Windows for Windows.

    Previously there were "windows-nsis" and "generic"
    subdirectories available that implemented an
    alternative build system for Windows installers
    based on mingw cross-compilation. Those build
    scripts were removed since they were not maintained
    anymore. You can find the last version before removal
    in branch release/2.6.

    Please refer to the README files in the subdirectories
    for further information.
