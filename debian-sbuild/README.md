sbuild_wrapper
==============

A set of scripts for easily building a set of Debian/Ubuntu packages. Currently
the scripts are highly OpenVPN-specific, and therefore patches that improve and
make these scripts more general purpose are _most_ welcome!

Note that all scripts should be run from the sbuild_wrapper base directory, e.g.

    $ scripts/update-all.sh

Before you start using sbuild_wrapper you should familiarize yourself with the 
basics of Debian packaging, sbuild and schroot:

* https://wiki.debian.org/Packaging
* https://wiki.debian.org/sbuild
* https://wiki.debian.org/Schroot

If you're not familiar with these tools and technologies you will run into 
trouble.

Installation
============

Use a recent Debian or Ubuntu version as the build rig, or you will run into 
various troubles during the _prepare-all.sh_ phase. For example, building Debian 
8 packages on Debian 7 will require the use of a backported iproute2 package, 
which conflicts with ifupdown package, which causes the network configuration on 
the build computer to break, unless it is a desktop computer using 
NetworkManager.

Check out sbuild_wrapper code from GitHub:

    $ git clone https://github.com/OpenVPN/sbuild_wrapper.git

Configuration
=============

Configuration of sbuild_wrapper involves running a some scripts and (possibly) 
editing some configuration files.

Create proper directory structure
---------------------------------

First run "scripts/setup.sh" which generates a few directories required by the 
scripts.

Edit config/variants.conf
-------------------------

This file determines which platforms to build packages for. It's syntax is 
simple:

    <osfamily> <lsbdistcodename> <architecture>

For example:

    debian wheezy i386
    ubuntu precise amd64

As described below, you need to have a corresponding debootstrap file for every 
operating system variant you define in variants.conf.

Edit config/base.conf
---------------------

This file determines which directories the scripts use. Typically you should not 
need to modify this file.

Edit config/version.conf
------------------------

This file determines the release and build numbers. It should be updated 
whenever a new release or build is made. Alternatively the version information
can be defined on the command-line (see below).

Adding new sbuild schroots
==========================

Ensure that debootstrap scripts are in place
--------------------------------------------

Before you can build anything you need to setup chroots using sbuild. First of 
all, you will need a debootstrap script for the operating system you're creating 
the chroot for. You can easily check if your target platforms are already 
supported by your operating system's debootstrap scripts:

    $ ls /usr/share/debootstrap/scripts

If you don't find the target OS from the above directory you need to get the 
appropriate bootstrap file from Debian unstable. First find out what the latest 
version of debootstrap in Debian is:

* <https://packages.debian.org/sid/debootstrap>

Next download latest debootstrap source tarball:

    $ wget http://ftp.de.debian.org/debian/pool/main/d/debootstrap/debootstrap_<version>.tar.gz
    $ tar -zxf debootstrap_<version>.tar.gz

If you were adding Ubuntu 14.04 ("Trust Tahr"), you'd do a check like this:

    $ ls -l debootstrap-<version>/scripts/trusty
    lrwxrwxrwx 1 root root 5 oct  21 18:06 debootstrap-<version>/scripts/trusty -> gutsy

As can be seen, "trusty" is just a symbolic link to "gutsy", so it's enough to 
add a new symbolic link:

    $ cd /usr/share/debootstrap/scripts/
    $ ln -s gutsy trusty

If the file for your target platform is _not_ a symbolic link, copy the 
debootstrap script to /usr/share/debootstrap/scripts/ on the build computer.

Setting up the schroots
-----------------------

Once debootstrap is configured properly you can create the schroot. Go to the 
sbuild_wrapper directory, add a new variant to "config/variants.conf" (see below 
for syntax) and then setup the new schroot(s):

    $ scripts/setup_chroots.sh

This command will generate schroots for all the operating system variants 
defined in "config/variants.conf". If an schroot already exists the script 
notices that and does not try to (re)create it.

You can verify that the schroots got created with this command:

    $ schroot -l|grep sbuild|grep source

This should display a bunch of schroots, for example something like this:

    --- snip ---
    source:trusty-amd64-sbuild
    source:trusty-i386-sbuild
    source:wheezy-amd64-sbuild
    source:wheezy-i386-sbuild

Installing build dependencies to the schroots
---------------------------------------------

Finally you need ensure that OpenVPN can be built inside the schroot. This can 
be done with

    $ scripts/install-build-deps.sh

Building
========

Before building update all the packages in the schroots:

    $ cd <sbuild_wrapper_dir>
    $ scripts/update-all.sh

While the schroots are updating you can update the Debian changelog file:

\<sbuild_wrapper_dir\>/packaging/changelog-\<openvpn_version\>

Make sure that the version header matches PROGRAM_VERSION and PACKAGE_VERSION
variables set in version.conf. For example in

    openvpn (2.4_alpha2-debian0) stable; urgency=medium

the word "debian" will be replaced with "jessie", "xenial" or such, depending on 
the values in variants.conf. If a matching changelog entry is not found, the
_prepare_all.sh_ script will exit with an error.

You can generate Debian-compatible change entries using this Git magic:

    $ git log --pretty=short --abbrev-commit --format="  * %s (%an, %h)" <old>...<new>

If you need to add patches, then do so at this point.

Next update the PROGRAM_VERSION and PACKAGE_VERSION variables in 
\<sbuild_wrapper_dir\>/config/version.conf. After this you can update
the sources which sbuild will use:

    $ cd <sbuild_wrapper_basedir>
    $ scripts/prepare-all.sh

Finally you can build on all platforms:

    $ cd <sbuild_wrapper_basedir>
    $ scripts/build-all.sh

Alternatively you can define version information on the command-line, if you 
need to build several OpenVPN versions using the same sbuild_wrapper:

    $ cd <sbuild_wrapper_basedir>
    $ PROGRAM_VERSION=2.3.12 PACKAGE_VERSION=0 scripts/prepare-all.sh
    $ PROGRAM_VERSION=2.3.12 PACKAGE_VERSION=0 scripts/build-all.sh
    $ PROGRAM_VERSION=2.4_alpha2 PACKAGE_VERSION=0 scripts/prepare-all.sh
    $ PROGRAM_VERSION=2.4_alpha2 PACKAGE_VERSION=0 scripts/build-all.sh

The above commands would build both 2.3.12 and 2.4_alpha2.

You can also customize the patch series file to use in prepare-all.sh:

    $ PROGRAM_VERSION=2.3.14 PACKAGE_VERSION=0 PATCH_SERIES=series-2.3 scripts/prepare-all.sh
    $ PROGRAM_VERSION=2.3.14 PACKAGE_VERSION=0 scripts/build-all.sh 

This can be useful when the same patch will not work on different OpenVPN 
versions. The series file is looked for from 
_packaging/\<lsbdistcodename\>/debian/patches/_.

The produced .deb files can be found from the "output" directory. They are also
packaged into "output.tar.gz" file at \<sbuild_wrapper_basedir\>.

Applying patches
================

Patches are applied manually with quilt. First copy the patch in 
openvpn-\<version\>/debian/patches. Then create or modify the series file 
(openvpn-\<version\>/debian/patches/series) to include the new patch. Finally 
apply the patch:

    $ cd openvpn-<version>
    $ QUILT_PATCHES=debian/patches quilt series
    $ QUILT_PATCHES=debian/patches quilt next
    $ QUILT_PATCHES=debian/patches quilt push

There are more details [here](http://raphaelhertzog.com/2012/08/08/how-to-use-quilt-to-manage-patches-in-debian-packages).

Publishing the packages
=======================

I prefer to use [freight](https://github.com/freight-team/freight) for apt 
repository management: Copy the output.tar.gz to the apt repository host and run 
"scripts/freight-add-many.py" there. If freight is properly configured that's all 
you need to do.
