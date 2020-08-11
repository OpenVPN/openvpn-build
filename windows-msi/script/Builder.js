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
/*@cc_on @*/
/*@if (! @__BUILDER_JS__) @*/
/*@set @__BUILDER_JS__ = true @*/


/**
 * Creates a Builder object
 *
 * @returns  Builder object
 */
function Builder()
{
    this.wsh = WScript.CreateObject("WScript.Shell");
    this.fso = WScript.CreateObject("Scripting.FileSystemObject");
    this.env = this.wsh.Environment("Process");

    // Temporary folder.
    this.tempPath = this.env("TEMP");

    // Detect the WiX Toolset path.
    this.wixPath = this.env("WIX");
    if (!this.wixPath || this.wixPath.length == 0) {
        // No WiX, no fun.
        throw new Error("The WIX environment is missing or empty. Please, make sure the WiX Toolset is installed correctly.");
    }

    this.wixCandleFlags = ["-nologo"];
    this.wixLightFlags = ["-nologo", "-dcl:high"];

    // Determine 7-Zip folder. Must be absolute, as we need to change dir for 7-Zip to make the payload correctly.
    this.sevenZipPath = BuildPath(this.fso.GetParentFolderName(this.fso.GetAbsolutePathName(WScript.ScriptFullName)), "lzma1805", "bin");
    this.sevenZipFlags = ["-mx", "-mf=BCJ2"];

    this.unzipFlags = [];
    this.tarFlags = [];
    this.gunzipFlags = ["-d"];
    this.bunzip2Flags = ["-d"];

    // Get the codepage Windows is using for stdin/stdout/stderr.
    switch (parseInt(this.wsh.RegRead("HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Control\\Nls\\CodePage\\OEMCP"), 10)) {
        case  437: this.cpOEMMime = "cp437"       ; break;
        case  850: this.cpOEMMime = "ibm850"      ; break;
        case  852: this.cpOEMMime = "ibm852"      ; break;
        case 1250: this.cpOEMMime = "windows-1250"; break;
        case 1251: this.cpOEMMime = "windows-1251"; break;
        default  : this.cpOEMMime = null;
    }

    this.force = false;
    this.rules = [];
    this.ruleIndex = {};

    return this;
}


/**
 * Adds a rule to the builder
 * 
 * @param {any} rule
 */
Builder.prototype.pushRule = function (rule)
{
    this.rules.push(rule);
    for (var i in rule.outNames) {
        var outFileAbsolute = this.fso.GetAbsolutePathName(rule.outNames[i]).toLowerCase();
        if (outFileAbsolute in this.ruleIndex)
            throw new Error("Rule for building " + rule.outNames[i] + " is already in the ruleset.");

        this.ruleIndex[outFileAbsolute] = rule;
    }
}


/**
 * Builds given file
 * 
 * @param outName  File to build
 */
Builder.prototype.build = function (outName)
{
    var builder = this;
    var stack = [];

    function build(outName)
    {
        var outFileAbsolute = builder.fso.GetAbsolutePathName(outName).toLowerCase();
        stack.push(outFileAbsolute);
        try {
            // Check stack for cycles.
            for (var i = 0, n = stack.length - 1; i < n; i++)
                if (outFileAbsolute == stack[i])
                    throw new Error("Cyclic dependency:\n   " + stack.join("\n    "));

            if (outFileAbsolute in builder.ruleIndex) {
                // We found the rule to build builder file.
                var rule = builder.ruleIndex[outFileAbsolute];

                // Have we already build this rule in this session?
                if (rule.timeBuilt != 0)
                    return builder.fso.GetFile(outName).DateLastModified;

                // Build dependencies.
                var ts = 0;
                for (var i in rule.inNames) {
                    var tsInput = build(rule.inNames[i]);
                    if (ts < tsInput)
                        ts = tsInput;
                }

                // Is building required?
                if (!builder.force) {
                    var tsOutput = rule.buildTime(builder);
                    if (tsOutput != 0 && ts <= tsOutput) {
                        rule.timeBuilt = tsOutput;
                        return builder.fso.GetFile(outName).DateLastModified;
                    }
                }

                // Make sure all output folders exist.
                for (var i in rule.outNames)
                    builder.makeDir(builder.fso.GetParentFolderName(rule.outNames[i]))

                try {
                    // Build!
                    WScript.Echo("BUILD: " + outName);
                    rule.build(builder);
                } catch (err) {
                    // Clean the rule output should anything go wrong in build.
                    // We don't want half finished zombie output files with fresh
                    // timestamp lying around.
                    rule.clean(builder);
                    throw err;
                }

                return builder.fso.GetFile(outName).DateLastModified;
            }

            if (builder.fso.FileExists(outName)) {
                // No rule found to build the file, but the file already exists.
                return builder.fso.GetFile(outName).DateLastModified;
            }

            throw new Error("Don't know how to build \"" + outName + "\".");
        } finally {
            stack.pop();
        }
    }

    build(outName);
}


/**
 * Cleans intermmediate and output files
 */
Builder.prototype.clean = function () {
    for (var i in this.rules)
        this.rules[i].clean(this);
}


/**
 * Creates folder creating all parent folders if required
 * 
 * @param path  Path to folder to create
 * 
 * @returns  true if the folder was created; false if the folder already existed.
 */
Builder.prototype.makeDir = function (path)
{
    var fso = this.fso;

    function makeDir(path)
    {
        if (path == "") return false;
        try {
            // Create folder.
            fso.CreateFolder(path);
            return true;
        } catch (err) {
            switch (err.number) {
                case -2146828230: // "File already exists"
                    return false;
                case -2146828212: // "Path not found"
                    // Create the parent folder.
                    makeDir(fso.GetParentFolderName(path));
                    try {
                        // Create folder.
                        fso.CreateFolder(path);
                        return true;
                    } catch (err) {
                        throw new Error(err.number, "Error creating \"" + path + "\" folder: " + err.message);
                    }
                default:
                    throw new Error(err.number, "Error creating \"" + path + "\" folder: " + err.message);
            }
        }
    }

    return makeDir(this.fso.GetAbsolutePathName(path));
}


/**
 * Deletes folder including all files and subfolders
 * 
 * @param path  Path to folder to delete
 * 
 * @returns  true if the folder was deleted; false if the folder did not exist.
 */
Builder.prototype.removeDir = function (path)
{
    try {
        // Delete folder.
        this.fso.DeleteFolder(path);
        return true;
    } catch (err) {
        switch (err.number) {
            case -2146828212: // "Path not found"
                return false;
            default:
                throw new Error(err.number, "Error deleting \"" + path + "\" folder: " + err.message);
        }
    }
}


/**
 * Copies file
 * 
 * @param inName   Source file name
 * @param outName  Destination file name
 */
Builder.prototype.copyFile = function (inName, outName)
{
    try {
        this.fso.CopyFile(inName, outName);
    } catch (err) {
        throw new Error(err.number, "Error copying \"" + inName + "\" to \"" + outName + "\": " + err.message);
    }
}


/**
 * Deletes a file
 * 
 * @param fileName  Name of the file to delete
 * 
 * @returns  true if the file was deleted; false otherwise.
 */
Builder.prototype.removeFile = function (fileName)
{
    try {
        this.fso.DeleteFile(fileName, true);
        return true;
    } catch (err) {
        switch (err.number) {
            case -2146828235: // "File not found" (pre Windows 10)
            case -2146828212: // "Path not found" (Windows 10)
                return false;
            default:
                throw new Error(err.number, "Error deleting \"" + fileName + "\": " + err.message);
        }
    }
}


/**
 * Executes the command synchronously
 * 
 * @param cmd  Command to execute
 * 
 * @returns  Command exit code
 */
Builder.prototype.exec = function (cmd)
{
    if (!Builder.prototype.__exec) {
        // Initialize static data.
        Builder.prototype.__exec = {
            "re_cr": new RegExp("\\r", "g")
        };
    }

    var result = -1;
    var outputPath = BuildPath(this.tempPath, this.fso.GetTempName());
    try {
        // Execute command and wait for it to finish. Redirect stdout and strerr to a temporary file.
        WScript.Echo("RUN: " + cmd);
        result = this.wsh.Run("\"" + _CMD(this.env("ComSpec")) + "\" /S /C \"" + cmd + " > \"" + _CMD(outputPath) + "\" 2>&1\"", 0, true);

        var dat = WScript.CreateObject("ADODB.Stream");
        var output = "";
        dat.Open();
        try {
            // Load its output.
            dat.Type = adTypeText;
            if (this.cpOEMMime)
                dat.Charset = this.cpOEMMime;
            dat.LoadFromFile(outputPath);
            output = (new String(dat.ReadText(adReadAll))).replace(Builder.prototype.__exec.re_cr, "");
        } finally {
            dat.Close();
        }

        // Replay all output on our console.
        WScript.Echo(output);
    } finally {
        this.removeFile(outputPath);
    }

    return result;
}


/**
 * Creates a generic build rule
 * 
 * @param outNames  Array of output files
 * @param inNames   Array of input files
 * 
 * @returns  Build rule
 */
function BuildRule(outNames, inNames)
{
    this.outNames  = outNames;
    this.inNames   = inNames;
    this.timeBuilt = 0;

    return this;
}


/**
 * Blank build rule
 * 
 * @param builder  The builder object
 */
BuildRule.prototype.build = function (builder)
{
    this.timeBuilt = (new Date()).getVarDate();
}


/**
 * Returns the time the rule was built
 * 
 * @param builder  The builder object
 * 
 * @returns  Oldest timestamp of the output files if all exist; 0 otherwise
 */
BuildRule.prototype.buildTime = function (builder)
{
    var ts = (new Date()).getVarDate();
    for (var i in this.outNames) {
        if (builder.fso.FileExists(this.outNames[i])) {
            var tsOutput = builder.fso.GetFile(this.outNames[i]).DateLastModified;
            if (tsOutput < ts)
                ts = tsOutput;
        } else
            return 0;
    }
    return ts;
}


/**
 * Removes all output files
 * 
 * @param builder  The builder object
 */
BuildRule.prototype.clean = function (builder)
{
    for (var i in this.outNames)
        builder.removeFile(this.outNames[i]);
}


/**
 * Creates a file copy build rule
 * 
 * @param outNames    Output file names
 * @param inName      Input file name
 * @param depNames    Additional dependencies
 *
 * @returns  Build rule
 */
function CopyFileBuildRule(outNames, inName, depNames)
{
    BuildRule.call(this, outNames, [inName].concat(depNames));

    return this;
}


/**
 * Builds the rule
 * 
 * @param builder  The builder object
 */
CopyFileBuildRule.prototype.build = function (builder)
{
    for (var i in this.outNames) {
        WScript.Echo("COPY: " + this.inNames[0] + " >> " + this.outNames[i]);
        builder.copyFile(this.inNames[0], this.outNames[i]);
    }

    BuildRule.prototype.build.call(this, builder);
}


/**
 * Returns the time the rule was built
 * 
 * @param builder  The builder object
 * 
 * @returns  Oldest timestamp of the output files if all exist; 0 otherwise
 */
CopyFileBuildRule.prototype.buildTime = BuildRule.prototype.buildTime;


/**
 * Removes all output files
 * 
 * @param builder  The builder object
 */
CopyFileBuildRule.prototype.clean = BuildRule.prototype.clean;


/**
 * Creates a text conversion build rule
 * 
 * @param outName     Output .txt file name
 * @param outCharset  Charset to use on output (e.g. "utf-8", "windows-1251" etc.)
 * @param outLineSep  Line separator on output (e.g. adCRLF, adLF)
 * @param inNames     Input .txt file names. Files are concatenated together.
 * @param inCharset   Charset to expect on input (e.g. "utf-8", "windows-1251" etc.)
 * @param inLineSep   Line separator on input (e.g. adCRLF, adLF)
 * @param depNames    Additional dependencies
 *
 * @returns  Build rule
 */
function ConvertTextBuildRule(outName, outCharset, outLineSep, inNames, inCharset, inLineSep, depNames)
{
    BuildRule.call(this, [outName], inNames.concat(depNames));

    this.outCharset = outCharset;
    this.outLineSep = outLineSep;
    this.txtNames   = inNames;
    this.inCharset  = inCharset;
    this.inLineSep  = inLineSep;

    return this;
}


/**
 * Builds the rule
 * 
 * @param builder  The builder object
 */
ConvertTextBuildRule.prototype.build = function (builder)
{
    WScript.Echo("CONVERT: " + this.txtNames.join("+") + " >> " + this.outNames[0]);
    var datOut = WScript.CreateObject("ADODB.Stream");
    datOut.Open();
    try {
        datOut.Type = adTypeText;
        datOut.Charset = this.outCharset;
        datOut.LineSeparator = this.outLineSep;

        for (var i in this.txtNames) {
            var datIn = WScript.CreateObject("ADODB.Stream");
            datIn.Open();
            try {
                // Load input file.
                datIn.Type = adTypeText;
                datIn.Charset = this.inCharset;
                datIn.LineSeparator = this.inLineSep;
                datIn.LoadFromFile(this.txtNames[i]);

                while (!datIn.EOS)
                    datOut.WriteText(this.transform(builder, datIn.ReadText(adReadLine)), adWriteLine);
            } finally {
                datIn.Close();
            }
        }

        // Persist stream to file.
        datOut.SaveToFile(this.outNames[0], adSaveCreateOverWrite);
    } finally {
        datOut.Close();
    }

    BuildRule.prototype.build.call(this, builder);
}


/**
 * Returns the time the rule was built
 * 
 * @param builder  The builder object
 * 
 * @returns  Oldest timestamp of the output files if all exist; 0 otherwise
 */
ConvertTextBuildRule.prototype.buildTime = BuildRule.prototype.buildTime;


/**
 * Removes all output files
 * 
 * @param builder  The builder object
 */
ConvertTextBuildRule.prototype.clean = BuildRule.prototype.clean;


/**
 * Transforms one line of text
 * 
 * @param builder  The builder object
 * @param str      Line of text to transform
 * 
 * @returns  Transformed text
 */
ConvertTextBuildRule.prototype.transform = function (builder, str)
{
    return str;
}


/**
 * Creates a text preprocessing build rule
 * 
 * @param outName     Output .txt file name
 * @param outCharset  Charset to use on output (e.g. "utf-8", "windows-1251" etc.)
 * @param outLineSep  Line separator on output (e.g. adCRLF, adLF)
 * @param inNames     Input .txt.in file names. Files are concatenated together.
 * @param inCharset   Charset to expect on input (e.g. "utf-8", "windows-1251" etc.)
 * @param inLineSep   Line separator on input (e.g. adCRLF, adLF)
 * @param ver         M4 parser
 * @param depNames    Additional dependencies
 *
 * @returns  Build rule
 */
function PreprocessBuildRule(outName, outCharset, outLineSep, inNames, inCharset, inLineSep, ver, depNames)
{
    ConvertTextBuildRule.call(this, outName, outCharset, outLineSep, inNames, inCharset, inLineSep, depNames);

    this.ver = ver;

    return this;
}


/**
 * Builds the rule
 * 
 * @param builder  The builder object
 */
PreprocessBuildRule.prototype.build = ConvertTextBuildRule.prototype.build;


/**
 * Returns the time the rule was built
 * 
 * @param builder  The builder object
 * 
 * @returns  Oldest timestamp of the output files if all exist; 0 otherwise
 */
PreprocessBuildRule.prototype.buildTime = BuildRule.prototype.buildTime;


/**
 * Removes all output files
 * 
 * @param builder  The builder object
 */
PreprocessBuildRule.prototype.clean = BuildRule.prototype.clean;


/**
 * Transforms one line of text
 * 
 * @param builder  The builder object
 * @param str      Line of text to transform
 * 
 * @returns  Transformed text
 */
PreprocessBuildRule.prototype.transform = function (builder, str)
{
    if (!PreprocessBuildRule.prototype.__transform) {
        // Initialize static data.
        PreprocessBuildRule.prototype.__transform = {
            "re_param": new RegExp("@(\\w+)@", "g")
        };
    }

    var dict = this.ver.define;

    str = str.replace(PreprocessBuildRule.prototype.__transform.re_param, function ($0, $1) {
        return $1 in dict ? dict[$1] : "@" + $1 + "@";
    });

    return str;
}


/**
 * Creates a WiX compiler build rule
 * 
 * @param outName   Output .wixobj file name
 * @param inName    Input .wxs file name
 * @param depNames  Additional dependencies
 * @param flags     Additional WiX Candle flags
 *
 * @returns  Build rule
 */
function WiXCompileBuildRule(outName, inName, depNames, flags)
{
    BuildRule.call(this, [outName], [inName].concat(depNames));

    this.flags = flags;

    return this;
}


/**
 * Builds the rule
 * 
 * @param builder  The builder object
 */
WiXCompileBuildRule.prototype.build = function (builder)
{
    // Compile .wxs file.
    if (builder.exec(
        "\"" + _CMD(BuildPath(builder.wixPath, "bin", "candle.exe")) + "\" " +
        builder.wixCandleFlags.join(" ") + (this.flags && this.flags.length ? " " + this.flags.join(" ") : "") +
        " -out \"" + _CMD(this.outNames[0]) + "\" \"" + _CMD(this.inNames[0]) + "\"") != 0)
        throw new Error("WiX compiler returned non-zero.");

    BuildRule.prototype.build.call(this, builder);
}


/**
 * Returns the time the rule was built
 * 
 * @param builder  The builder object
 * 
 * @returns  Oldest timestamp of the output files if all exist; 0 otherwise
 */
WiXCompileBuildRule.prototype.buildTime = BuildRule.prototype.buildTime;


/**
 * Removes all output files
 * 
 * @param builder  The builder object
 */
WiXCompileBuildRule.prototype.clean = BuildRule.prototype.clean;


/**
 * Creates a WiX linker build rule
 * 
 * @param outName   Output .msi file name
 * @param inNames   Input .wixobj file names
 * @param depNames  Additional dependencies
 * @param flags     Additional WiX Light flags
 *
 * @returns  Build rule
 */
function WiXLinkBuildRule(outName, inNames, depNames, flags)
{
    BuildRule.call(this, [outName], inNames.concat(depNames));

    this.flags = flags;
    this.objNames = inNames;

    return this;
}


/**
 * Builds the rule
 * 
 * @param builder  The builder object
 */
WiXLinkBuildRule.prototype.build = function (builder)
{
    // Link .wixobj files.
    if (builder.exec(
        "\"" + _CMD(BuildPath(builder.wixPath, "bin", "light.exe")) + "\" " +
        builder.wixLightFlags.join(" ") + (this.flags && this.flags.length ? " " + this.flags.join(" ") : "") +
        " -out \"" + this.outNames[0] + "\" \"" + this.objNames.join("\" \"") + "\"") != 0)
        throw new Error("WiX linker returned non-zero.");

    BuildRule.prototype.build.call(this, builder);
}


/**
 * Returns the time the rule was built
 * 
 * @param builder  The builder object
 * 
 * @returns  Oldest timestamp of the output files if all exist; 0 otherwise
 */
WiXLinkBuildRule.prototype.buildTime = BuildRule.prototype.buildTime;


/**
 * Removes all output files
 * 
 * @param builder  The builder object
 */
WiXLinkBuildRule.prototype.clean = BuildRule.prototype.clean;


/**
 * Creates a 7-Zip SFX build rule
 * 
 * @param outName   Output .exe file name
 * @param sfx       7-Zip SFX module
 * @param cfg       7-Zip SFX installer config
 * @param inNames   Input file names
 * @param depNames  Additional dependencies
 *
 * @returns  Build rule
 */
function SevenZipSFXBuildRule(outName, sfx, cfg, inNames, depNames)
{
    BuildRule.call(this, [outName], inNames.concat([sfx]).concat(depNames));

    this.sfx = sfx;
    this.cfg = cfg;
    this.payloadNames = inNames;

    return this;
}


/**
 * Builds the rule
 * 
 * @param builder  The builder object
 */
SevenZipSFXBuildRule.prototype.build = function (builder)
{
    // Prepare installer config file.
    var cfgPath = BuildPath(builder.tempPath, builder.fso.GetTempName());
    try {
        var datOut = WScript.CreateObject("ADODB.Stream");
        datOut.Open();
        try {
            datOut.Type = adTypeText;
            datOut.Charset = "utf-8";
            datOut.LineSeparator = adCRLF;

            // Write installer config.
            datOut.WriteText(this.cfg);

            // Persist stream to file.
            datOut.SaveToFile(cfgPath, adSaveCreateOverWrite);
        } finally {
            datOut.Close();
        }

        // 7-Zip has no flag to pack all files in a flat arhive without laying them out into subfolder(s).
        var payloadTempPath = BuildPath(builder.tempPath, builder.fso.GetTempName());
        try {
            // Copy payload files to a temporary folder first. 
            builder.makeDir(payloadTempPath);
            for (var i in this.payloadNames)
                builder.copyFile(this.payloadNames[i], payloadTempPath + "\\");

            // 7-Zip is sensitive to file extension. Carefully select a temporary .7z file name.
            var payloadPath = BuildPath(builder.tempPath, builder.fso.GetBaseName(builder.fso.GetTempName()) + ".7z");
            try {
                // As much as I personally hate this: we need to change folder.
                var dirPrev = builder.wsh.CurrentDirectory;
                try {
                    // Compress the payload.
                    builder.wsh.CurrentDirectory = payloadTempPath;
                    if (builder.exec(
                        "\"" + _CMD(BuildPath(builder.sevenZipPath, "7zr.exe")) + "\" a " +
                        builder.sevenZipFlags.join(" ") +
                        " \"" + _CMD(payloadPath) + "\" *") != 0)
                        throw new Error("7-Zip returned non-zero.");
                } finally {
                    builder.wsh.CurrentDirectory = dirPrev;
                }

                // Compile installer by concatenating: 7-Zip SFX module, installer config, and payload.
                var datOut = WScript.CreateObject("ADODB.Stream");
                datOut.Open();
                try {
                    datOut.Type = adTypeBinary;

                    // Copy 7-Zip SFX module.
                    var datIn = WScript.CreateObject("ADODB.Stream");
                    datIn.Open();
                    try {
                        datIn.Type = adTypeBinary;
                        datIn.LoadFromFile(this.sfx);
                        datIn.CopyTo(datOut);
                    } finally {
                        datIn.Close();
                    }

                    // Copy installer config.
                    var datIn = WScript.CreateObject("ADODB.Stream");
                    datIn.Open();
                    try {
                        datIn.Type = adTypeBinary;
                        datIn.LoadFromFile(cfgPath);
                        datIn.Position = 3; // Skip UTF-8 BOM.
                        datIn.CopyTo(datOut);
                    } finally {
                        datIn.Close();
                    }

                    // Copy payload.
                    var datIn = WScript.CreateObject("ADODB.Stream");
                    datIn.Open();
                    try {
                        datIn.Type = adTypeBinary;
                        datIn.LoadFromFile(payloadPath);
                        datIn.CopyTo(datOut);
                    } finally {
                        datIn.Close();
                    }

                    // Persist stream to file.
                    datOut.SaveToFile(this.outNames[0], adSaveCreateOverWrite);
                } finally {
                    datOut.Close();
                }
            } finally {
                builder.removeFile(payloadPath);
            }
        } finally {
            builder.removeDir(payloadTempPath);
        }
    } finally {
        builder.removeFile(cfgPath);
    }

    BuildRule.prototype.build.call(this, builder);
}


/**
 * Returns the time the rule was built
 * 
 * @param builder  The builder object
 * 
 * @returns  Oldest timestamp of the output files if all exist; 0 otherwise
 */
SevenZipSFXBuildRule.prototype.buildTime = BuildRule.prototype.buildTime;


/**
 * Removes all output files
 * 
 * @param builder  The builder object
 */
SevenZipSFXBuildRule.prototype.clean = BuildRule.prototype.clean;


/**
 * Creates a download build rule
 * 
 * @param outName   Output file name
 * @param url       URL to retrieve data from
 * @param depNames  Additional dependencies
 *
 * @returns  Build rule
 */
function DownloadBuildRule(outName, url, depNames)
{
    BuildRule.call(this, [outName], depNames);

    this.url = url;

    return this;
}


/**
 * Builds the rule
 * 
 * @param builder  The builder object
 */
DownloadBuildRule.prototype.build = function (builder)
{
    WScript.Echo("GET: " + this.url + " >> " + this.outNames[0]);
    var req = new ActiveXObject("WinHttp.WinHttpRequest.5.1");
    req.Open("GET", this.url, false);
    req.Send();
    if (req.Status == "200") {
        var datOut = new ActiveXObject("ADODB.Stream");
        datOut.Open();
        try {
            datOut.Type = adTypeBinary;
            datOut.Write(req.ResponseBody);
            datOut.SaveToFile(this.outNames[0], adSaveCreateOverWrite);
        } finally {
            datOut.Close();
        }
    } else
        throw new Error("GET " + this.url + " failed with status " + req.Status + " " + req.StatusText + ".");

    BuildRule.prototype.build.call(this, builder);
}


/**
 * Returns the time the rule was built
 * 
 * @param builder  The builder object
 * 
 * @returns  Oldest timestamp of the output files if all exist; 0 otherwise
 */
DownloadBuildRule.prototype.buildTime = BuildRule.prototype.buildTime;


/**
 * Removes all output files
 * 
 * @param builder  The builder object
 */
DownloadBuildRule.prototype.clean = BuildRule.prototype.clean;


/**
 * Creates a generic archive extraction build rule
 * 
 * @param outNames  Array of output files. You may list only the important ones, however, the cleaning will take care of only those then.
 * @param outDir    Output directory
 * @param tsName    Timestamp file name. Serves as a dummy output file to mark the extraction date. This is the actual output file used to detect if the rule needs rebuilding.
 * @param inName    Input archive file name
 * @param depNames  Additional dependencies
 *
 * @returns  Build rule
 */
function ExtractBuildRule(outNames, outDir, tsName, inName, depNames)
{
    BuildRule.call(this, [tsName].concat(outNames), [inName].concat(depNames));

    this.outDir = outDir;

    return this;
}


/**
 * Builds the rule
 * 
 * @param builder  The builder object
 */
ExtractBuildRule.prototype.build = function (builder)
{
    if (this.inNames[0].slice(-4).toLowerCase() == ".zip") {
        // Unzip file.
        if (builder.exec(
            "unzip.exe " +
            builder.unzipFlags.join(" ") +
            " -o" +
            " -d \"" + _CMD(this.outDir) + "\"" + 
            " \"" + _CMD(this.inNames[0]) + "\"") != 0)
            throw new Error("Unzip returned non-zero.");
    } else if (this.inNames[0].slice(-7).toLowerCase() == ".tar.gz" || this.inNames[0].slice(-4).toLowerCase() == ".tgz") {
        // Gunzip then untar file.
        if (builder.exec(
            "gzip.exe " +
            builder.gunzipFlags.join(" ") +
            " -c" + 
            " \"" + _CMD(this.inNames[0]) + "\"" +
            " | tar.exe " +
            builder.tarFlags.join(" ") +
            " -xf - -C \"" + _CMD(this.outDir) + "\"") != 0)
            throw new Error("gunzip|tar returned non-zero.");
    } else if (this.inNames[0].slice(-8).toLowerCase() == ".tar.bz2" || this.inNames[0].slice(-5).toLowerCase()() == ".tbz2") {
        // Bunzip2 then untar file.
        if (builder.exec(
            "bzip2.exe " +
            builder.bunzip2Flags.join(" ") +
            " -c" + 
            " \"" + _CMD(this.inNames[0]) + "\"" +
            " | tar.exe " +
            builder.tarFlags.join(" ") +
            " -xf - -C \"" + _CMD(this.outDir) + "\"") != 0)
            throw new Error("bunzip2|tar returned non-zero.");
    }

    // Create the timestamp file.
    var datOut = WScript.CreateObject("ADODB.Stream");
    datOut.Open();
    try {
        datOut.Type = adTypeText;
        datOut.Charset = "utf-8";
        datOut.LineSeparator = adCRLF;
        datOut.WriteText(this.inNames[0] + " extracted at " + (new Date()).toLocaleString(), adWriteLine);
        datOut.SaveToFile(this.outNames[0], adSaveCreateOverWrite);
    } finally {
        datOut.Close();
    }

    BuildRule.prototype.build.call(this, builder);
}


/**
 * Returns the time the rule was built
 * 
 * @param builder  The builder object
 * 
 * @returns  Oldest timestamp of the output files if all exist; 0 otherwise
 */
ExtractBuildRule.prototype.buildTime = function (builder)
{
    // Timestamp and all the output files must exist.
    // However, it is the timestamp file that always provides the output time.
    for (var i in this.outNames)
        if (!builder.fso.FileExists(this.outNames[i])) return 0;
    return builder.fso.GetFile(this.outNames[0]).DateLastModified;
}


/**
 * Removes all output files
 * 
 * @param builder  The builder object
 */
ExtractBuildRule.prototype.clean = BuildRule.prototype.clean;


/*@end @*/
