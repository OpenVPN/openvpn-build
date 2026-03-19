# openvpn-build — CMake-based Windows MSI build system
#
# Usage:
#   cmake -B build -DOPENVPN_ARCH=all       (or x86, amd64, arm64)
#   cmake --build build
#
# Options:
#   -DOPENVPN_ARCH=all|x86|amd64|arm64      Architectures to build (default: all)
#   -DSIGN_BINARIES=ON                       Enable code signing
#   -DCMAKE_PROGRAM_PATH=...                 Additional search paths for tools

cmake_minimum_required(VERSION 3.20)
project(openvpn-msi NONE)

# ============================================================
# Options
# ============================================================

set(OPENVPN_ARCH "all" CACHE STRING "Architectures to build: all, x86, amd64, arm64")
set_property(CACHE OPENVPN_ARCH PROPERTY STRINGS all x86 amd64 arm64)

option(SIGN_BINARIES "Sign binaries and MSI packages" OFF)

# ============================================================
# Paths
# ============================================================

set(MSI_DIR "${CMAKE_CURRENT_SOURCE_DIR}")
set(ROOT_DIR "${CMAKE_CURRENT_SOURCE_DIR}/..")
set(DEPS_DIR "${ROOT_DIR}/src")
set(BUILD_DIR "${CMAKE_CURRENT_BINARY_DIR}/tmp")
set(SOURCE_DIR "${CMAKE_CURRENT_BINARY_DIR}/sources")
set(OUTPUT_DIR "${CMAKE_CURRENT_BINARY_DIR}/image")

# ============================================================
# Version and dependency configuration
# ============================================================

include("${MSI_DIR}/version.cmake")

message(STATUS "Building ${PRODUCT_NAME} ${PACKAGE_VERSION} (${PRODUCT_VERSION})")

# ============================================================
# Determine architectures to build
# ============================================================

set(_valid_archs all x86 amd64 arm64)
if(NOT OPENVPN_ARCH IN_LIST _valid_archs)
    message(FATAL_ERROR "Invalid OPENVPN_ARCH '${OPENVPN_ARCH}'. Must be one of: ${_valid_archs}")
endif()

if(OPENVPN_ARCH STREQUAL "all")
    set(ARCHITECTURES x86 amd64 arm64)
else()
    set(ARCHITECTURES ${OPENVPN_ARCH})
endif()

message(STATUS "Target architectures: ${ARCHITECTURES}")

# ============================================================
# Platform-specific mappings
# ============================================================

# OpenVPN GUI uses different directory names than the openvpn build arch
set(GUI_ARCH_x86 "x86")
set(GUI_ARCH_amd64 "x64")
set(GUI_ARCH_arm64 "arm64")

# OpenVPN CMake preset names
set(OVPN_PRESET_x86 "win-x86-release")
set(OVPN_PRESET_amd64 "win-amd64-release")
set(OVPN_PRESET_arm64 "win-arm64-release")

# WiX platform names
set(WIX_PLAT_x86 "x86")
set(WIX_PLAT_amd64 "x64")
set(WIX_PLAT_arm64 "arm64")

# vcpkg triplet prefix (used in vcpkg_installed paths and vcredist)
set(VCPKG_TRIPLET_x86 "x86")
set(VCPKG_TRIPLET_amd64 "x64")
set(VCPKG_TRIPLET_arm64 "arm64")

# OpenSSL platform suffix for DLL names
set(OPENSSL_PLAT_x86 "")
set(OPENSSL_PLAT_amd64 "-x64")
set(OPENSSL_PLAT_arm64 "-arm64")

# TAP-Windows platform names
set(TAP_PLAT_x86 "i386")
set(TAP_PLAT_amd64 "amd64")
set(TAP_PLAT_arm64 "arm64")

# Program Files folder for WiX
set(PROGRAM_FILES_DIR_x86 "ProgramFilesFolder")
set(PROGRAM_FILES_DIR_amd64 "ProgramFiles64Folder")
set(PROGRAM_FILES_DIR_arm64 "ProgramFiles64Folder")

# ============================================================
# Helper: build paths for each architecture
# ============================================================

macro(set_arch_paths arch)
    set(_preset "${OVPN_PRESET_${arch}}")
    set(_gui_arch "${GUI_ARCH_${arch}}")
    set(_vcpkg_triplet "${VCPKG_TRIPLET_${arch}}")

    set(OPENVPN_BIN_${arch}      "${DEPS_DIR}/openvpn/out/build/${_preset}/Release")
    set(OPENVPN_MSICA_${arch}    "${DEPS_DIR}/openvpn/out/build/${_preset}/src/openvpnmsica/Release")
    set(OPENVPN_SERV_${arch}     "${DEPS_DIR}/openvpn/out/build/${_preset}/src/openvpnserv/Release")
    set(OPENVPN_TAPCTL_${arch}   "${DEPS_DIR}/openvpn/out/build/${_preset}/src/tapctl/Release")
    set(OPENVPN_DOC_${arch}      "${DEPS_DIR}/openvpn/out/build/${_preset}/doc")
    set(OPENVPN_GUI_DIR          "${DEPS_DIR}/openvpn-gui")
    set(OPENVPN_GUI_BIN_${arch}  "${DEPS_DIR}/openvpn-gui/out/build/${_gui_arch}/Release")
    set(OPENSSL_TOOLS_${arch}    "${DEPS_DIR}/openvpn/out/build/${_preset}/vcpkg_installed/${_vcpkg_triplet}-windows-ovpn/tools/openssl")
    set(OPENSSL_BIN_${arch}      "${DEPS_DIR}/openvpn/out/build/${_preset}/vcpkg_installed/${_vcpkg_triplet}-windows-ovpn/bin")
endmacro()

foreach(_arch ${ARCHITECTURES})
    set_arch_paths(${_arch})
endforeach()

# ============================================================
# Find required tools
# ============================================================

# CMake (for building sub-projects)
find_program(CMAKE_EXE cmake HINTS "C:/Program Files/CMake/bin" REQUIRED)

# WiX Toolset
if(DEFINED ENV{WIX})
    set(WIX_DIR "$ENV{WIX}")
else()
    # Try common install locations
    find_path(WIX_DIR NAMES "bin/candle.exe"
        HINTS "C:/Program Files (x86)/WiX Toolset v3.14"
    )
endif()

find_program(WIX_CANDLE candle HINTS "${WIX_DIR}/bin" REQUIRED)
find_program(WIX_LIGHT light HINTS "${WIX_DIR}/bin" REQUIRED)
message(STATUS "WiX candle: ${WIX_CANDLE}")
message(STATUS "WiX light: ${WIX_LIGHT}")

# ============================================================
# Create output directories
# ============================================================

file(MAKE_DIRECTORY "${BUILD_DIR}")
file(MAKE_DIRECTORY "${SOURCE_DIR}")
file(MAKE_DIRECTORY "${OUTPUT_DIR}")

foreach(_arch ${ARCHITECTURES})
    file(MAKE_DIRECTORY "${BUILD_DIR}/${_arch}")
endforeach()

# ============================================================
# vcpkg bootstrap
# ============================================================

set(VCPKG_ROOT "${DEPS_DIR}/vcpkg")
set(VCPKG_OVERLAY_PORTS "${MSI_DIR}/vcpkg-ports")

# Environment for sub-builds: override VCPKG_ROOT to use our vcpkg, not
# a system-installed one (e.g. the VS-bundled vcpkg).
set(VCPKG_ENV
    ${CMAKE_COMMAND} -E env
    "VCPKG_ROOT=${VCPKG_ROOT}"
    "VCPKG_OVERLAY_PORTS=${VCPKG_OVERLAY_PORTS}"
)

add_custom_command(
    OUTPUT "${VCPKG_ROOT}/vcpkg.exe"
    COMMAND cmd /c "${VCPKG_ROOT}/bootstrap-vcpkg.bat"
    WORKING_DIRECTORY "${VCPKG_ROOT}"
    COMMENT "Bootstrapping vcpkg"
)

add_custom_target(vcpkg_bootstrap DEPENDS "${VCPKG_ROOT}/vcpkg.exe")

# ============================================================
# Build OpenVPN GUI (per architecture)
# ============================================================

foreach(_arch ${ARCHITECTURES})
    set(_gui_arch "${GUI_ARCH_${_arch}}")

    add_custom_target(openvpn_gui_${_arch}
        COMMAND ${VCPKG_ENV} "${CMAKE_EXE}" --preset ${_gui_arch}
        COMMAND ${VCPKG_ENV} "${CMAKE_EXE}" --build --preset ${_gui_arch}-release
        WORKING_DIRECTORY "${DEPS_DIR}/openvpn-gui"
        COMMENT "Building openvpn-gui (${_gui_arch})"
        DEPENDS vcpkg_bootstrap
    )
endforeach()

# ============================================================
# Build OpenVPN core (per architecture)
# ============================================================

foreach(_arch ${ARCHITECTURES})
    set(_preset "${OVPN_PRESET_${_arch}}")

    add_custom_target(openvpn_core_${_arch}
        COMMAND ${VCPKG_ENV} "${CMAKE_EXE}" --preset ${_preset}
        COMMAND ${VCPKG_ENV} "${CMAKE_EXE}" --build --preset ${_preset}
        WORKING_DIRECTORY "${DEPS_DIR}/openvpn"
        COMMENT "Building openvpn (${_preset})"
        DEPENDS vcpkg_bootstrap
    )
endforeach()

# ============================================================
# Sign OpenVPN binaries (optional, per architecture)
# ============================================================

if(SIGN_BINARIES)
    foreach(_arch ${ARCHITECTURES})
        set(_sign_arch "${_arch}")
        if(_arch STREQUAL "amd64")
            set(_sign_arch_alt "x64")
        else()
            set(_sign_arch_alt "${_arch}")
        endif()

        add_custom_target(sign_openvpn_${_arch}
            COMMAND ${CMAKE_COMMAND} -E env
                "SignArch=${_sign_arch}"
                "SignArchAlt=${_sign_arch_alt}"
                cmd /c "\"${MSI_DIR}/sign-openvpn.bat\""
            WORKING_DIRECTORY "${MSI_DIR}"
            COMMENT "Signing openvpn binaries (${_arch})"
            DEPENDS openvpn_core_${_arch} openvpn_gui_${_arch}
        )
    endforeach()
endif()

# ============================================================
# Helper: download a file if it doesn't already exist
# ============================================================

function(download_file url dest)
    if(NOT EXISTS "${dest}")
        message(STATUS "Downloading ${url}")
        file(DOWNLOAD "${url}" "${dest}"
            STATUS _dl_status
        )
        list(GET _dl_status 0 _dl_code)
        if(NOT _dl_code EQUAL 0)
            file(REMOVE "${dest}")
            message(FATAL_ERROR "Failed to download ${url}: ${_dl_status}")
        endif()
    endif()
endfunction()

# ============================================================
# Download openvpnserv2.exe
# ============================================================

set(OPENVPNSERV2_FILE "${BUILD_DIR}/openvpnserv2.exe")
download_file(
    "https://github.com/OpenVPN/openvpnserv2/releases/download/${OVPNSERV2_VERSION}/openvpnserv2-${OVPNSERV2_VERSION}-signed.exe"
    "${OPENVPNSERV2_FILE}"
)

# ============================================================
# Download and extract Easy-RSA
# ============================================================

set(EASYRSA_ZIP "${SOURCE_DIR}/easyrsa-${EASYRSA_VERSION}.zip")
set(EASYRSA_DIR "${BUILD_DIR}/easyrsa-${EASYRSA_VERSION}")

download_file(
    "https://github.com/OpenVPN/easy-rsa/releases/download/v${EASYRSA_VERSION}/EasyRSA-${EASYRSA_VERSION}-win64.zip"
    "${EASYRSA_ZIP}"
)

if(NOT EXISTS "${EASYRSA_DIR}/easyrsa")
    message(STATUS "Extracting Easy-RSA...")
    file(ARCHIVE_EXTRACT INPUT "${EASYRSA_ZIP}" DESTINATION "${BUILD_DIR}")
    # Easy-RSA zip extracts to EasyRSA-<version>; rename to our convention
    if(EXISTS "${BUILD_DIR}/EasyRSA-${EASYRSA_VERSION}" AND NOT EXISTS "${EASYRSA_DIR}")
        file(RENAME "${BUILD_DIR}/EasyRSA-${EASYRSA_VERSION}" "${EASYRSA_DIR}")
    endif()
endif()

# Generate EasyRSA-Start.bat
file(WRITE "${EASYRSA_DIR}/EasyRSA-Start.bat"
"@echo OFF\r
rem Automatically set PATH to openssl.exe\r
FOR /F \"tokens=2*\" %%a IN ('REG QUERY \"HKEY_LOCAL_MACHINE\\SOFTWARE\\OpenVPN\" /v bin_dir') DO set \"PATH=%PATH%;%%b\"\r
bin\\sh.exe bin\\easyrsa-shell-init.sh %*\r
")

# ============================================================
# Download TAP-Windows6 and ovpn-dco (per architecture)
# ============================================================

foreach(_arch ${ARCHITECTURES})
    set(_tap_plat "${TAP_PLAT_${_arch}}")

    download_file(
        "https://github.com/OpenVPN/tap-windows6/releases/download/${PRODUCT_TAP_WIN_VERSION}/tap-windows-${PRODUCT_TAP_WIN_VERSION}-${PRODUCT_TAP_WIN_INSTALLER_VERSION}-${_tap_plat}.msm"
        "${BUILD_DIR}/${_arch}/tap-windows6.msm"
    )

    download_file(
        "https://github.com/OpenVPN/ovpn-dco-win/releases/download/${PRODUCT_OVPN_DCO_VERSION}/ovpn-dco-${_arch}.msm"
        "${BUILD_DIR}/${_arch}/ovpn-dco.msm"
    )
endforeach()

# ============================================================
# Preprocess documentation templates (@VAR@ -> value)
# ============================================================

# Preprocess documentation templates (@VAR@ -> value, CRLF line endings)
set(_doc_templates INSTALL-win32 README-config README-config-auto README-log)
foreach(_doc ${_doc_templates})
    configure_file(
        "${MSI_DIR}/doc/${_doc}.txt.in"
        "${BUILD_DIR}/${_doc}.txt"
        @ONLY
        NEWLINE_STYLE CRLF
    )
endforeach()

# ============================================================
# Generate license.txt and sample configs (per architecture)
# ============================================================

foreach(_arch ${ARCHITECTURES})
    set(_arch_build "${BUILD_DIR}/${_arch}")

    # license.txt: concatenation of COPYING + COPYRIGHT.GPL + bundled-licenses.txt
    set(_license_parts
        "${DEPS_DIR}/openvpn/COPYING"
        "${DEPS_DIR}/openvpn/COPYRIGHT.GPL"
        "${MSI_DIR}/doc/bundled-licenses.txt"
    )

    add_custom_command(
        OUTPUT "${_arch_build}/license.txt"
        COMMAND ${CMAKE_COMMAND}
            "-DOUTPUT=${_arch_build}/license.txt"
            "-DINPUTS=${_license_parts}"
            -P "${MSI_DIR}/concat_files.cmake"
        DEPENDS ${_license_parts}
        COMMENT "Generating license.txt (${_arch})"
    )

    # Sample config files (copy with CRLF line endings)
    foreach(_config client server)
        add_custom_command(
            OUTPUT "${_arch_build}/${_config}.ovpn"
            COMMAND ${CMAKE_COMMAND}
                -DINPUT="${DEPS_DIR}/openvpn/sample/sample-config-files/${_config}.conf"
                -DOUTPUT="${_arch_build}/${_config}.ovpn"
                -P "${MSI_DIR}/convert_to_crlf.cmake"
            DEPENDS "${DEPS_DIR}/openvpn/sample/sample-config-files/${_config}.conf"
            COMMENT "Copying ${_config}.ovpn (${_arch}) with CRLF line endings"
        )
    endforeach()
endforeach()

# ============================================================
# WiX compilation and linking (per architecture)
# ============================================================

foreach(_arch ${ARCHITECTURES})
    set(_arch_build "${BUILD_DIR}/${_arch}")
    set(_wix_plat "${WIX_PLAT_${_arch}}")
    set(_openssl_plat "${OPENSSL_PLAT_${_arch}}")
    set(_vcpkg_triplet "${VCPKG_TRIPLET_${_arch}}")

    # WiX compiler define flags
    set(_wix_defines
        -dPRODUCT_PUBLISHER="${PRODUCT_PUBLISHER}"
        -dPRODUCT_NAME="${PRODUCT_NAME}"
        -dPRODUCT_VERSION="${PRODUCT_VERSION}"
        -dPACKAGE_VERSION="${PACKAGE_VERSION}"
        -dPRODUCT_TAP_WIN_NAME="${PRODUCT_TAP_WIN_NAME}"
        -dPRODUCT_TAP_WIN_COMPONENT_ID="${PRODUCT_TAP_WIN_COMPONENT_ID}"
        -dPRODUCT_PLATFORM="${_arch}"
        -dPRODUCT_CODE="${PRODUCT_CODE}"
        -dUPGRADE_CODE="${UPGRADE_CODE_${_arch}}"
        -dCONFIG_EXTENSION="${CONFIG_EXTENSION}"
        -dPROGRAM_FILES_DIR="${PROGRAM_FILES_DIR_${_arch}}"
        -dOPENSSL_PLAT="${_openssl_plat}"
    )

    # Common WiX compiler flags
    set(_wix_candle_flags
        -nologo
        -ext WixNetFxExtension
        -ext WixUtilExtension
        -arch "${_wix_plat}"
        ${_wix_defines}
    )

    # Compile gui.wxs
    add_custom_command(
        OUTPUT "${_arch_build}/gui.wixobj"
        COMMAND "${WIX_CANDLE}" ${_wix_candle_flags}
            -out "${_arch_build}/gui.wixobj"
            "${MSI_DIR}/gui.wxs"
        DEPENDS "${MSI_DIR}/gui.wxs" "${MSI_DIR}/version.cmake"
        COMMENT "WiX compiling gui.wxs (${_arch})"
    )

    # Compile msi.wxs
    add_custom_command(
        OUTPUT "${_arch_build}/msi.wixobj"
        COMMAND "${WIX_CANDLE}" ${_wix_candle_flags}
            -out "${_arch_build}/msi.wixobj"
            "${MSI_DIR}/msi.wxs"
        DEPENDS "${MSI_DIR}/msi.wxs" "${MSI_DIR}/version.cmake"
        COMMENT "WiX compiling msi.wxs (${_arch})"
    )

    # WiX linker flags
    set(_wix_light_flags
        -nologo
        -dcl:high
        -spdb
        -ext WixNetFxExtension
        -ext WixUtilExtension
        -b "${MSI_DIR}"
        -b "build=${BUILD_DIR}"
        -b "openvpndoc=${OPENVPN_DOC_${_arch}}"
        -b "openvpnbin=${OPENVPN_BIN_${_arch}}"
        -b "openvpnmsica=${OPENVPN_MSICA_${_arch}}"
        -b "openvpnserv=${OPENVPN_SERV_${_arch}}"
        -b "openvpntapctl=${OPENVPN_TAPCTL_${_arch}}"
        -b "openvpngui=${OPENVPN_GUI_DIR}"
        -b "openvpnguibin=${OPENVPN_GUI_BIN_${_arch}}"
        -b "openssltools=${OPENSSL_TOOLS_${_arch}}"
        -b "opensslbin=${OPENSSL_BIN_${_arch}}"
        -b "easyrsa=${EASYRSA_DIR}"
        -b "openvpnserv2=${BUILD_DIR}"
    )

    # MSI output file
    set(_msi_file "${OUTPUT_DIR}/${PRODUCT_NAME}-${PACKAGE_VERSION}-${_arch}.msi")

    # Per-architecture MSI target (links WiX objects into MSI)
    add_custom_target(msi_${_arch}
        COMMAND "${WIX_LIGHT}" ${_wix_light_flags}
            -out "${_msi_file}"
            "${_arch_build}/gui.wixobj"
            "${_arch_build}/msi.wixobj"
        DEPENDS
            "${_arch_build}/gui.wixobj"
            "${_arch_build}/msi.wixobj"
            # Generated files
            "${_arch_build}/license.txt"
            "${_arch_build}/client.ovpn"
            "${_arch_build}/server.ovpn"
            # Downloaded files
            "${_arch_build}/tap-windows6.msm"
            "${_arch_build}/ovpn-dco.msm"
            "${OPENVPNSERV2_FILE}"
        COMMENT "WiX linking ${PRODUCT_NAME}-${PACKAGE_VERSION}-${_arch}.msi"
    )

    # Ensure binaries are built (and optionally signed) before linking
    add_dependencies(msi_${_arch} openvpn_core_${_arch} openvpn_gui_${_arch})
    if(SIGN_BINARIES)
        add_dependencies(msi_${_arch} sign_openvpn_${_arch})
    endif()
endforeach()

# ============================================================
# Sign MSI packages (optional)
# ============================================================

if(SIGN_BINARIES)
    set(_all_msi_targets "")
    foreach(_arch ${ARCHITECTURES})
        list(APPEND _all_msi_targets msi_${_arch})
    endforeach()

    add_custom_target(sign_msi
        COMMAND cmd /c "${MSI_DIR}/sign-msi.bat"
        WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}"
        COMMENT "Signing MSI packages"
        DEPENDS ${_all_msi_targets}
    )
endif()

# ============================================================
# Top-level targets
# ============================================================

# "msi" target builds all architecture MSIs
set(_all_msi_targets "")
foreach(_arch ${ARCHITECTURES})
    list(APPEND _all_msi_targets msi_${_arch})
endforeach()

add_custom_target(msi DEPENDS ${_all_msi_targets})

# Default target
if(SIGN_BINARIES)
    add_custom_target(package ALL DEPENDS sign_msi)
else()
    add_custom_target(package ALL DEPENDS msi)
endif()

# ============================================================
# Clean target
# ============================================================

set_property(DIRECTORY APPEND PROPERTY ADDITIONAL_CLEAN_FILES
    "${BUILD_DIR}"
    "${SOURCE_DIR}"
    "${OUTPUT_DIR}"
)

# ============================================================
# Status summary
# ============================================================

message(STATUS "")
message(STATUS "=== OpenVPN MSI Build Configuration ===")
message(STATUS "  Product:        ${PRODUCT_NAME} ${PACKAGE_VERSION}")
message(STATUS "  Version:        ${PRODUCT_VERSION}")
message(STATUS "  Architectures:  ${ARCHITECTURES}")
message(STATUS "  Sign binaries:  ${SIGN_BINARIES}")
message(STATUS "  TAP-Windows:    ${PRODUCT_TAP_WIN_VERSION}")
message(STATUS "  ovpn-dco:       ${PRODUCT_OVPN_DCO_VERSION}")
message(STATUS "  Easy-RSA:       ${EASYRSA_VERSION}")
message(STATUS "  openvpnserv2:   ${OVPNSERV2_VERSION}")
message(STATUS "  WiX candle:     ${WIX_CANDLE}")
message(STATUS "  WiX light:      ${WIX_LIGHT}")
message(STATUS "  Output:         ${OUTPUT_DIR}")
message(STATUS "=======================================")
