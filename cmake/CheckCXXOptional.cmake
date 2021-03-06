cmake_minimum_required(VERSION 3.12)
function(check_optional_compiles)
    include(CheckCXXSourceCompiles)
    if(MSVC)
        set(CMAKE_REQUIRED_FLAGS     "/std:c++17")
    else()
        set(CMAKE_REQUIRED_FLAGS     "-std=c++17")
    endif()
    check_cxx_source_compiles("
        // Include optional or experimental/optional
        namespace h5pp{}
        #if __has_include(<optional>)
        #include <optional>
        #elif __has_include(<experimental/optional>)
        #include <experimental/optional>
        namespace h5pp{
            namespace std{
                constexpr const std::experimental::nullopt_t &nullopt = std::experimental::nullopt ;
                template<typename T> using std::optional = std::experimental::optional<T>;
            }
        }
        #else
            #error Could not find <optional> or <experimental/optional>
        #endif


        int main(){
            using namespace h5pp;
            std::optional<int> optVar = std::nullopt;
            return 0;
        }
        " OPTIONAL_COMPILES)
    set(OPTIONAL_COMPILES ${OPTIONAL_COMPILES} PARENT_SCOPE)
endfunction()

function(CheckCXXOptional)
    cmake_policy(SET CMP0075 NEW)
    include(CheckIncludeFileCXX)
    check_optional_compiles()
    if(NOT OPTIONAL_COMPILES)
        check_include_file_cxx(optional    has_optional)
        check_include_file_cxx(experimental/optional has_experimental_optional )
        if(NOT has_optional AND NOT has_experimental_optional)
            message(WARNING "
                Missing <optional> and/or <experimental/optional> headers.\n\
                Consider using a newer compiler (GCC 6 or above, Clang 5 or above),\n\
                or checking the compiler flags. If using Clang, pass the variable \n\
                GCC_TOOLCHAIN=<path> \n\
                where path is the install directory of a recent GCC.
        ")
        endif()
        message(FATAL_ERROR "Unable to compile with <optional> or <experimental/optional> headers")
    endif()



endfunction()