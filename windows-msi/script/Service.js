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

function IsServiceFeatureSelected() {
    var msiInstallStateUnknown = -1;
    var msiInstallStateLocal = 3;
    var feature = "OpenVPN.Service";

    var requested = Session.FeatureRequestState(feature);
    if (requested == msiInstallStateUnknown)
        return Session.FeatureCurrentState(feature) == msiInstallStateLocal;
    return requested == msiInstallStateLocal;
}

// runs early, as removing an old version during an upgrade may delete the service
// result: selected|startMode|started|migrateSrc|migrateDst
function CheckOpenVPNServiceStatus() {
    var startMode = "";
    var started = false;
    var migrateDirs = ["", ""];

    if (IsServiceExist()) {
        var wmi = GetObject("winmgmts://./root/cimv2");
        var srv = wmi.Get("Win32_Service.Name='" + _serviceName + "'");
        startMode = srv.StartMode.toLowerCase();
        if ((startMode != "auto") && (startMode != "disabled"))
            startMode = "demand";
        started = srv.Started;
        migrateDirs = GetConfigMigrationDirs();

        // without the feature the service is registered disabled, nothing to keep
        if (startMode == "disabled" && !Session.Property("CONFIGAUTODIRREG"))
            startMode = "";
    }

    var selected = IsServiceFeatureSelected() ? "1" : "0";
    Session.Property("ConfigureOpenVPNService") = [selected, startMode, started].concat(migrateDirs).join("|");
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

// removing an openvpnserv2.exe based version deletes the service, install it again
function RecreateOpenVPNService() {
    var exe = Session.Property("CustomActionData");
    var wsh = new ActiveXObject("WScript.Shell");
    var rc = wsh.Run("\"" + exe + "\" -install automatic", 0, true);
    if (rc != 0) {
        Log("Installing " + _serviceName + " failed, openvpnserv.exe exit code " + rc);
    }
}

function Log(msg) {
    var rec = Session.Installer.CreateRecord(0);
    rec.StringData(0) = msg;
    Session.Message(0x04000000 /* msiMessageTypeInfo */, rec);
}

function ConfigureOpenVPNService() {
    if (!IsServiceExist()) {
        Log(_serviceName + " does not exist, cannot configure it");
        return;
    }

    var arr = Session.Property("CustomActionData").split("|");
    var selected = arr[0] == "1";
    var startMode = arr[1] || "";
    var needsStart = arr[2] == "true";
    var migrateSrc = arr[3] || "";
    var migrateDst = arr[4] || "";

    if (!selected) {
        // the service is always registered, but must not run without the feature
        startMode = "disabled";
        needsStart = false;
    } else if (startMode == "") {
        // nothing to restore: new install, or the feature was just selected
        startMode = "auto";
        needsStart = true;
    } else if (needsStart && migrateSrc && migrateDst) {
        // migrate configs if this is an upgrade and service was started
        MigrateConfigs(migrateSrc, migrateDst);
    }

    var wsh = new ActiveXObject("WScript.Shell");
    wsh.Run("sc config " + _serviceName + " start= " + startMode, 0, true);
    if (needsStart) {
        wsh.Run("sc start " + _serviceName, 0, true);
    }
}
