#pragma once
#include "h5ppHid.h"
#include <complex>
#include <hdf5.h>
namespace h5pp::Type::Compound {

    inline Hid::h5t H5T_COMPLEX_INT;
    inline Hid::h5t H5T_COMPLEX_LONG;
    inline Hid::h5t H5T_COMPLEX_LLONG;
    inline Hid::h5t H5T_COMPLEX_UINT;
    inline Hid::h5t H5T_COMPLEX_ULONG;
    inline Hid::h5t H5T_COMPLEX_ULLONG;
    inline Hid::h5t H5T_COMPLEX_DOUBLE;
    inline Hid::h5t H5T_COMPLEX_FLOAT;
    inline Hid::h5t H5T_SCALAR2_INT;
    inline Hid::h5t H5T_SCALAR2_LONG;
    inline Hid::h5t H5T_SCALAR2_LLONG;
    inline Hid::h5t H5T_SCALAR2_UINT;
    inline Hid::h5t H5T_SCALAR2_ULONG;
    inline Hid::h5t H5T_SCALAR2_ULLONG;
    inline Hid::h5t H5T_SCALAR2_DOUBLE;
    inline Hid::h5t H5T_SCALAR2_FLOAT;
    inline Hid::h5t H5T_SCALAR3_INT;
    inline Hid::h5t H5T_SCALAR3_LONG;
    inline Hid::h5t H5T_SCALAR3_LLONG;
    inline Hid::h5t H5T_SCALAR3_UINT;
    inline Hid::h5t H5T_SCALAR3_ULONG;
    inline Hid::h5t H5T_SCALAR3_ULLONG;
    inline Hid::h5t H5T_SCALAR3_DOUBLE;
    inline Hid::h5t H5T_SCALAR3_FLOAT;

    template<typename T>
    struct H5T_COMPLEX_STRUCT {
        T real, imag; // real,imag parts
        using value_type     = T;
        using Scalar         = T;
        H5T_COMPLEX_STRUCT() = default;
        explicit H5T_COMPLEX_STRUCT(const std::complex<T> &in) {
            real = in.real();
            imag = in.imag();
        }
        H5T_COMPLEX_STRUCT &operator=(const std::complex<T> &rhs) {
            real = rhs.real();
            imag = rhs.imag();
            return *this;
        }
    };

    template<typename T>
    struct H5T_SCALAR2 {
        T x, y;
        using value_type = T;
        using Scalar     = T;
        H5T_SCALAR2()    = default;
        template<typename Scalar2Type>
        explicit H5T_SCALAR2(const Scalar2Type &in) {
            static_assert(std::is_same_v<T, decltype(in.x)>);
            static_assert(std::is_same_v<T, decltype(in.y)>);
            x = in.x;
            y = in.y;
        }
        template<typename Scalar2Type>
        H5T_SCALAR2 &operator=(const Scalar2Type &rhs) {
            static_assert(std::is_same_v<T, decltype(rhs.x)>);
            static_assert(std::is_same_v<T, decltype(rhs.y)>);
            x = rhs.x;
            y = rhs.y;
            return *this;
        }
    };

    template<typename T>
    struct H5T_SCALAR3 {
        T x, y, z;
        using value_type = T;
        using Scalar     = T;
        H5T_SCALAR3()    = default;
        template<typename Scalar3Type>
        explicit H5T_SCALAR3(const Scalar3Type &in) {
            static_assert(std::is_same_v<T, decltype(in.x)>);
            static_assert(std::is_same_v<T, decltype(in.y)>);
            static_assert(std::is_same_v<T, decltype(in.z)>);
            x = in.x;
            y = in.y;
            z = in.z;
        }
        template<typename Scalar3Type>
        H5T_SCALAR3 &operator=(const Scalar3Type &rhs) {
            static_assert(std::is_same_v<T, decltype(rhs.x)>);
            static_assert(std::is_same_v<T, decltype(rhs.y)>);
            static_assert(std::is_same_v<T, decltype(rhs.z)>);
            x = rhs.x;
            y = rhs.y;
            z = rhs.z;
            return *this;
        }
    };

}
