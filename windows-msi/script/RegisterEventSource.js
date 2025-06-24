function RegisterEventSource() {
    var shell = new ActiveXObject("WScript.Shell");
    var source = "OpenVPNService";
    var logName = "Application";

    var command = 'powershell -ExecutionPolicy Bypass -Command "if (-not [System.Diagnostics.EventLog]::SourceExists(\'' +
                source + '\')) {[System.Diagnostics.EventLog]::CreateEventSource(\'' +
                source + '\', \'' + logName + '\')}"';

    shell.Run(command, 0, true); // 0 = hidden, true = wait until complete
}
