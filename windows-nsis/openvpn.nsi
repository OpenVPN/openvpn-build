; ****************************************************************************
; * Copyright (C) 2002-2010 OpenVPN Technologies, Inc.                       *
; * Copyright (C)      2012 Alon Bar-Lev <alon.barlev@gmail.com>             *
; *  This program is free software; you can redistribute it and/or modify    *
; *  it under the terms of the GNU General Public License version 2          *
; *  as published by the Free Software Foundation.                           *
; ****************************************************************************

; OpenVPN install script for Windows, using NSIS

SetCompressor lzma

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

; Read the command-line parameters
!insertmacro GetParameters
!insertmacro GetOptions

; Default service settings
!define OPENVPN_CONFIG_EXT   "ovpn"

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
!define MUI_WELCOMEPAGE_TEXT "This wizard will guide you through the installation of ${PACKAGE_NAME} ${SPECIAL_BUILD}, an Open Source VPN package by James Yonan.$\r$\n$\r$\nNote that the Windows version of ${PACKAGE_NAME} will only run on Windows XP, or higher.$\r$\n$\r$\n$\r$\n"

!define MUI_COMPONENTSPAGE_TEXT_TOP "Select the components to install/upgrade.  Stop any ${PACKAGE_NAME} processes or the ${PACKAGE_NAME} service if it is running.  All DLLs are installed locally."

!define MUI_COMPONENTSPAGE_SMALLDESC
!define MUI_FINISHPAGE_SHOWREADME "$INSTDIR\doc\INSTALL-win32.txt"
!define MUI_FINISHPAGE_RUN_TEXT "Start OpenVPN GUI"
!define MUI_FINISHPAGE_RUN "$INSTDIR\bin\openvpn-gui.exe"
!define MUI_FINISHPAGE_RUN_NOTCHECKED

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
!define MUI_PAGE_CUSTOMFUNCTION_SHOW StartGUI.show
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_UNPAGE_FINISH

Var /Global strGuiKilled ; Track if GUI was killed so we can tick the checkbox to start it upon installer finish

;--------------------------------
;Languages
 
!insertmacro MUI_LANGUAGE "English"
  
;--------------------------------
;Language Strings

LangString DESC_SecOpenVPNUserSpace ${LANG_ENGLISH} "Install ${PACKAGE_NAME} user-space components, including openvpn.exe."

!ifdef USE_OPENVPN_GUI
	LangString DESC_SecOpenVPNGUI ${LANG_ENGLISH} "Install ${PACKAGE_NAME} GUI by Mathias Sundman"
!endif

!ifdef USE_TAP_WINDOWS
	LangString DESC_SecTAP ${LANG_ENGLISH} "Install/upgrade the TAP virtual device driver."
!endif

!ifdef USE_EASYRSA
	LangString DESC_SecOpenVPNEasyRSA ${LANG_ENGLISH} "Install ${PACKAGE_NAME} RSA scripts for X509 certificate management."
!endif

LangString DESC_SecOpenSSLDLLs ${LANG_ENGLISH} "Install OpenSSL DLLs locally (may be omitted if DLLs are already installed globally)."

LangString DESC_SecLZODLLs ${LANG_ENGLISH} "Install LZO DLLs locally (may be omitted if DLLs are already installed globally)."

LangString DESC_SecPKCS11DLLs ${LANG_ENGLISH} "Install PKCS#11 helper DLLs locally (may be omitted if DLLs are already installed globally)."

LangString DESC_SecService ${LANG_ENGLISH} "Install the ${PACKAGE_NAME} service wrapper (openvpnserv.exe)"

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

	Push $0
	FindWindow $0 "OpenVPN-GUI"
	StrCmp $0 0 guiNotRunning

	MessageBox MB_YESNO|MB_ICONEXCLAMATION "To perform the specified operation, OpenVPN-GUI needs to be closed. Shall I close it?" /SD IDYES IDNO guiEndNo
	DetailPrint "Closing OpenVPN-GUI..."
	Goto guiEndYes

	guiEndNo:
		Quit

	guiEndYes:
		; user wants to close GUI as part of install/upgrade
		FindWindow $0 "OpenVPN-GUI"
		IntCmp $0 0 guiClosed
		SendMessage $0 ${WM_CLOSE} 0 0
		Sleep 100
		Goto guiEndYes

	guiClosed:
		; Keep track that we closed the GUI so we can offer to auto (re)start it later
		StrCpy $strGuiKilled "1"

	guiNotRunning:
		; GUI not running/closed successfully, carry on with install/upgrade
		Pop $0
	
		; Delete previous start menu folder
		RMDir /r "$SMPROGRAMS\${PACKAGE_NAME}"

		; Stop & Remove previous OpenVPN service
		DetailPrint "Removing any previous OpenVPN service..."
		nsExec::ExecToLog '"$INSTDIR\bin\openvpnserv.exe" -remove'
		Pop $R0 # return value/error/timeout

		Sleep 3000

SectionEnd

Section /o "-workaround" SecAddShortcutsWorkaround
	; this section should be selected as SecAddShortcuts
	; as we don't want to move SecAddShortcuts to top of selection
SectionEnd

Section /o "${PACKAGE_NAME} User-Space Components" SecOpenVPNUserSpace

	SetOverwrite on

	SetOutPath "$INSTDIR\bin"
	File "${OPENVPN_ROOT}\bin\openvpn.exe"

	SetOutPath "$INSTDIR\doc"
	File "${OPENVPN_ROOT}\share\doc\openvpn\INSTALL-win32.txt"
	File "${OPENVPN_ROOT}\share\doc\openvpn\openvpn.8.html"

	${If} ${SectionIsSelected} ${SecAddShortcutsWorkaround}
		CreateDirectory "$SMPROGRAMS\${PACKAGE_NAME}\Documentation"
		CreateShortCut "$SMPROGRAMS\${PACKAGE_NAME}\Documentation\${PACKAGE_NAME} Manual Page.lnk" "$INSTDIR\doc\openvpn.8.html"
		CreateShortCut "$SMPROGRAMS\${PACKAGE_NAME}\Documentation\${PACKAGE_NAME} Windows Notes.lnk" "$INSTDIR\doc\INSTALL-win32.txt"
	${EndIf}
SectionEnd

Section /o "${PACKAGE_NAME} Service" SecService

	SetOverwrite on

	SetOutPath "$INSTDIR\bin"
	File "${OPENVPN_ROOT}\bin\openvpnserv.exe"

	SetOutPath "$INSTDIR\config"

	FileOpen $R0 "$INSTDIR\config\README.txt" w
	FileWrite $R0 "This directory should contain ${PACKAGE_NAME} configuration files$\r$\n"
	FileWrite $R0 "each having an extension of .${OPENVPN_CONFIG_EXT}$\r$\n"
	FileWrite $R0 "$\r$\n"
	FileWrite $R0 "When ${PACKAGE_NAME} is started as a service, a separate ${PACKAGE_NAME}$\r$\n"
	FileWrite $R0 "process will be instantiated for each configuration file.$\r$\n"
	FileClose $R0

	SetOutPath "$INSTDIR\sample-config"
	File "${OPENVPN_ROOT}\share\doc\openvpn\sample\sample.${OPENVPN_CONFIG_EXT}"
	File "${OPENVPN_ROOT}\share\doc\openvpn\sample\client.${OPENVPN_CONFIG_EXT}"
	File "${OPENVPN_ROOT}\share\doc\openvpn\sample\server.${OPENVPN_CONFIG_EXT}"

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

	; install openvpnserv as a service (to be started manually from service control manager)
	DetailPrint "Installing OpenVPN Service..."
	nsExec::ExecToLog '"$INSTDIR\bin\openvpnserv.exe" -install'
	Pop $R0 # return value/error/timeout

SectionEnd

!ifdef USE_TAP_WINDOWS
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
!endif

!ifdef USE_OPENVPN_GUI
Section /o "${PACKAGE_NAME} GUI" SecOpenVPNGUI

	SetOverwrite on
	SetOutPath "$INSTDIR\bin"

	File "${OPENVPN_ROOT}\bin\openvpn-gui.exe"

	${If} ${SectionIsSelected} ${SecAddShortcutsWorkaround}
		CreateDirectory "$SMPROGRAMS\${PACKAGE_NAME}"
		CreateShortCut "$SMPROGRAMS\${PACKAGE_NAME}\${PACKAGE_NAME} GUI.lnk" "$INSTDIR\bin\openvpn-gui.exe" ""
		CreateShortcut "$DESKTOP\${PACKAGE_NAME} GUI.lnk" "$INSTDIR\bin\openvpn-gui.exe"
	${EndIf}
SectionEnd
!endif

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
	File "${OPENVPN_ROOT}\bin\openssl.exe"

SectionEnd

!ifdef USE_EASYRSA
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
!endif

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
		File "${OPENVPN_ROOT}\bin\libeay32.dll"
		File "${OPENVPN_ROOT}\bin\ssleay32.dll"

	SectionEnd

	Section /o "LZO DLLs" SecLZODLLs

		SetOverwrite on
		SetOutPath "$INSTDIR\bin"
		File "${OPENVPN_ROOT}\bin\liblzo2-2.dll"

	SectionEnd

	Section /o "PKCS#11 DLLs" SecPKCS11DLLs

		SetOverwrite on
		SetOutPath "$INSTDIR\bin"
		File "${OPENVPN_ROOT}\bin\libpkcs11-helper-1.dll"

	SectionEnd

SectionGroupEnd

;--------------------------------
;Installer Sections

Function .onInit
	${GetParameters} $R0
	ClearErrors

	!insertmacro SelectByParameter ${SecAddShortcutsWorkaround} SELECT_SHORTCUTS 1
	!insertmacro SelectByParameter ${SecOpenVPNUserSpace} SELECT_OPENVPN 1
	!insertmacro SelectByParameter ${SecService} SELECT_SERVICE 1
!ifdef USE_TAP_WINDOWS
	!insertmacro SelectByParameter ${SecTAP} SELECT_TAP 1
!endif
!ifdef USE_OPENVPN_GUI
	!insertmacro SelectByParameter ${SecOpenVPNGUI} SELECT_OPENVPNGUI 1
!endif
	!insertmacro SelectByParameter ${SecFileAssociation} SELECT_ASSOCIATIONS 1
	!insertmacro SelectByParameter ${SecOpenSSLUtilities} SELECT_OPENSSL_UTILITIES 0
!ifdef USE_EASYRSA
	!insertmacro SelectByParameter ${SecOpenVPNEasyRSA} SELECT_EASYRSA 0
!endif
	!insertmacro SelectByParameter ${SecAddPath} SELECT_PATH 1
	!insertmacro SelectByParameter ${SecAddShortcuts} SELECT_SHORTCUTS 1
	!insertmacro SelectByParameter ${SecOpenSSLDLLs} SELECT_OPENSSLDLLS 1
	!insertmacro SelectByParameter ${SecLZODLLs} SELECT_LZODLLS 1
	!insertmacro SelectByParameter ${SecPKCS11DLLs} SELECT_PKCS11DLLS 1

	!insertmacro MULTIUSER_INIT
	SetShellVarContext all

	; Check if we're running on 64-bit Windows
	${If} "${ARCH}" == "x86_64"
		SetRegView 64

		; Change the installation directory to C:\Program Files, but only if the
		; user has not provided a custom install location.
		${If} "$INSTDIR" == "$PROGRAMFILES\${PACKAGE_NAME}"
			StrCpy $INSTDIR "$PROGRAMFILES64\${PACKAGE_NAME}"
		${EndIf}
	${EndIf}

FunctionEnd

;--------------------------------
;Dependencies

Function .onSelChange
	${If} ${SectionIsSelected} ${SecService}
		!insertmacro SelectSection ${SecOpenVPNUserSpace}
	${EndIf}
!ifdef USE_EASYRSA
	${If} ${SectionIsSelected} ${SecOpenVPNEasyRSA}
		!insertmacro SelectSection ${SecOpenSSLUtilities}
	${EndIf}
!endif
	${If} ${SectionIsSelected} ${SecAddShortcuts}
		!insertmacro SelectSection ${SecAddShortcutsWorkaround}
	${Else}
		!insertmacro UnselectSection ${SecAddShortcutsWorkaround}
	${EndIf}
FunctionEnd

Function StartGUI.show
	; if the user chooses not to install the GUI, do not offer to start it
	${IfNot} ${SectionIsSelected} ${SecOpenVPNGUI}
		SendMessage $mui.FinishPage.Run ${BM_SETCHECK} ${BST_CHECKED} 0
		ShowWindow $mui.FinishPage.Run 0
	${EndIf}

	; if we killed the GUI to do the install/upgrade, automatically tick the "Start OpenVPN GUI" option
	${If} $strGuiKilled == "1"
		SendMessage $mui.FinishPage.Run ${BM_SETCHECK} ${BST_CHECKED} 1
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

SectionEnd

;--------------------------------
;Descriptions

!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
	!insertmacro MUI_DESCRIPTION_TEXT ${SecOpenVPNUserSpace} $(DESC_SecOpenVPNUserSpace)
	!insertmacro MUI_DESCRIPTION_TEXT ${SecService} $(DESC_SecService)
	!ifdef USE_OPENVPN_GUI
		!insertmacro MUI_DESCRIPTION_TEXT ${SecOpenVPNGUI} $(DESC_SecOpenVPNGUI)
	!endif
	!ifdef USE_TAP_WINDOWS
		!insertmacro MUI_DESCRIPTION_TEXT ${SecTAP} $(DESC_SecTAP)
	!endif
	!ifdef USE_EASYRSA
		!insertmacro MUI_DESCRIPTION_TEXT ${SecOpenVPNEasyRSA} $(DESC_SecOpenVPNEasyRSA)
	!endif
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
	${If} "${ARCH}" == "x86_64"
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
	DetailPrint "Removing OpenVPN Service..."
	nsExec::ExecToLog '"$INSTDIR\bin\openvpnserv.exe" -remove'
	Pop $R0 # return value/error/timeout

	Sleep 3000

	!ifdef USE_TAP_WINDOWS
		ReadRegStr $R0 HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\${PACKAGE_NAME}" "tap"
		${If} $R0 == "installed"
			ReadRegStr $R0 HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\TAP-Windows" "UninstallString"
			${If} $R0 != ""
				DetailPrint "Uninstalling TAP..."
				nsExec::ExecToLog '"$R0" /S'
				Pop $R0 # return value/error/timeout
			${EndIf}
		${EndIf}
	!endif

	${un.EnvVarUpdate} $R0 "PATH" "R" "HKLM" "$INSTDIR\bin"

	!ifdef USE_OPENVPN_GUI
		Delete "$INSTDIR\bin\openvpn-gui.exe"
		Delete "$DESKTOP\${PACKAGE_NAME} GUI.lnk"
	!endif

	Delete "$INSTDIR\bin\openvpn.exe"
	Delete "$INSTDIR\bin\openvpnserv.exe"
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

	!ifdef USE_EASYRSA
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
	!endif

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
