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

var _serviceName = "OpenVPNService";

function IsServiceExist() {
    var wmi = GetObject("winmgmts://./root/cimv2");
    var svcs = wmi.ExecQuery("Select * from Win32_Service where Name = '" + _serviceName + "'");
    return svcs.Count > 0;
}

/*
 * Checks if config migrations is required and if yes,
 * returns [src, dst] directories.
 *
 * Config migration is required if:
 *  - config_dir exists in registry
 *  - autostart_config_dir doesn't exist in registry
 *  - autostart_config_dir doesn't exists on disk
 *
 * Migration is performed only when service exists and
 * was started before upgrade. Migration is not performed for
 * new installations.
 *
 */
function GetConfigMigrationDirs() {
    var configDirReg = Session.Property("CONFIGDIRREG");
    var configAutoDir = Session.Property("CONFIGAUTODIR");
    var configAutoDirReg = Session.Property("CONFIGAUTODIRREG");

    var fso = new ActiveXObject("Scripting.FileSystemObject");
    if (configDirReg && !configAutoDirReg && !fso.FolderExists(configAutoDir)) {
        return [configDirReg, configAutoDir];
    } else {
        return ["", ""];
    }
}

function CheckOpenVPNServiceStatus() {
    if (!IsServiceExist())
        return;

    var wmi = GetObject("winmgmts://./root/cimv2");
    var srv = wmi.Get("Win32_Service.Name='" + _serviceName + "'");
    var startMode = srv.StartMode.toLowerCase();
    if ((startMode != "auto") && (startMode != "disabled"))
        startMode = "demand";

    Session.Property("ConfigureOpenVPNService") = [startMode, srv.Started].concat(GetConfigMigrationDirs()).join("|");
}

function MigrateConfigs(src, dst) {
    var fso = new ActiveXObject("Scripting.FileSystemObject");

    try {
        fso.MoveFile(src + "\\*.ovpn", dst);
        var ts = fso.CreateTextFile(src + "\\Where are my configs files.txt");
        ts.WriteLine("The OpenVPNService has switched to a separate configuration directory.");
        ts.WriteLine("");
        ts.WriteLine("The update process detected that you were using OpenVPNService");
        ts.WriteLine("to start your connections, and moved all your config");
        ts.WriteLine("files from config to the config-auto directory.");
        ts.Close();
    }
    catch (err) {
        // something wrong, but this is not super critical
    }
}

function ConfigureOpenVPNService() {
    if (!IsServiceExist())
        return;

    var startMode = "";
    var needsStart = false;
    var val = Session.Property("CustomActionData");
    var migrateSrc = "", migrateDst = "";
    if (val == "") {
        // this likely means new install
        startMode = "auto";
        needsStart = true;
    } else {
        arr = val.split("|");
        startMode = arr[0];
        needsStart = arr[1] == "true";

        // migrate configs if this is an upgrade and service was started
        if (needsStart && arr.length >= 4) {
            migrateSrc = arr[2];
            migrateDst = arr[3];
        }
    }

    if (migrateSrc && migrateDst) {
        MigrateConfigs(migrateSrc, migrateDst);
    }

    var wsh = new ActiveXObject("WScript.Shell");
    wsh.Run("sc config " + _serviceName + " start= " + startMode, 0, true);
    if (needsStart) {
        wsh.Run("sc start " + _serviceName, 0, true);
    }
}
