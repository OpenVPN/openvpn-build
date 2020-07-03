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
/*@if (! @__M4PARSER_JS__) @*/
/*@set @__M4PARSER_JS__ = true @*/


/**
 * Creates a parser object
 *
 * @returns M4 parser object
 */
function M4Parser()
{
    // Initialization
    this.define = new Array();

    return this;
}


/**
 * Parses a M4 file
 *
 * @param fileName  M4 file name to parse
 */
M4Parser.prototype.parse = function (fileName)
{
    if (!M4Parser.prototype.__parse) {
        // Initialize static data.
        M4Parser.prototype.__parse = {
            "re_define": new RegExp("^\\s*define\\s*\\(\\s*\\[?(\\w+)\\]?\\s*,\\s*\\[([^\\]]*)\\]\\s*\\)\\s*$")
        };
    }

    // Open M4 file.
    var dat = WScript.CreateObject("Scripting.FileSystemObject").OpenTextFile(fileName, ForReading);
    try {
        // (Re)initialize
        this.define = new Array();

        // Read M4 file line by line and parse it.
        while (!dat.AtEndOfStream) {
            var line = new String(dat.ReadLine());
            var m = line.match(M4Parser.prototype.__parse.re_define);
            if (m)
                this.define[m[1]] = m[2];
        }
    } finally {
        dat.Close();
    }
}

/*@end @*/
