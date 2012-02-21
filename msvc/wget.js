/*
 * wget.js  - a simple wget implementation in jscript.
 *
 * Copyright (C) 2008-2012 Alon Bar-Lev <alon.barlev@gmail.com>
 *
 * BSD License
 * ============
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *     o Redistributions of source code must retain the above copyright notice,
 *       this list of conditions and the following disclaimer.
 *     o Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     o Neither the name of the Alon Bar-Lev nor the names of its
 *       contributors may be used to endorse or promote products derived from
 *       this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 *
 */
var ForWriting = 2;
var adTypeBinary = 1;
var adTypeText = 2;
var adSaveCreateOverWrite = 2;

function _http_get(url) {
	var http = new ActiveXObject("WinHttp.WinHttpRequest.5.1");
	http.Open("GET", url, false);
	http.send();
	return http;
}

function http_get(url, file) {
	var http = _http_get(url);
	try {
		while(true) {
			var location = http.GetResponseHeader("Location");
			http = _http_get(location);
		}
	} catch(e) {}

	var stream = new ActiveXObject("ADODB.Stream");
	stream.Type = adTypeBinary;
	stream.Open();
	stream.Write(http.ResponseBody);
	stream.SaveToFile(file, adSaveCreateOverWrite);
	stream.close();
}

if (WScript.Arguments.length != 2) {
	WScript.StdErr.WriteLine("Usage: wget.js url file");
	WScript.Quit(1);
}

var index = 0;
var url = WScript.Arguments(index++);
var file = WScript.Arguments(index++);
try {
	http_get(url, file);
	WScript.Quit(0);
}
catch(e) {
	WScript.Echo("ERROR: Cannot get '" + url + "'");
	WScript.Quit(1);
}