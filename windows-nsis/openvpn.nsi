; ****************************************************************************
; * Copyright (C) 2002-2010 OpenVPN Technologies, Inc.                       *
; * Copyright (C)      2012 Alon Bar-Lev <alon.barlev@gmail.com>             *
; *  This program is free software; you can redistribute it and/or modify    *
; *  it under the terms of the GNU General Public License version 2          *
; *  as published by the Free Software Foundation.                           *
; ****************************************************************************

; OpenVPN install script for Windows, using NSIS

SetCompressor lzma

!define PRODUCT_PUBLISHER "OpenVPN Technologies, Inc."

; Modern user interface
!include "MUI2.nsh"

; Install for all users. MultiUser.nsh also calls SetShellVarContext to point 
; the installer to global directories (e.g. Start menu, desktop, etc.)
!define MULTIUSER_EXECUTIONLEVEL Admin
!include "MultiUser.nsh"

; EnvVarUpdate.nsh is needed to update the PATH environment variable
!include "EnvVarUpdate.nsh"

; WinMessages.nsh is needed to send WM_CLOSE to the GUI if it is still running
!include "WinMessages.nsh"

; nsProcess.nsh to detect whether OpenVPN process is running ( http://nsis.sourceforge.net/NsProcess_plugin )
!addplugindir .
!include "nsProcess.nsh"

; x64.nsh for architecture detection
!include "x64.nsh"

; Read the command-line parameters
!insertmacro GetParameters
!insertmacro GetOptions

; Default service settings
!define OPENVPN_CONFIG_EXT "ovpn"

;--------------------------------
;Configuration

;General

; Package name as shown in the installer GUI
Name "${PACKAGE_NAME} ${VERSION_STRING}"

; On 64-bit Windows the constant $PROGRAMFILES defaults to
; C:\Program Files (x86) and on 32-bit Windows to C:\Program Files. However,
; the .onInit function (see below) takes care of changing this for 64-bit 
; Windows.
InstallDir "$PROGRAMFILES\${PACKAGE_NAME}"

; Installer filename
OutFile "${OUTPUT}"

ShowInstDetails show
ShowUninstDetails show

;Remember install folder
InstallDirRegKey HKLM "SOFTWARE\${PACKAGE_NAME}" ""

;--------------------------------
;Modern UI Configuration

; Compile-time constants which we'll need during install
!define MUI_WELCOMEPAGE_TEXT "This wizard will guide you through the installation of ${PACKAGE_NAME} ${SPECIAL_BUILD}, an Open Source VPN package by James Yonan.$\r$\n$\r$\nNote that the Windows version of ${PACKAGE_NAME} will only run on Windows Vista, or higher.$\r$\n$\r$\n$\r$\n"

!define MUI_COMPONENTSPAGE_TEXT_TOP "Select the components to install/upgrade.  Stop any ${PACKAGE_NAME} processes or the ${PACKAGE_NAME} service if it is running.  All DLLs are installed locally."

!define MUI_COMPONENTSPAGE_SMALLDESC
!define MUI_FINISHPAGE_SHOWREADME "$INSTDIR\doc\INSTALL-win32.txt"

!define MUI_FINISHPAGE_NOAUTOCLOSE
!define MUI_ABORTWARNING
!define MUI_ICON "icon.ico"
!define MUI_UNICON "icon.ico"
!define MUI_HEADERIMAGE
!define MUI_HEADERIMAGE_BITMAP "install-whirl.bmp"
!define MUI_UNFINISHPAGE_NOAUTOCLOSE

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "${OPENVPN_ROOT}\share\doc\openvpn\license.txt"
!insertmacro MUI_PAGE_COMPONENTS
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_UNPAGE_FINISH

;--------------------------------
;Languages
 
!insertmacro MUI_LANGUAGE "English"
  
;--------------------------------
;Language Strings

LangString DESC_SecOpenVPNUserSpace ${LANG_ENGLISH} "Install ${PACKAGE_NAME} user-space components, including openvpn.exe."

LangString DESC_SecOpenVPNGUI ${LANG_ENGLISH} "Install ${PACKAGE_NAME} GUI by Mathias Sundman"

LangString DESC_SecTAP ${LANG_ENGLISH} "Install/upgrade the TAP virtual device driver."

LangString DESC_SecOpenVPNEasyRSA ${LANG_ENGLISH} "Install ${PACKAGE_NAME} RSA scripts for X509 certificate management."

LangString DESC_SecOpenSSLDLLs ${LANG_ENGLISH} "Install OpenSSL DLLs locally (may be omitted if DLLs are already installed globally)."

LangString DESC_SecLZODLLs ${LANG_ENGLISH} "Install LZO DLLs locally (may be omitted if DLLs are already installed globally)."

LangString DESC_SecPKCS11DLLs ${LANG_ENGLISH} "Install PKCS#11 helper DLLs locally (may be omitted if DLLs are already installed globally)."

LangString DESC_SecService ${LANG_ENGLISH} "Install the ${PACKAGE_NAME} service wrappers"

LangString DESC_SecInteractiveService ${LANG_ENGLISH} "Install the ${PACKAGE_NAME} Interactive Service (allows running OpenVPN-GUI without admin privileges)"

LangString DESC_SecOpenSSLUtilities ${LANG_ENGLISH} "Install the OpenSSL Utilities (used for generating public/private key pairs)."

LangString DESC_SecAddPath ${LANG_ENGLISH} "Add ${PACKAGE_NAME} executable directory to the current user's PATH."

LangString DESC_SecAddShortcuts ${LANG_ENGLISH} "Add ${PACKAGE_NAME} shortcuts to the current user's Start Menu."

LangString DESC_SecFileAssociation ${LANG_ENGLISH} "Register ${PACKAGE_NAME} config file association (*.${OPENVPN_CONFIG_EXT})"

;--------------------------------
;Reserve Files
  
;Things that need to be extracted on first (keep these lines before any File command!)
;Only useful for BZIP2 compression

ReserveFile "install-whirl.bmp"

;--------------------------------
;Macros

!macro SelectByParameter SECT PARAMETER DEFAULT
	${GetOptions} $R0 "/${PARAMETER}=" $0
	${If} ${DEFAULT} == 0
		${If} $0 == 1
			!insertmacro SelectSection ${SECT}
		${EndIf}
	${Else}
		${If} $0 != 0
			!insertmacro SelectSection ${SECT}
		${EndIf}
	${EndIf}
!macroend

!macro WriteRegStringIfUndef ROOT SUBKEY KEY VALUE
	Push $R0
	ReadRegStr $R0 "${ROOT}" "${SUBKEY}" "${KEY}"
	${If} $R0 == ""
		WriteRegStr "${ROOT}" "${SUBKEY}" "${KEY}" '${VALUE}'
	${EndIf}
	Pop $R0
!macroend

!macro DelRegKeyIfUnchanged ROOT SUBKEY VALUE
	Push $R0
	ReadRegStr $R0 "${ROOT}" "${SUBKEY}" ""
	${If} $R0 == '${VALUE}'
		DeleteRegKey "${ROOT}" "${SUBKEY}"
	${EndIf}
	Pop $R0
!macroend

;--------------------
;Pre-install section

Section -pre
	Push $0 ; for FindWindow
	FindWindow $0 "OpenVPN-GUI"
	StrCmp $0 0 guiNotRunning

	MessageBox MB_YESNO|MB_ICONEXCLAMATION "To perform the specified operation, OpenVPN-GUI needs to be closed. You will have to restart it manually after the installation has completed. Shall I close it?" /SD IDYES IDNO guiEndNo
	Goto guiEndYes

	guiEndNo:
		Quit

	guiEndYes:
		DetailPrint "Closing OpenVPN-GUI..."
		; user wants to close GUI as part of install/upgrade
		FindWindow $0 "OpenVPN-GUI"
		IntCmp $0 0 guiNotRunning
		SendMessage $0 ${WM_CLOSE} 0 0
		Sleep 100
		Goto guiEndYes

	guiNotRunning:
		; check for running openvpn.exe processes
		${nsProcess::FindProcess} "openvpn.exe" $R0
		${If} $R0 == 0
			MessageBox MB_OK|MB_ICONEXCLAMATION "The installation cannot continue as OpenVPN is currently running. Please close all OpenVPN instances and re-run the installer."
			Quit
		${EndIf}

		; openvpn.exe + GUI not running/closed successfully, carry on with install/upgrade
	
		; Delete previous start menu folder
		RMDir /r "$SMPROGRAMS\${PACKAGE_NAME}"

		; Stop & Remove previous OpenVPN service
		DetailPrint "Removing any previous OpenVPN services..."
		nsExec::ExecToLog '"$INSTDIR\bin\openvpnserv.exe" -remove'
		nsExec::ExecToLog '"$INSTDIR\bin\openvpnserv2.exe" -remove'
		Pop $R0 # return value/error/timeout

		Sleep 3000
	Pop $0 ; for FindWindow

SectionEnd

Section /o "-workaround" SecAddShortcutsWorkaround
	; this section should be selected as SecAddShortcuts
	; as we don't want to move SecAddShortcuts to top of selection
SectionEnd

Section /o "${PACKAGE_NAME} User-Space Components" SecOpenVPNUserSpace

	SetOverwrite on

	SetOutPath "$INSTDIR\bin"
	${If} ${RunningX64}
		File "${OPENVPN_ROOT_X86_64}\bin\openvpn.exe"
	${Else}
		File "${OPENVPN_ROOT_I686}\bin\openvpn.exe"
	${EndIf}

	SetOutPath "$INSTDIR\doc"
	File "INSTALL-win32.txt"
	File "${OPENVPN_ROOT_I686}\share\doc\openvpn\openvpn.8.html"

	${If} ${SectionIsSelected} ${SecAddShortcutsWorkaround}
		CreateDirectory "$SMPROGRAMS\${PACKAGE_NAME}\Documentation"
		CreateShortCut "$SMPROGRAMS\${PACKAGE_NAME}\Documentation\${PACKAGE_NAME} Manual Page.lnk" "$INSTDIR\doc\openvpn.8.html"
		CreateShortCut "$SMPROGRAMS\${PACKAGE_NAME}\Documentation\${PACKAGE_NAME} Windows Notes.lnk" "$INSTDIR\doc\INSTALL-win32.txt"
	${EndIf}

SectionEnd

Section /o "${PACKAGE_NAME} Service" SecService

	SetOverwrite on

	SetOutPath "$INSTDIR\bin"
	File /oname=openvpnserv2.exe "${OPENVPNSERV2_EXECUTABLE}"
	${If} ${RunningX64}
		File "${OPENVPN_ROOT_X86_64}\bin\openvpnserv.exe"
	${Else}
		File "${OPENVPN_ROOT_I686}\bin\openvpnserv.exe"
	${EndIf}

	SetOutPath "$INSTDIR\config"

	FileOpen $R0 "$INSTDIR\config\README.txt" w
	FileWrite $R0 "This directory should contain ${PACKAGE_NAME} configuration files$\r$\n"
	FileWrite $R0 "each having an extension of .${OPENVPN_CONFIG_EXT}$\r$\n"
	FileWrite $R0 "$\r$\n"
	FileWrite $R0 "When ${PACKAGE_NAME} is started as a service, a separate ${PACKAGE_NAME}$\r$\n"
	FileWrite $R0 "process will be instantiated for each configuration file.$\r$\n"
	FileClose $R0

	SetOutPath "$INSTDIR\sample-config"
	File "${OPENVPN_ROOT_I686}\share\doc\openvpn\sample\sample.${OPENVPN_CONFIG_EXT}"
	File "${OPENVPN_ROOT_I686}\share\doc\openvpn\sample\client.${OPENVPN_CONFIG_EXT}"
	File "${OPENVPN_ROOT_I686}\share\doc\openvpn\sample\server.${OPENVPN_CONFIG_EXT}"

	CreateDirectory "$INSTDIR\log"
	FileOpen $R0 "$INSTDIR\log\README.txt" w
	FileWrite $R0 "This directory will contain the log files for ${PACKAGE_NAME}$\r$\n"
	FileWrite $R0 "sessions which are being run as a service.$\r$\n"
	FileClose $R0

	${If} ${SectionIsSelected} ${SecAddShortcutsWorkaround}
		CreateDirectory "$SMPROGRAMS\${PACKAGE_NAME}\Utilities"
		CreateShortCut "$SMPROGRAMS\${PACKAGE_NAME}\Utilities\Generate a static ${PACKAGE_NAME} key.lnk" "$INSTDIR\bin\openvpn.exe" '--pause-exit --verb 3 --genkey --secret "$INSTDIR\config\key.txt"' "$INSTDIR\icon.ico" 0
		CreateDirectory "$SMPROGRAMS\${PACKAGE_NAME}\Shortcuts"
		CreateShortCut "$SMPROGRAMS\${PACKAGE_NAME}\Shortcuts\${PACKAGE_NAME} Sample Configuration Files.lnk" "$INSTDIR\sample-config" ""
		CreateShortCut "$SMPROGRAMS\${PACKAGE_NAME}\Shortcuts\${PACKAGE_NAME} log file directory.lnk" "$INSTDIR\log" ""
		CreateShortCut "$SMPROGRAMS\${PACKAGE_NAME}\Shortcuts\${PACKAGE_NAME} configuration file directory.lnk" "$INSTDIR\config" ""
	${EndIf}

	; set registry parameters for openvpnserv	
	!insertmacro WriteRegStringIfUndef HKLM "SOFTWARE\${PACKAGE_NAME}" "config_dir" "$INSTDIR\config" 
	!insertmacro WriteRegStringIfUndef HKLM "SOFTWARE\${PACKAGE_NAME}" "config_ext"  "${OPENVPN_CONFIG_EXT}"
	!insertmacro WriteRegStringIfUndef HKLM "SOFTWARE\${PACKAGE_NAME}" "exe_path"    "$INSTDIR\bin\openvpn.exe"
	!insertmacro WriteRegStringIfUndef HKLM "SOFTWARE\${PACKAGE_NAME}" "log_dir"     "$INSTDIR\log"
	!insertmacro WriteRegStringIfUndef HKLM "SOFTWARE\${PACKAGE_NAME}" "priority"    "NORMAL_PRIORITY_CLASS"
	!insertmacro WriteRegStringIfUndef HKLM "SOFTWARE\${PACKAGE_NAME}" "log_append"  "0"

	; install openvpnserv.exe as a services
	DetailPrint "Installing OpenVPN Services..."
	nsExec::ExecToLog '"$INSTDIR\bin\openvpnserv.exe" -install'
	nsExec::ExecToLog '"$INSTDIR\bin\openvpnserv2.exe" -install'

	Pop $R0 # return value/error/timeout

SectionEnd

Section "${PACKAGE_NAME} Interactive Service" SecInteractiveService
SectionEnd

Section /o "TAP Virtual Ethernet Adapter" SecTAP

	SetOverwrite on
	SetOutPath "$TEMP"

	File /oname=tap-windows.exe "${TAP_WINDOWS_INSTALLER}"

	DetailPrint "Installing TAP (may need confirmation)..."
	nsExec::ExecToLog '"$TEMP\tap-windows.exe" /S /SELECT_UTILITIES=1'
	Pop $R0 # return value/error/timeout

	Delete "$TEMP\tap-windows.exe"

	WriteRegStr HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\${PACKAGE_NAME}" "tap" "installed"
SectionEnd

Section /o "${PACKAGE_NAME} GUI" SecOpenVPNGUI

	SetOverwrite on
	SetOutPath "$INSTDIR\bin"

	${If} ${RunningX64}
		File "${OPENVPN_ROOT_X86_64}\bin\openvpn-gui.exe"
	${Else}
		File "${OPENVPN_ROOT_I686}\bin\openvpn-gui.exe"
	${EndIf}

	${If} ${SectionIsSelected} ${SecAddShortcutsWorkaround}
		CreateDirectory "$SMPROGRAMS\${PACKAGE_NAME}"
		CreateShortCut "$SMPROGRAMS\${PACKAGE_NAME}\${PACKAGE_NAME} GUI.lnk" "$INSTDIR\bin\openvpn-gui.exe" ""
		CreateShortcut "$DESKTOP\${PACKAGE_NAME} GUI.lnk" "$INSTDIR\bin\openvpn-gui.exe"
	${EndIf}
SectionEnd

Section /o "${PACKAGE_NAME} File Associations" SecFileAssociation
	WriteRegStr HKCR ".${OPENVPN_CONFIG_EXT}" "" "${PACKAGE_NAME}File"
	WriteRegStr HKCR "${PACKAGE_NAME}File" "" "${PACKAGE_NAME} Config File"
	WriteRegStr HKCR "${PACKAGE_NAME}File\shell" "" "open"
	WriteRegStr HKCR "${PACKAGE_NAME}File\DefaultIcon" "" "$INSTDIR\icon.ico,0"
	WriteRegStr HKCR "${PACKAGE_NAME}File\shell\open\command" "" 'notepad.exe "%1"'
	WriteRegStr HKCR "${PACKAGE_NAME}File\shell\run" "" "Start ${PACKAGE_NAME} on this config file"
	WriteRegStr HKCR "${PACKAGE_NAME}File\shell\run\command" "" '"$INSTDIR\bin\openvpn.exe" --pause-exit --config "%1"'
SectionEnd

Section /o "OpenSSL Utilities" SecOpenSSLUtilities

	SetOverwrite on
	SetOutPath "$INSTDIR\bin"
	${If} ${RunningX64}
		File "${OPENVPN_ROOT_X86_64}\bin\openssl.exe"
	${Else}
		File "${OPENVPN_ROOT_I686}\bin\openssl.exe"
	${EndIf}

SectionEnd

Section /o "${PACKAGE_NAME} RSA Certificate Management Scripts" SecOpenVPNEasyRSA

	SetOverwrite on
	SetOutPath "$INSTDIR\easy-rsa"

	File "${EASYRSA_ROOT}\2.0\openssl-1.0.0.cnf"
	File "${EASYRSA_ROOT}\Windows\vars.bat.sample"

	File "${EASYRSA_ROOT}\Windows\init-config.bat"

	File "${EASYRSA_ROOT}\Windows\README.txt"
	File "${EASYRSA_ROOT}\Windows\build-ca.bat"
	File "${EASYRSA_ROOT}\Windows\build-dh.bat"
	File "${EASYRSA_ROOT}\Windows\build-key-server.bat"
	File "${EASYRSA_ROOT}\Windows\build-key.bat"
	File "${EASYRSA_ROOT}\Windows\build-key-pass.bat"
	File "${EASYRSA_ROOT}\Windows\build-key-pkcs12.bat"
	File "${EASYRSA_ROOT}\Windows\clean-all.bat"
	File "${EASYRSA_ROOT}\Windows\index.txt.start"
	File "${EASYRSA_ROOT}\Windows\revoke-full.bat"
	File "${EASYRSA_ROOT}\Windows\serial.start"

SectionEnd

Section /o "Add ${PACKAGE_NAME} to PATH" SecAddPath

	; append our bin directory to end of current user path
	${EnvVarUpdate} $R0 "PATH" "A" "HKLM" "$INSTDIR\bin"

SectionEnd

Section /o "Add Shortcuts to Start Menu" SecAddShortcuts

	SetOverwrite on
	CreateDirectory "$SMPROGRAMS\${PACKAGE_NAME}\Documentation"
	WriteINIStr "$SMPROGRAMS\${PACKAGE_NAME}\Documentation\${PACKAGE_NAME} HOWTO.url" "InternetShortcut" "URL" "http://openvpn.net/howto.html"
	WriteINIStr "$SMPROGRAMS\${PACKAGE_NAME}\Documentation\${PACKAGE_NAME} Web Site.url" "InternetShortcut" "URL" "http://openvpn.net/"
	WriteINIStr "$SMPROGRAMS\${PACKAGE_NAME}\Documentation\${PACKAGE_NAME} Wiki.url" "InternetShortcut" "URL" "https://community.openvpn.net/openvpn/wiki/"
	WriteINIStr "$SMPROGRAMS\${PACKAGE_NAME}\Documentation\${PACKAGE_NAME} Support.url" "InternetShortcut" "URL" "https://community.openvpn.net/openvpn/wiki/GettingHelp"

	CreateShortCut "$SMPROGRAMS\${PACKAGE_NAME}\Uninstall ${PACKAGE_NAME}.lnk" "$INSTDIR\Uninstall.exe"
SectionEnd

SectionGroup "!Dependencies (Advanced)"

	Section /o "OpenSSL DLLs" SecOpenSSLDLLs

		SetOverwrite on
		SetOutPath "$INSTDIR\bin"
		${If} ${RunningX64}
			File "${OPENVPN_ROOT_X86_64}\bin\libeay32.dll"
			File "${OPENVPN_ROOT_X86_64}\bin\ssleay32.dll"
		${Else}
			File "${OPENVPN_ROOT_I686}\bin\libeay32.dll"
			File "${OPENVPN_ROOT_I686}\bin\ssleay32.dll"
		${EndIf}

	SectionEnd

	Section /o "LZO DLLs" SecLZODLLs

		SetOverwrite on
		SetOutPath "$INSTDIR\bin"
		${If} ${RunningX64}
			File "${OPENVPN_ROOT_X86_64}\bin\liblzo2-2.dll"
		${Else}
			File "${OPENVPN_ROOT_I686}\bin\liblzo2-2.dll"
		${EndIf}

	SectionEnd

	Section /o "PKCS#11 DLLs" SecPKCS11DLLs

		SetOverwrite on
		SetOutPath "$INSTDIR\bin"
		${If} ${RunningX64}
			File "${OPENVPN_ROOT_X86_64}\bin\libpkcs11-helper-1.dll"
		${Else}
			File "${OPENVPN_ROOT_I686}\bin\libpkcs11-helper-1.dll"
		${EndIf}

	SectionEnd

SectionGroupEnd

;--------------------------------
;Installer Sections

Function .onInit
	${GetParameters} $R0
	ClearErrors

${IfNot} ${AtLeastWinVista}

	MessageBox MB_YESNO|MB_ICONEXCLAMATION "This package does not work on your operating system.  The last version of OpenVPN supported on your OS is 2.3. Shall I open a web browser for you to download it?" /SD IDYES IDNO guiEndNo
	Goto guiEndYes

	guiEndNo:
	Quit

	guiEndYes:
	DetailPrint "Downloading the latest WinXP build ..."
	${If} ${RunningX64}
		ExecShell "open" "https://build.openvpn.net/downloads/releases/latest/openvpn-install-latest-winxp-x86_64.exe" 
	${Else}
		ExecShell "open" "https://build.openvpn.net/downloads/releases/latest/openvpn-install-latest-winxp-i686.exe"
	${EndIf}

	Quit

${EndIf}

	${If} ${RunningX64}
		SetRegView 64
		; Change the installation directory to C:\Program Files, but only if the
		; user has not provided a custom install location.
		${If} "$INSTDIR" == "$PROGRAMFILES\${PACKAGE_NAME}"
			StrCpy $INSTDIR "$PROGRAMFILES64\${PACKAGE_NAME}"
		${EndIf}
	${EndIf}

	!insertmacro SelectByParameter ${SecAddShortcutsWorkaround} SELECT_SHORTCUTS 1
	!insertmacro SelectByParameter ${SecOpenVPNUserSpace} SELECT_OPENVPN 1
	!insertmacro SelectByParameter ${SecService} SELECT_SERVICE 1
	!insertmacro SelectByParameter ${SecInteractiveService} SELECT_INTERACTIVE_SERVICE 1
	!insertmacro SelectByParameter ${SecTAP} SELECT_TAP 1
	!insertmacro SelectByParameter ${SecOpenVPNGUI} SELECT_OPENVPNGUI 1
	!insertmacro SelectByParameter ${SecFileAssociation} SELECT_ASSOCIATIONS 1
	!insertmacro SelectByParameter ${SecOpenSSLUtilities} SELECT_OPENSSL_UTILITIES 0
	!insertmacro SelectByParameter ${SecOpenVPNEasyRSA} SELECT_EASYRSA 0
	!insertmacro SelectByParameter ${SecAddPath} SELECT_PATH 1
	!insertmacro SelectByParameter ${SecAddShortcuts} SELECT_SHORTCUTS 1
	!insertmacro SelectByParameter ${SecOpenSSLDLLs} SELECT_OPENSSLDLLS 1
	!insertmacro SelectByParameter ${SecLZODLLs} SELECT_LZODLLS 1
	!insertmacro SelectByParameter ${SecPKCS11DLLs} SELECT_PKCS11DLLS 1

	!insertmacro MULTIUSER_INIT
	SetShellVarContext all

FunctionEnd

;--------------------------------
;Dependencies

Function .onSelChange
	${If} ${SectionIsSelected} ${SecService}
		!insertmacro SelectSection ${SecOpenVPNUserSpace}
	${Else}
		!insertmacro UnselectSection ${SecInteractiveService}
	${EndIf}
	${If} ${SectionIsSelected} ${SecOpenVPNEasyRSA}
		!insertmacro SelectSection ${SecOpenSSLUtilities}
	${EndIf}
	${If} ${SectionIsSelected} ${SecAddShortcuts}
		!insertmacro SelectSection ${SecAddShortcutsWorkaround}
	${Else}
		!insertmacro UnselectSection ${SecAddShortcutsWorkaround}
	${EndIf}
FunctionEnd

;--------------------
;Post-install section

Section -post

	SetOverwrite on
	SetOutPath "$INSTDIR"
	File "icon.ico"
	SetOutPath "$INSTDIR\doc"
	File "${OPENVPN_ROOT}\share\doc\openvpn\license.txt"

	; Store install folder in registry
	WriteRegStr HKLM "SOFTWARE\${PACKAGE_NAME}" "" "$INSTDIR"

	; Create uninstaller
	WriteUninstaller "$INSTDIR\Uninstall.exe"

	; Show up in Add/Remove programs
	WriteRegStr HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\${PACKAGE_NAME}" "DisplayName" "${PACKAGE_NAME} ${VERSION_STRING} ${SPECIAL_BUILD}"
	WriteRegExpandStr HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\${PACKAGE_NAME}" "UninstallString" "$INSTDIR\Uninstall.exe"
	WriteRegStr HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\${PACKAGE_NAME}" "DisplayIcon" "$INSTDIR\icon.ico"
	WriteRegStr HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\${PACKAGE_NAME}" "DisplayVersion" "${VERSION_STRING}"
	WriteRegStr HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\${PACKAGE_NAME}" "HelpLink" "https://openvpn.net/index.php/open-source.html"
	WriteRegStr HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\${PACKAGE_NAME}" "InstallLocation" "$INSTDIR\"
	WriteRegDWORD HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\${PACKAGE_NAME}" "Language" 1033
	WriteRegDWORD HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\${PACKAGE_NAME}" "NoModify" 1
	WriteRegDWORD HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\${PACKAGE_NAME}" "NoRepair" 1
	WriteRegStr HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\${PACKAGE_NAME}" "Publisher" "${PRODUCT_PUBLISHER}"
	WriteRegStr HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\${PACKAGE_NAME}" "UninstallString" "$INSTDIR\Uninstall.exe"
	WriteRegStr HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\${PACKAGE_NAME}" "URLInfoAbout" "https://openvpn.net"

	${GetSize} "$INSTDIR" "/S=0K" $0 $1 $2
	IntFmt $0 "0x%08X" $0
	WriteRegDWORD HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\${PACKAGE_NAME}" "EstimatedSize" "$0"

	; Enable and start the Interactive Service
	${If} ${SectionIsSelected} ${SecInteractiveService}
		nsExec::ExecToLog '"$SYSDIR\sc.exe" config OpenVPNServiceInteractive start= auto'

		; Get location of cmd.exe and launch sc.exe inside it to allow
		; redirecting to nul. This is done because "sc.exe start" output looks a
		; lot like an error in addition to being too verbose.
		ReadEnvStr $R0 COMSPEC
		nsExec::ExecToLog '"$R0" /c "$SYSDIR\sc.exe" start OpenVPNServiceInteractive >nul'
		Pop $R1
		${If} "$R1" == "0"
			DetailPrint "Started OpenVPNServiceInteractive"
		${Else}
			DetailPrint "WARNING: $\"sc.exe start OpenVPNServiceInteractive$\" failed with return value of $R1"
		${EndIf}
	${Else}
		nsExec::ExecToLog '"$SYSDIR\sc.exe" config OpenVPNServiceInteractive start= demand'
	${EndIf}

SectionEnd

;--------------------------------
;Descriptions

!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
	!insertmacro MUI_DESCRIPTION_TEXT ${SecOpenVPNUserSpace} $(DESC_SecOpenVPNUserSpace)
	!insertmacro MUI_DESCRIPTION_TEXT ${SecService} $(DESC_SecService)
	!insertmacro MUI_DESCRIPTION_TEXT ${SecInteractiveService} $(DESC_SecInteractiveService)
	!insertmacro MUI_DESCRIPTION_TEXT ${SecOpenVPNGUI} $(DESC_SecOpenVPNGUI)
	!insertmacro MUI_DESCRIPTION_TEXT ${SecTAP} $(DESC_SecTAP)
	!insertmacro MUI_DESCRIPTION_TEXT ${SecOpenVPNEasyRSA} $(DESC_SecOpenVPNEasyRSA)
	!insertmacro MUI_DESCRIPTION_TEXT ${SecOpenSSLUtilities} $(DESC_SecOpenSSLUtilities)
	!insertmacro MUI_DESCRIPTION_TEXT ${SecOpenSSLDLLs} $(DESC_SecOpenSSLDLLs)
	!insertmacro MUI_DESCRIPTION_TEXT ${SecLZODLLs} $(DESC_SecLZODLLs)
	!insertmacro MUI_DESCRIPTION_TEXT ${SecPKCS11DLLs} $(DESC_SecPKCS11DLLs)
	!insertmacro MUI_DESCRIPTION_TEXT ${SecAddPath} $(DESC_SecAddPath)
	!insertmacro MUI_DESCRIPTION_TEXT ${SecAddShortcuts} $(DESC_SecAddShortcuts)
	!insertmacro MUI_DESCRIPTION_TEXT ${SecFileAssociation} $(DESC_SecFileAssociation)
!insertmacro MUI_FUNCTION_DESCRIPTION_END

;--------------------------------
;Uninstaller Section

Function un.onInit
	ClearErrors
	!insertmacro MULTIUSER_UNINIT
	SetShellVarContext all
	${If} ${RunningX64}
		SetRegView 64
	${EndIf}
FunctionEnd

Section "Uninstall"

	; Stop OpenVPN-GUI if currently running
	DetailPrint "Stopping OpenVPN-GUI..."
	StopGUI:

	FindWindow $0 "OpenVPN-GUI"
	IntCmp $0 0 guiClosed
	SendMessage $0 ${WM_CLOSE} 0 0
	Sleep 100
	Goto StopGUI

	guiClosed:

	; Stop OpenVPN if currently running
	DetailPrint "Removing OpenVPN Services..."
	nsExec::ExecToLog '"$INSTDIR\bin\openvpnserv.exe" -remove'
	nsExec::ExecToLog '"$INSTDIR\bin\openvpnserv2.exe" -remove'
	Pop $R0 # return value/error/timeout

	Sleep 3000

	ReadRegStr $R0 HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\${PACKAGE_NAME}" "tap"
	${If} $R0 == "installed"
		ReadRegStr $R0 HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\TAP-Windows" "UninstallString"
		${If} $R0 != ""
			DetailPrint "Uninstalling TAP..."
			nsExec::ExecToLog '"$R0" /S'
			Pop $R0 # return value/error/timeout
		${EndIf}
	${EndIf}

	${un.EnvVarUpdate} $R0 "PATH" "R" "HKLM" "$INSTDIR\bin"

	Delete "$INSTDIR\bin\openvpn-gui.exe"
	Delete "$DESKTOP\${PACKAGE_NAME} GUI.lnk"

	Delete "$INSTDIR\bin\openvpn.exe"
	Delete "$INSTDIR\bin\openvpnserv.exe"
	Delete "$INSTDIR\bin\openvpnserv2.exe"
	Delete "$INSTDIR\bin\libeay32.dll"
	Delete "$INSTDIR\bin\ssleay32.dll"
	Delete "$INSTDIR\bin\liblzo2-2.dll"
	Delete "$INSTDIR\bin\libpkcs11-helper-1.dll"

	Delete "$INSTDIR\config\README.txt"
	Delete "$INSTDIR\config\sample.${OPENVPN_CONFIG_EXT}.txt"

	Delete "$INSTDIR\log\README.txt"

	Delete "$INSTDIR\bin\openssl.exe"

	Delete "$INSTDIR\doc\license.txt"
	Delete "$INSTDIR\doc\INSTALL-win32.txt"
	Delete "$INSTDIR\doc\openvpn.8.html"
	Delete "$INSTDIR\icon.ico"
	Delete "$INSTDIR\Uninstall.exe"

	Delete "$INSTDIR\easy-rsa\openssl-1.0.0.cnf"
	Delete "$INSTDIR\easy-rsa\vars.bat.sample"
	Delete "$INSTDIR\easy-rsa\init-config.bat"
	Delete "$INSTDIR\easy-rsa\README.txt"
	Delete "$INSTDIR\easy-rsa\build-ca.bat"
	Delete "$INSTDIR\easy-rsa\build-dh.bat"
	Delete "$INSTDIR\easy-rsa\build-key-server.bat"
	Delete "$INSTDIR\easy-rsa\build-key.bat"
	Delete "$INSTDIR\easy-rsa\build-key-pass.bat"
	Delete "$INSTDIR\easy-rsa\build-key-pkcs12.bat"
	Delete "$INSTDIR\easy-rsa\clean-all.bat"
	Delete "$INSTDIR\easy-rsa\index.txt.start"
	Delete "$INSTDIR\easy-rsa\revoke-full.bat"
	Delete "$INSTDIR\easy-rsa\serial.start"

	Delete "$INSTDIR\sample-config\*.${OPENVPN_CONFIG_EXT}"

	RMDir "$INSTDIR\bin"
	RMDir "$INSTDIR\doc"
	RMDir "$INSTDIR\config"
	RMDir "$INSTDIR\easy-rsa"
	RMDir "$INSTDIR\sample-config"
	RMDir /r "$INSTDIR\log"
	RMDir "$INSTDIR"
	RMDir /r "$SMPROGRAMS\${PACKAGE_NAME}"

	!insertmacro DelRegKeyIfUnchanged HKCR ".${OPENVPN_CONFIG_EXT}" "${PACKAGE_NAME}File"
	DeleteRegKey HKCR "${PACKAGE_NAME}File"
	DeleteRegKey HKLM "SOFTWARE\${PACKAGE_NAME}"
	DeleteRegKey HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\${PACKAGE_NAME}"

SectionEnd

