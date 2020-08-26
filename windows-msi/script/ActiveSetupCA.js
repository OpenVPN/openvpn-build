/*
 *  openvpn-build — OpenVPN packaging
 *
 *  Copyright (C) 2018-2020 Simon Rozman <simon@rozman.si>
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


/**
 * Evaluates Active Setup component state and prepares instructions for
 * PublishActiveSetup deferred action.
 */
function EvaluateActiveSetup()
{
    var
        productCode = Session.Property("ProductCode"),
        version;

    // Read the current component version from registry. Default to "0".
    try {
        var wsh = new ActiveXObject("WScript.Shell");
        version = new String(wsh.RegRead("HKLM\\Software\\Microsoft\\Active Setup\\Installed Components\\" + productCode + "\\" + "Version"));
        if (!version || version.length == 0)
            throw new Error("Active Setup component version not found.");
    } catch (err) {
        version = "0";
    }

    if (Session.EvaluateCondition("NOT Installed") == 1/*msiEvaluateConditionTrue*/) {
        // Increment the last version component.
        var v = version.split(",").slice(0, 4);
        v[v.length - 1] = (parseInt(v[v.length - 1], 10) + 1).toString();
        version = v.join(",");
    }

    var runOnLogon = Session.FeatureRequestState("OpenVPN.GUI.OnLogon") == 3;

    // Save the data for deferred action.
    Session.Property("PublishActiveSetup") =
        (Session.EvaluateCondition("REMOVE=\"ALL\"") == 1/*msiEvaluateConditionTrue*/ ?
            ["uninstall", productCode] :
            ["install", productCode, Session.Property("ProductName"), version, runOnLogon, Session.Property("BINDIR")]
        ).join("\t");

    return 1/*msiDoActionStatusSuccess*/;
}


/**
 * Publishes Active Setup component
 * 
 * This is a deffered execution action. CustomActionData property should be
 * one of:
 * 
 * "install\t<product code>\t<product name>\t<Action Setup component version>"
 *    Installs Active Setup component
 * 
 * "uninstall\t<product code>"
 *    Marks Active Setup component as uninstalled
 */
function PublishActiveSetup()
{
    var data = Session.Property("CustomActionData").split("\t");
    if (data && data.length >= 2) {
        var
            wsh = new ActiveXObject("WScript.Shell"),
            regPath = "HKLM\\Software\\Microsoft\\Active Setup\\Installed Components\\" + data[1] + "\\",
            hkcu_run = "HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Run";

        switch (data[0].toLowerCase()) {
            case "install":
                if (data.length >= 6) {
                    var runOnLogon = data[4] == "true";
                    var bindir = data[5];

                    // Register component.
                    wsh.RegWrite(regPath,             data[2], "REG_SZ");
                    wsh.RegWrite(regPath + "Version", data[3], "REG_SZ");

                    // Mark component as installed.
                    wsh.RegWrite(regPath + "IsInstalled", 1, "REG_DWORD");
                    wsh.RegWrite(regPath + "DontAsk"    , 2, "REG_DWORD");

                    // StubPath command will be executed on user logon
                    if (runOnLogon) {
                        wsh.RegWrite(regPath + "StubPath" , "reg add " + hkcu_run + " /f /v OPENVPN-GUI /t REG_SZ /d \"" + bindir + "openvpn-gui.exe\"", "REG_EXPAND_SZ");
                    } else {
                        wsh.RegWrite(regPath + "StubPath" , "reg delete " + hkcu_run + " /v OPENVPN-GUI /f");
                    }
                }
                break;

            case "uninstall":
                // Mark component as uninstalled.
                wsh.RegWrite(regPath + "IsInstalled", 0, "REG_DWORD");

                // StubPath command will be executed on user logon
                wsh.RegWrite(regPath + "StubPath" , "reg delete " + hkcu_run + " /v OPENVPN-GUI /f");
                break;
        }
    }

    return 1/*msiDoActionStatusSuccess*/;
}
