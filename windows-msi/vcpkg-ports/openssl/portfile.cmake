if(EXISTS "${CURRENT_INSTALLED_DIR}/include/openssl/ssl.h")
    message(FATAL_ERROR "Can't build openssl if libressl/boringssl is installed. Please remove libressl/boringssl, and try install openssl again if you need it.")
endif()

set(OPENSSL_VERSION 1.1.1t)
vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO openssl/openssl
    REF "OpenSSL_1_1_1t"
    SHA512 f28a323fd78be0b16ae6db9a8f163e64c74410e12ddd1a9836dfdda34c264112184f4e22583c84b6fa56716e5aaac9cb860cb183bd3d0cb064091eea1e21815e
    PATCHES
        windows/umul128-arm64.patch # Fixed upstream in https://github.com/openssl/openssl/pull/20244
)

vcpkg_find_acquire_program(PERL)
get_filename_component(PERL_EXE_PATH ${PERL} DIRECTORY)
vcpkg_add_to_path("${PERL_EXE_PATH}")

if(VCPKG_TARGET_IS_UWP)
    include("${CMAKE_CURRENT_LIST_DIR}/uwp/portfile.cmake")
    include("${CMAKE_CURRENT_LIST_DIR}/install-pc-files.cmake")
elseif(VCPKG_TARGET_IS_WINDOWS AND NOT VCPKG_TARGET_IS_MINGW)
    include("${CMAKE_CURRENT_LIST_DIR}/windows/portfile.cmake")
    include("${CMAKE_CURRENT_LIST_DIR}/install-pc-files.cmake")
else()
    include("${CMAKE_CURRENT_LIST_DIR}/unix/portfile.cmake")
endif()

configure_file("${CMAKE_CURRENT_LIST_DIR}/vcpkg-cmake-wrapper.cmake.in" "${CURRENT_PACKAGES_DIR}/share/${PORT}/vcpkg-cmake-wrapper.cmake" @ONLY)
file(INSTALL "${CMAKE_CURRENT_LIST_DIR}/usage" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}")
