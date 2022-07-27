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

function CheckOpenVPNServiceStatus() {
    if (!IsServiceExist())
        return;

    var wmi = GetObject("winmgmts://./root/cimv2");
    var srv = wmi.Get("Win32_Service.Name='" + _serviceName + "'");
    var startMode = srv.StartMode.toLowerCase();
    if ((startMode != "auto") && (startMode != "disabled"))
        startMode = "demand";
    var started = srv.Started;
    Session.Property("ConfigureOpenVPNService") = [startMode, started].join(",");
}

function ConfigureOpenVPNService() {
    if (!IsServiceExist())
        return;

    var startMode = "";
    var started = false;
    var val = Session.Property("CustomActionData");
    if (val == "") {
        // this likely means new install
        startMode = "demand";
    } else {
        arr = val.split(",");
        startMode = arr[0];
        started = arr[1] == "true";
    }
    var wsh = new ActiveXObject("WScript.Shell");
    wsh.Run("sc config " + _serviceName + " start= " + startMode, 0, true);
    if (started) {
        wsh.Run("sc start " + _serviceName, 0, true);
    }
}
