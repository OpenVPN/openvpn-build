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
/*@if (! @__STRING_JS__) @*/
/*@set @__STRING_JS__ = true @*/

var _CMD_stat = null;
function _CMD(str)
{
    if (!_CMD_stat) {
        _CMD_stat = {
            "re_quot": new RegExp("\"", "g")
        };
    }

    if (str == null) return null;
    switch (typeof(str)) {
        case "string":    break;
        case "undefined": return null;
        default:          try { str = str.toString(); } catch (err) { return null; }
    }

    return str.replace(_CMD_stat.re_quot, "\"\"");
}


var BuildPath_stat = null;
function BuildPath(str)
{
    if (!BuildPath_stat) {
        BuildPath_stat = {
            "fso": WScript.CreateObject("Scripting.FileSystemObject")
        };
    }

    for (var i = 1, n_arg = arguments.length; i < n_arg; i++)
        str = BuildPath_stat.fso.BuildPath(str, arguments[i]);

    return str;
}




/*@end @*/
