

if(H5PP_DOWNLOAD_METHOD MATCHES "conan")
    ##################################################################
    ### Install conan-modules/conanfile.txt dependencies          ###
    ### This uses conan to get spdlog/eigen3/h5pp/ceres           ###
    ###    eigen/3.3.7@conan/stable                               ###
    ###    spdlog/1.4.2@bincrafters/stable                        ###
    ###    hdf5/1.10.5                                            ###
    ##################################################################

    # Check which packages to get with conan
    if(H5PP_DOWNLOAD_METHOD MATCHES "find|fetch|native")
        if(NOT TARGET hdf5::hdf5)
            list(APPEND CONAN_REQUIRES REQUIRES hdf5/1.10.5)
        endif()
        if(H5PP_ENABLE_SPDLOG AND NOT TARGET spdlog::spdlog)
            list(APPEND CONAN_REQUIRES REQUIRES spdlog/1.4.2@bincrafters/stable)
        endif()
        if(H5PP_ENABLE_EIGEN3 AND NOT TARGET Eigen3::Eigen)
            list(APPEND CONAN_REQUIRES REQUIRES eigen/3.3.7@conan/stable)
        endif()
    else()
        list(APPEND CONAN_REQUIRES CONANFILE conanfile.txt)
    endif()



    find_program (
            CONAN_COMMAND
            conan
            HINTS ${CONAN_PREFIX} ${CONDA_PREFIX} $ENV{CONAN_PREFIX} $ENV{CONDA_PREFIX}
            PATHS $ENV{HOME}/anaconda3 $ENV{HOME}/miniconda $ENV{HOME}/.conda
            PATH_SUFFIXES bin envs/dmrg/bin
    )


    # Download automatically, you can also just copy the conan.cmake file
    if(NOT EXISTS "${CMAKE_BINARY_DIR}/conan.cmake")
        message(STATUS "Downloading conan.cmake from https://github.com/conan-io/cmake-conan")
        file(DOWNLOAD "https://github.com/conan-io/cmake-conan/raw/v0.14/conan.cmake"
                "${CMAKE_BINARY_DIR}/conan.cmake")
    endif()

    include(${CMAKE_BINARY_DIR}/conan.cmake)

    if(CMAKE_CXX_COMPILER_ID MATCHES "AppleClang")
        # Let it autodetect libcxx
    elseif(CMAKE_CXX_COMPILER_ID MATCHES "MSVC")
        # There is no libcxx
    elseif(CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
        list(APPEND conan_libcxx compiler.libcxx=libstdc++11)
    endif()

    conan_cmake_run(
            ${CONAN_REQUIRES}
            CONAN_COMMAND ${CONAN_COMMAND}
            SETTINGS compiler.cppstd=17
            SETTINGS "${conan_libcxx}"
            BUILD_TYPE ${CMAKE_BUILD_TYPE}
            BASIC_SETUP CMAKE_TARGETS
            BUILD missing)

    message(STATUS "CONAN TARGETS: ${CONAN_TARGETS}")
    list(APPEND H5PP_POSSIBLE_TARGET_NAMES CONAN_PKG::HDF5 CONAN_PKG::hdf5 CONAN_PKG::Eigen3 CONAN_PKG::eigen CONAN_PKG::spdlog)

    foreach(tgt ${H5PP_POSSIBLE_TARGET_NAMES})
        if(TARGET ${tgt})
            message(STATUS "Dependency found: [${tgt}]")
            get_target_property(${tgt}_INCLUDE_DIR ${tgt} INTERFACE_INCLUDE_DIRECTORIES)
            if(${tgt}_INCLUDE_DIR)
                list(APPEND H5PP_DIRECTORY_HINTS ${tgt}_INCLUDE_DIR)
            endif()
        endif()
    endforeach()

    ##################################################################
    ### Link all the things!                                       ###
    ##################################################################
    list(APPEND H5PP_TARGETS ${CONAN_TARGETS})
    target_link_libraries(deps INTERFACE ${CONAN_TARGETS})


endif()
