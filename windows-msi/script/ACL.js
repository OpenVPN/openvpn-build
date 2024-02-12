/*
 *  openvpn-build — OpenVPN packaging
 *
 *  Copyright (C) 2024 Lev Stipakov <lev@openvpn.net>
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

function InProgramFiles(installPath) {
    var shell = new ActiveXObject("WScript.Shell");
    var fso = new ActiveXObject("Scripting.FileSystemObject");

    var programFilesPath = shell.ExpandEnvironmentStrings("%ProgramFiles%");

    installPath = fso.GetAbsolutePathName(installPath).toLowerCase();
    programFilesPath = fso.GetAbsolutePathName(programFilesPath).toLowerCase();

    return installPath.indexOf(programFilesPath) === 0;
}

function DirectoryExists(installPath) {
    var fso = new ActiveXObject("Scripting.FileSystemObject");
    return fso.FolderExists(installPath);
}

function ReadFile(filePath) {
    var fso = new ActiveXObject("Scripting.FileSystemObject");

    try {
        var file = fso.OpenTextFile(filePath, 1); // 1 indicates reading mode
        var firstLine = file.ReadLine();
        file.Close();
        return firstLine;
    } catch (e) {
        return "";
    }
}

function DirectoryExists(dir) {
    var fso = new ActiveXObject("Scripting.FileSystemObject");
    return fso.FolderExists(dir);
}

function CanChangeACL(installPath) {
    // are we in silent mode?
    var uiLevel = Session.Property("UILevel");
    if (uiLevel == 2) {
        return true;
    }

    var fso = new ActiveXObject("Scripting.FileSystemObject");

    // generate tmp file path
    var tmpFolder = fso.GetSpecialFolder(2); // 2 is the value for the temp folder
    var scriptFile = fso.BuildPath(tmpFolder.Path, fso.GetTempName() + ".vbs");
    var answerFile = fso.BuildPath(tmpFolder.Path, fso.GetTempName());

    var file = fso.CreateTextFile(scriptFile);
    var content =
        'text = "You are about to install OpenVPN into an existing directory. For security reasons, the directory\'s inherited permissions will be removed and the following permissions will be granted:" & vbCrLf & vbCrLf & _\n' +
        '       "- Administrators: Full control" & vbCrLf & _\n' +
        '       "- System: Full control" & vbCrLf & _\n' +
        '       "- Users: Read and execute" & vbCrLf & vbCrLf & _\n' +
        '       "Do you wish to continue?"\n' +
        'Dim resp: resp = MsgBox(text, vbYesNo Or vbSystemModal Or vbQuestion, "OpenVPN Installer")\n' +
        'Set fso = CreateObject("Scripting.FileSystemObject")\n' +
        'Set outputFile = fso.CreateTextFile("' + answerFile + '", True)\n' +
        'outputFile.WriteLine(resp)\n' +
        'outputFile.Close';
    file.Write(content);
    file.Close();

    var shell = new ActiveXObject("WScript.Shell");
    var exitCode = shell.Run("cscript //nologo " + scriptFile, 0, true);

    var res = (exitCode == 0) && ReadFile(answerFile) == "6"; // vbYes

    fso.DeleteFile(scriptFile);
    fso.DeleteFile(answerFile);

    return res;
}

// returns major << 24 + minor << 16 + build * 100
// for example 2.6.5 (2.6.501) is 33948149
function GetPreviousVersion() {
    var productCode = Session.Property("WIX_UPGRADE_DETECTED");
    if (productCode == "") {
        return 0;
    }

    try {
        // value of that key is set by MSI infrastucture
        var key = "HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\" + productCode;
        return parseInt(new ActiveXObject("WScript.Shell").RegRead(key + "\\" + "Version"));
    } catch (e) {
        return 0;
    }
}

function GetInstallDir() {
    var installPath = Session.Property("PRODUCTDIR");

    // Do not modify ACL under ProgramFiles
    if (InProgramFiles(installPath)) {
        Session.Property("SetACL") = "";
        return 0;
    }

    var isOldVersionUpgrade = GetPreviousVersion() < ((2 << 24) + (6 << 16) + 9 * 100); // returns 0 for fresh install

    // install into new directory, change ACL unconditionaly
    if (!DirectoryExists(installPath)) {
        Session.Property("SetACL") = installPath;
        return 0;
    }

    // install into existing directory

    // upgrade from old version (including clean install)
    if (isOldVersionUpgrade) {
        if (CanChangeACL(installPath)) {
            Session.Property("SetACL") = installPath;
            return 0;
        } else {
            return 1603;
        }
    }

    // upgrade from a new version - no need to change ACL
    Session.Property("SetACL") = "";
    return 0;
}

function RunIcacls(cmd) {
    var shell = new ActiveXObject("WScript.Shell");
    var exitCode = shell.Run('icacls.exe ' + cmd, 0, true);

    if (exitCode != 0) {
        throw new Error("icacls exited with code " + exitCode);
    }
}

function TrimTrailingSlash(dir) {
    // trim trailing slash
    if (dir.charAt(dir.length - 1) === '\\') {
        dir = dir.substring(0, dir.length - 1);
    }

    return dir;
}

function SetACL() {
    var targetDir = Session.Property("CustomActionData");
    if (targetDir == "") {
        // installed in ProgramFiles, not modifying ACL
        return 0;
    }

    targetDir = TrimTrailingSlash(targetDir);

    try {
        RunIcacls('\"' + targetDir + '\" /inheritance:r /grant "Administrators:(OI)(CI)F" /grant "System:(OI)(CI)F" /grant "Users:(OI)(CI)RX"');
    } catch (e) {
        Session.Property("CUSTOMACTIONERROR") = e.message;
        return 1603; // Indicates a fatal error during installation.
    }

    return 0;
}
