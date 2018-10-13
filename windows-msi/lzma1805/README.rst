7-Zip LZMA SDK Port for OpenVPN
===============================

This is a ripped version of 7-ZIP `LZMA SDK 18.05 (2018-04-30)`_. Files kept
are used to compress MSI packages into a single self-extractible Win32 EXE
file.


File List
---------

``bin\7zr.exe``
   A reduced version of 7za.exe of 7-Zip (i386)

``bin\7zSD.sfx``
   The original 7-Zip SFX module

``bin\7zSD-openvpn.sfx``
   Copy of the ``bin\7zSD.sfx`` with altered resources:
   - The icon has been replaced
   - Version info block has been replaced
   - A manifest resource has been added to turn off the elevation prompt. User
     is prompted for elevation later in the MSI install phase, should user
     proceed so far at all.
   
   For resource modification, the `Resource Hacker`_ utility has been used
   (v3.6.0.92).

``bin\7zSD-openvpn.manifest``
   Manifest file that has been added to ``bin\7zSD-openvpn.sfx``.

``bin\7zSD-openvpn.rc``
   Version info resource source.

``bin\7zSD-openvpn.res``
   Binary version info resource compiled with ``rc.exe 7zSD-openvpn.rc``. This
   resource is the ``bin\7zSD-openvpn.sfx``'s version info resource
   replacement.

``DOC\installer.txt``
   Licence info and instructions

.. _`LZMA SDK 18.05 (2018-04-30)`: https://www.7-zip.org/a/lzma1805.7z
.. _`Resource Hacker`: http://www.angusj.com/resourcehacker/