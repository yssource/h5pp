# This sets the following variables

# FMT_INCLUDE_DIR
# FMT_VERSION
# fmt_FOUND

# as well as a target fmt::fmt
#
# To guide the find behavior the user can set the following variables to TRUE/FALSE:

# FMT_NO_CMAKE_PACKAGE_REGISTRY
# FMT_NO_DEFAULT_PATH
# FMT_NO_CONFIG
# FMT_CONFIG_ONLY

# The user can set search directory hints from CMake or environment, such as
# FMT_DIR, fmt_DIR, FMT_ROOT fmt_ROOT, etc.

if(NOT fmt_FIND_VERSION)
    if(NOT fmt_FIND_VERSION_MAJOR)
        set(fmt_FIND_VERSION_MAJOR 5)
    endif()
    if(NOT fmt_FIND_VERSION_MINOR)
        set(fmt_FIND_VERSION_MINOR 0)
    endif()
    if(NOT fmt_FIND_VERSION_PATCH)
        set(fmt_FIND_VERSION_PATCH 0)
    endif()
    set(fmt_FIND_VERSION "${fmt_FIND_VERSION_MAJOR}.${fmt_FIND_VERSION_MINOR}.${fmt_FIND_VERSION_PATCH}")
endif()

function(fmt_check_version var)
    if (${var} AND EXISTS ${${var}})
        set(include ${${var}})
    endif()
    if(EXISTS ${include}/fmt/core.h)
        set(_fmt_version_file "${include}/fmt/core.h")
    elseif(EXISTS ${include}/fmt/bundled/core.h)
        set(_fmt_version_file "${include}/fmt/bundled/core.h")
    endif()
    if(EXISTS ${_fmt_version_file})
        # parse "#define FMT_VERSION 40100" to 4.1.0
        file(STRINGS "${_fmt_version_file}" FMT_VERSION_LINE
                REGEX "^#define[ \t]+FMT_VERSION[ \t]+[0-9]+$")
        string(REGEX REPLACE "^#define[ \t]+FMT_VERSION[ \t]+([0-9]+)$"
                "\\1" FMT_VERSION "${FMT_VERSION_LINE}")
        foreach(ver "FMT_VERSION_PATCH" "FMT_VERSION_MINOR" "FMT_VERSION_MAJOR")
            math(EXPR ${ver} "${FMT_VERSION} % 100")
            math(EXPR FMT_VERSION "(${FMT_VERSION} - ${${ver}}) / 100")
        endforeach()
        set(FMT_VERSION "${FMT_VERSION_MAJOR}.${FMT_VERSION_MINOR}.${FMT_VERSION_PATCH}")
        if(${FMT_VERSION} VERSION_LESS ${fmt_FIND_VERSION})
            set(FMT_VERSION_OK FALSE)
        else()
            set(FMT_VERSION_OK TRUE)
        endif()
        set(FMT_VERSION      ${FMT_VERSION}       PARENT_SCOPE)
        set(FMT_VERSION_OK   ${FMT_VERSION_OK}    PARENT_SCOPE)
    else()
        set(FMT_VERSION_OK FALSE PARENT_SCOPE)
    endif()
endfunction()

if(FMT_NO_DEFAULT_PATH)
    set(NO_DEFAULT_PATH NO_DEFAULT_PATH)
endif()

if(FMT_NO_CMAKE_PACKAGE_REGISTRY)
    set(NO_CMAKE_PACKAGE_REGISTRY NO_CMAKE_PACKAGE_REGISTRY)
endif()


# First try finding a config somewhere in the system
if(NOT FMT_NO_CONFIG OR FMT_CONFIG_ONLY)
    find_package(fmt ${fmt_FIND_VERSION}
            HINTS  ${fmt_ROOT} ${CONAN_FMT_ROOT} ${CMAKE_INSTALL_PREFIX}
            PATH_SUFFIXES include fmt include/fmt fmt/include/fmt
            ${NO_DEFAULT_PATH}
            ${NO_CMAKE_PACKAGE_REGISTRY}
            ${NO_CMAKE_SYSTEM_PATH}
            ${NO_SYSTEM_ENVIRONMENT_PATH}
            CONFIG QUIET
            )
    if(TARGET fmt::fmt)
        get_target_property(FMT_INCLUDE_DIR fmt::fmt INTERFACE_INCLUDE_DIRECTORIES)
        fmt_check_version(FMT_INCLUDE_DIR)
        if(NOT FMT_VERSION_OK OR NOT FMT_VERSION)
            message(WARNING "Could not determine the version of fmt.\n"
                    "However, the target fmt::fmt has already been defined, so it will be used:\n"
                    "FMT_INCLUDE_DIR: ${FMT_INCLUDE_DIR}\n"
                    "FMT_VERSION:     ${FMT_VERSION}\n"
                    "Something is wrong with your installation of fmt")
        endif()

        if(FMT_INCLUDE_DIR MATCHES "conda")
            # Use the header-only mode to avoid weird linking errors
            target_compile_definitions(fmt::fmt INTERFACE FMT_HEADER_ONLY)
        endif()
    endif()
endif()

if(NOT TARGET fmt::fmt AND NOT FMT_CONFIG_ONLY)
    find_path(FMT_INCLUDE_DIR
            fmt/fmt.h
            HINTS ${fmt_ROOT} ${FMT_INCLUDE_DIR} ${H5PP_CONDA_CANDIDATE_PATHS}
            PATH_SUFFIXES fmt fmt/include include include/fmt
            ${NO_DEFAULT_PATH}
            ${NO_CMAKE_PACKAGE_REGISTRY}
            ${NO_CMAKE_SYSTEM_PATH}
            ${NO_SYSTEM_ENVIRONMENT_PATH}
            )
    if(FMT_INCLUDE_DIR)
        fmt_check_version(FMT_INCLUDE_DIR)
        # Check if there is a compiled library to go with the headers
        find_library(FMT_LIBRARY
                NAMES fmt
                HINTS ${fmt_ROOT} ${CMAKE_INSTALL_PREFIX}
                PATHS ${H5PP_CONDA_CANDIDATE_PATHS}
                PATH_SUFFIXES fmt fmt/lib lib/fmt fmt/${CMAKE_INSTALL_LIBDIR} spdlog/${CMAKE_INSTALL_LIBDIR}  ${CMAKE_INSTALL_LIBDIR}
                ${NO_DEFAULT_PATH}
                ${NO_CMAKE_PACKAGE_REGISTRY}
                ${NO_CMAKE_SYSTEM_PATH}
                ${NO_SYSTEM_ENVIRONMENT_PATH}
                )
    else()
        # Check if fmt has been bundled with spdlog, in which case we use it as header-only
        find_path(SPDLOG_FMT_BUNDLED
                spdlog/fmt/fmt.h
                HINTS ${SPDLOG_INCLUDE_DIR} ${spdlog_ROOT} ${CONAN_SPDLOG_ROOT} ${CMAKE_INSTALL_PREFIX}
                PATH_SUFFIXES spdlog/include include spdlog include/spdlog spdlog/include/spdlog
                ${NO_DEFAULT_PATH}
                ${NO_CMAKE_PACKAGE_REGISTRY}
                )
        fmt_check_version(SPDLOG_FMT_BUNDLED)
    endif()

    if(FMT_VERSION_OK)
        if(FMT_INCLUDE_DIR)
            add_library(fmt::fmt INTERFACE IMPORTED)
            target_include_directories(fmt::fmt SYSTEM INTERFACE ${FMT_INCLUDE_DIR})
            if(FMT_LIBRARY AND NOT FMT_LIBRARY MATCHES "conda")
                set_target_properties(fmt::fmt PROPERTIES IMPORTED_LOCATION ${FMT_LIBRARY})
            else()
                target_compile_definitions(fmt::fmt INTERFACE FMT_HEADER_ONLY)
            endif()
        elseif(SPDLOG_FMT_BUNDLED)
            add_library(fmt::fmt INTERFACE IMPORTED)
            target_include_directories(fmt::fmt SYSTEM INTERFACE ${SPDLOG_FMT_BUNDLED})
            target_compile_definitions(fmt::fmt INTERFACE FMT_HEADER_ONLY)
        endif()
    endif()
endif()

if(TARGET fmt::fmt)
    set(fmt_FOUND TRUE)
endif()


include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(fmt
        FOUND_VAR fmt_FOUND
        REQUIRED_VARS FMT_INCLUDE_DIR FMT_VERSION_OK
        VERSION_VAR FMT_VERSION
        FAIL_MESSAGE "Failed to find fmt"
        )

mark_as_advanced(FMT_INCLUDE_DIR)
mark_as_advanced(FMT_LIBRARY)
mark_as_advanced(FMT_VERSION)
mark_as_advanced(FMT_VERSION_OK)
mark_as_advanced(fmt_FOUND)
mark_as_advanced(_fmt_version_file)
