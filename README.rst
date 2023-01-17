OpenVPN project buildsystems
#####################################################
.. image:: https://github.com/OpenVPN/openvpn-build/actions/workflows/build.yaml/badge.svg
  :target: https://github.com/OpenVPN/openvpn-build/actions
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

    The "release" subdir contains scripts to prepare
    the source tarballs and tag the git repositories.
    It also has scripts to orchestrate the other parts
    of the build.

    The "debian-sbuild" subdir contains scripts to build
    Debian packages for all supported distributions.

    The following two sub directories were used in the
    past but are currently unmaintained:

    The "generic" subdir contains scripts to cross-compile
    OpenVPN using mingw_w64 (e.g. Linux -> Windows).

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
