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

// Directories are handed to the deferred action as a single property, so they
// are joined with a character which cannot appear in a Windows path.
var DIR_SEPARATOR = "|";

// Directories which must not be writable by unprivileged users. The config
// directories are listed because CONFIG and CONFIGAUTO can point them outside
// of the install directory. Each entry also names the property holding the
// directory the install being upgraded from used, and the version from which
// that directory has been given this ACL.
var V_2_6_9 = (2 << 24) + (6 << 16) + 9 * 100;
var V_2_7_9 = (2 << 24) + (7 << 16) + 9 * 100;

var PROTECTED_DIRS = [
    { dir: "PRODUCTDIR",    prev: "PRODUCTDIRPREV",    since: V_2_6_9 },
    { dir: "CONFIGDIR",     prev: "CONFIGDIRPREV",     since: V_2_7_9 },
    { dir: "CONFIGAUTODIR", prev: "CONFIGAUTODIRPREV", since: V_2_7_9 }
];

function TrimTrailingSlash(dir) {
    // trim trailing slash
    if (dir.charAt(dir.length - 1) === '\\') {
        dir = dir.substring(0, dir.length - 1);
    }

    return dir;
}

// Is path the same as root, or below it? The comparison is done at a path
// component boundary, so that a sibling directory such as
// "C:\Program Files-Foo" is not reported as being below "C:\Program Files".
function IsSameOrBelow(path, root) {
    var fso = new ActiveXObject("Scripting.FileSystemObject");

    path = fso.GetAbsolutePathName(path).toLowerCase();
    root = fso.GetAbsolutePathName(root).toLowerCase();

    return path === root || path.indexOf(root + "\\") === 0;
}

// Do both paths name the same directory?
function IsSamePath(a, b) {
    var fso = new ActiveXObject("Scripting.FileSystemObject");

    return fso.GetAbsolutePathName(a).toLowerCase() ===
           fso.GetAbsolutePathName(b).toLowerCase();
}

function InProgramFiles(installPath) {
    var shell = new ActiveXObject("WScript.Shell");

    // %ProgramFiles% expands differently depending on the bitness of the
    // custom action host, so check every program files directory.
    var vars = ["%ProgramFiles%", "%ProgramFiles(x86)%", "%ProgramW6432%"];

    for (var i = 0; i < vars.length; i++) {
        var dir = shell.ExpandEnvironmentStrings(vars[i]);

        // ExpandEnvironmentStrings() returns the input unchanged when the
        // variable is not set
        if (dir === vars[i]) {
            continue;
        }

        if (IsSameOrBelow(installPath, dir)) {
            return true;
        }
    }

    return false;
}

function DirectoryExists(dir) {
    var fso = new ActiveXObject("Scripting.FileSystemObject");
    return fso.FolderExists(dir);
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

function CanChangeACL(dirs) {
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

    var lines = [];
    lines.push("You are about to install OpenVPN into existing directories. For security reasons, the inherited permissions of the following directories will be removed:");
    lines.push("");
    for (var i = 0; i < dirs.length; i++) {
        lines.push("    " + dirs[i]);
    }
    lines.push("");
    lines.push("and these permissions will be granted:");
    lines.push("");
    lines.push("- Administrators: Full control");
    lines.push("- System: Full control");
    lines.push("- Users: Read and execute");
    lines.push("");
    lines.push("Do you wish to continue?");

    // a Windows path cannot contain a double quote, so the directories are
    // safe to embed into VBScript string literals
    var text = "";
    for (var i = 0; i < lines.length; i++) {
        text += (i > 0 ? " & vbCrLf & " : "") + '"' + lines[i] + '"';
    }

    var file = fso.CreateTextFile(scriptFile);
    var content =
        'text = ' + text + '\n' +
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

// Collect the directories whose ACL has to be tightened. Directories under
// ProgramFiles are left alone.
function GetDirsToProtect() {
    var dirs = [];

    for (var i = 0; i < PROTECTED_DIRS.length; i++) {
        var entry = PROTECTED_DIRS[i];
        var dir = TrimTrailingSlash(Session.Property(entry.dir));

        // GetAbsolutePathName() resolves an empty string to the current
        // directory, which must never end up being handed to icacls
        if (dir === "") {
            continue;
        }

        if (InProgramFiles(dir)) {
            continue;
        }

        // More than one property can name the same directory. Only identical
        // paths are folded together: being below another directory does not
        // mean inheriting its ACL, since anything in between may have
        // inheritance disabled.
        var duplicate = false;
        for (var j = 0; j < dirs.length; j++) {
            if (IsSamePath(dir, dirs[j].path)) {
                duplicate = true;
                break;
            }
        }

        if (!duplicate) {
            dirs.push({
                path: dir,
                prev: TrimTrailingSlash(Session.Property(entry.prev)),
                since: entry.since
            });
        }
    }

    return dirs;
}

function GetInstallDir() {
    var dirs = GetDirsToProtect();
    var prevVersion = GetPreviousVersion(); // returns 0 for fresh install

    var protect = [];
    var consent = [];

    for (var i = 0; i < dirs.length; i++) {
        var dir = dirs[i];

        // Only ask when the install being upgraded from did not already give
        // this very directory the same ACL. Comparing the path matters:
        // CONFIG and CONFIGAUTO can be redirected during an upgrade, so a new
        // version alone does not say that this directory was ever protected.
        // The ACL is set either way, but it is applied with (OI)(CI), so
        // removing the inherited permissions propagates through the subtree.
        var alreadyProtected = prevVersion >= dir.since && dir.prev !== "" &&
                               IsSamePath(dir.path, dir.prev);

        if (DirectoryExists(dir.path) && !alreadyProtected) {
            consent.push(dir.path);
        }

        protect.push(dir.path);
    }

    if (consent.length > 0 && !CanChangeACL(consent)) {
        return 1603;
    }

    Session.Property("SetACL") = protect.join(DIR_SEPARATOR);
    return 0;
}

function RunIcacls(cmd) {
    var shell = new ActiveXObject("WScript.Shell");
    var exitCode = shell.Run('icacls.exe ' + cmd, 0, true);

    if (exitCode != 0) {
        throw new Error("icacls exited with code " + exitCode);
    }
}

function SetACL() {
    var data = Session.Property("CustomActionData");
    if (data == "") {
        // nothing to protect, for example installed in ProgramFiles
        return 0;
    }

    var dirs = data.split(DIR_SEPARATOR);

    for (var i = 0; i < dirs.length; i++) {
        var targetDir = TrimTrailingSlash(dirs[i]);

        // a directory belonging to a feature which has not been installed
        if (targetDir == "" || !DirectoryExists(targetDir)) {
            continue;
        }

        try {
            // Administrators, SYSTEM, Users
            RunIcacls('\"' + targetDir + '\" /inheritance:r /grant "*S-1-5-32-544:(OI)(CI)F" /grant "*S-1-5-18:(OI)(CI)F" /grant "*S-1-5-32-545:(OI)(CI)RX"');
        } catch (e) {
            Session.Property("CUSTOMACTIONERROR") = e.message;
            return 1603; // Indicates a fatal error during installation.
        }
    }

    return 0;
}
