/*
 *  openvpn-build — OpenVPN packaging
 *
 *  Copyright (C) 2022 Lev Stipakov <lev@openvpn.net>
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License version 2
 *  as published by the Free Software Foundation.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License along
 *  with this program; if not, write to the Free Software Foundation, Inc.,
 *  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 */

function GetInstallDir() {
    var installPath = Session.Property("PRODUCTDIR");
    installPath = installPath.replace(new RegExp(/\\/g), "\\\\");
    Session.Property("UpdatePlapReg") = installPath;
}

function UpdatePlapReg() {
    var installPath = Session.Property("CustomActionData");
    if (installPath == "") // uninstall
        return;

    var binPath = installPath + "bin\\\\";
    var oldFile = binPath + "openvpn-plap-install.reg";
    var newFile = binPath + "openvpn-plap-install-new.reg";
    var plapDll = binPath + "libopenvpn_plap.dll";

    var fso = new ActiveXObject("Scripting.FileSystemObject");

    try {
        // regex to match @="C:\\Program Files\\OpenVPN\\bin\\libopenvpn_plap.dll"
        var r = new RegExp("^@=\"\\w:")

        var fso = new ActiveXObject("Scripting.FileSystemObject");
        if (!fso.FileExists(oldFile))
            return; // feature not installed

        var os = fso.OpenTextFile(oldFile);
        var ns = fso.CreateTextFile(newFile);

        while (!os.AtEndOfStream) {
            var line = new String(os.ReadLine());
            if (line.match(r)) {
                line = "@=\"" + plapDll + "\"";
            }
            ns.WriteLine(line);
        }

        os.Close();
        ns.Close();

        fso.DeleteFile(oldFile);
        fso.MoveFile(newFile, oldFile);
    }
    catch (err) {
        // something wrong, but this is not super critical
    }
    finally {
        // cleanup
        if (fso.FileExists(newFile)) {
            fso.DeleteFile(newFile);
        }
    }
}
