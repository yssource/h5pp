

find_package(spdlog NO_DEFAULT_PATH HINTS ${INSTALL_DIRECTORY_THIRD_PARTY}/spdlog/lib/cmake/spdlog ${spdlog_DIR} )

if(spdlog_FOUND)
    message(STATUS "SPDLOG FOUND IN SYSTEM: ${spdlog_DIR}")
    add_library(spdlog INTERFACE)
    target_link_libraries(spdlog INTERFACE spdlog::spdlog)
elseif (DOWNLOAD_SPDLOG OR DOWNLOAD_ALL)
    message(STATUS "Spdlog will be installed into ${INSTALL_DIRECTORY_THIRD_PARTY}/spdlog on first build.")
    include(ExternalProject)
    ExternalProject_Add(external_SPDLOG
            GIT_REPOSITORY https://github.com/gabime/spdlog.git
            GIT_TAG v1.x
            GIT_PROGRESS 1
            UPDATE_COMMAND ""
            TEST_COMMAND ""
            PREFIX      ${BUILD_DIRECTORY_THIRD_PARTY}/spdlog
            INSTALL_DIR ${INSTALL_DIRECTORY_THIRD_PARTY}/spdlog
            CMAKE_ARGS
            -DCMAKE_INSTALL_PREFIX:PATH=<INSTALL_DIR>
            )


    ExternalProject_Get_Property(external_SPDLOG INSTALL_DIR)
    add_library(spdlog INTERFACE)
    add_library(spdlog::spdlog ALIAS spdlog)
    set(spdlog_DIR ${INSTALL_DIR}/lib/cmake/spdlog)
    set(spdlog_ROOT ${INSTALL_DIR})
    add_dependencies(spdlog external_SPDLOG)

    target_include_directories(
            spdlog
            INTERFACE
            $<BUILD_INTERFACE:${INSTALL_DIR}/include>
            $<INSTALL_INTERFACE:third-party/spdlog/include>
    )
else()
    message("WARNING: Dependency spdlog not found and DOWNLOAD_SPDLOG is OFF. Build will fail.")

endif()