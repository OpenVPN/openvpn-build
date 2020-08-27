openvpn-release-scripts
=======================

These scripts automate a large subset of the OpenVPN 2.x release process:

* **make-openvpn-release.sh**: produces tarballs, changelog and man-pages
* **sign-and-push.sh**: sign release files with GPG and push them to the secondary webserver
* **verify-openvpn-release.sh**: download release files from webservers and verify their GPG signatures

The last script is particularly important when Content Delivery systems (e.g.
CloudFlare) are in the middle and may be serving obsolete files.

Prerequisites
=============

Before you run these scripts:

* Ensure that you can build OpenVPN manually
* Install man2html
* Install gnupg
* Ensure that you have GPG key for signing
* Ensure that you have a clean GPG keyring available for verifying signatures

Configuration
=============

Once prerequisites are set up copy vars.example to vars and add your GPG key ID.

Making a full release
=====================

Typically you need / want to edit build parameters in vars:

    OPENVPN_PREVIOUS_VERSION="${OPENVPN_PREVIOUS_VERSION:-2.4.7}"
    OPENVPN_CURRENT_VERSION="${OPENVPN_CURRENT_VERSION:-2.4.8}"
    OPENVPN_GUI_CURRENT_MIN_VERSION="14"
    INSTALLER_VERSION="I601"

OpenVPN GUI min version refers to the minor version for _this_ release.

Once build parameters are correct do

    $ ./make-openvpn-release.sh

This will produce a directory called "release" with all the release files. Note
that any previous "release" directory will be unconditionally wiped away. You
can avoid that by renaming it and running the subsequent commands against the
copy.

You can override some variables on the command-line. A typical use-case is
changing the OpenVPN versions:

    OPENVPN_PREVIOUS_VERSION=2.3.16 OPENVPN_CURRENT_VERSION=2.3.17 ./make-openvpn-release.sh

Another one is using a custom OpenVPN repository as the source:

    OPENVPN_REPO="<url>/openvpn.git" ./make-openvpn-release.sh

Refer to vars.example for all overrideable parameters.

The script will ask for your GPG key password when signing the release files.
Depending on your GnuPG agent / pinentry configuration it may be a good idea to
have the GPG password on your clipboard.

Once all the release files (tarballs, Windows installers, openvpn-gui tarball)
are present in a directory (e.g. release/sources), you can sign and push all
the files to the download servers like this:

    $ ./sign-and-push.sh release

When you've moved the release files to their correct places on the webservers 
you can automatically download the files and verify their GPG signatures:

    $ ./verify-openvpn-release.sh release

This is particularly useful with CloudFlare which has a habit of caching
obsolete files.

Making a Windows installer release
==================================

These scripts can be used to make (part of a) Windows installer release. Create
a release sources directory (e.g. release-2.4.7-I607/sources) manually, put the
installer files in there and run sign-and-push.sh:

    $ ./sign-and-push.sh release-2.4.7-I607

Once the files are present in S3 verify the release:

    $ ./verify-openvpn-release.sh release-2.4.7-I607

You will need to update and tag openvpn-gui etc. manually for now.

What do these scripts do and don't do?
======================================

make-openvpn-release.sh produces:

* openvpn release tarball
* openvpn changelog for debian packages
* openvpn changelog for Trac
* openvpn man-page for Trac
* openvpn-gui tarball
* increments openvpn-gui version
* adds openvpn-gui git tags

make-openvpn-release.sh does not:

* push any of the produced files anywhere
* push any changes it makes to Git
* GPG sign any of the files
