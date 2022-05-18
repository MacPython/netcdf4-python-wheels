# Define custom utilities
# Test for OSX with [ -n "$IS_OSX" ]
# Uncomment to disable net tests - the server is sometimes down
export NO_NET=1
# ncdump/ncgen not installed in wheel, so tst_cdl.py fails
export NO_CDL=1

# Compile libs for macOS 10.9 or later
export MACOSX_DEPLOYMENT_TARGET="10.9"
export NETCDF_VERSION="4.8.1"
export HDF5_VERSION="1.12.1"
# old openssl, since building new version requires perl 5.10.0
export OPENSSL_ROOT=openssl-1.0.2u
export OPENSSL_HASH=ecd0c6ffb493dd06707d38b14bb4d8c2288bb7033735606569d8f90f89669d16
export CURL_VERSION="7.75.0"
export=LIBAEC_VERSION="1.0.6"


function build_curl2 {
    if [ -e curl-stamp ]; then return; fi
    local flags="--prefix=$BUILD_PREFIX"
    if [ -n "$IS_MACOS" ]; then
        flags="$flags --with-darwinssl"
    else  # manylinux
        flags="$flags --with-ssl"
        build_openssl
    fi
    flags="$flags --without-brotli --without-nghttp2 --without-zstd --without-librtmp --without-libidn2"
    fetch_unpack https://curl.haxx.se/download/curl-${CURL_VERSION}.tar.gz
    (cd curl-${CURL_VERSION} \
        && if [ -z "$IS_MACOS" ]; then \
        LIBS=-ldl ./configure $flags; else \
        ./configure $flags; fi\
        && make -j4 \
        && make install)
    touch curl-stamp
}

function build_libaec {
    if [ -e libaec-stamp ]; then return; fi
    local root_name=v${LIBAEC_VERSION}
    local tar_name=libaec-${root_name}.tar.gz
    fetch_unpack https://gitlab.dkrz.de/k202009/libaec/-/archive/${root_name}/${tar_name}
    (cd libaec-${root_name} \
        && ./configure --prefix=$BUILD_PREFIX \
        && make \
        && make install)
    touch libaec-stamp
}

function build_hdf5 {
    if [ -e hdf5-stamp ]; then return; fi
    build_zlib
    # libaec is a drop-in replacement for szip
    build_libaec
    local hdf5_url=https://support.hdfgroup.org/ftp/HDF5/releases
    local short=$(echo $HDF5_VERSION | awk -F "." '{printf "%d.%d", $1, $2}')
    fetch_unpack $hdf5_url/hdf5-$short/hdf5-$HDF5_VERSION/src/hdf5-$HDF5_VERSION.tar.gz
    
    if [[ ! -z "IS_OSX"  && "$PLAT" = "arm64" ]] && [[ "$CROSS_COMPILING" = "1" ]]; then
    cd hdf5-$HDF5_VERSION
    # from https://github.com/conda-forge/hdf5-feedstock/commit/2cb83b63965985fa8795b0a13150bf0fd2525ebd
    export ac_cv_sizeof_long_double=8
    export hdf5_cv_ldouble_to_long_special=no
    export hdf5_cv_long_to_ldouble_special=no
    export hdf5_cv_ldouble_to_llong_accurate=yes
    export hdf5_cv_llong_to_ldouble_correct=yes
    export hdf5_cv_disable_some_ldouble_conv=no
    export hdf5_cv_system_scope_threads=yes
    export hdf5_cv_printf_ll="l"
    export PAC_FC_MAX_REAL_PRECISION=15
    export PAC_C_MAX_REAL_PRECISION=17
    export PAC_FC_ALL_INTEGER_KINDS="{1,2,4,8,16}"
    export PAC_FC_ALL_REAL_KINDS="{4,8}"
    export H5CONFIG_F_NUM_RKIND="INTEGER, PARAMETER :: num_rkinds = 2"
    export H5CONFIG_F_NUM_IKIND="INTEGER, PARAMETER :: num_ikinds = 5"
    export H5CONFIG_F_RKIND="INTEGER, DIMENSION(1:num_rkinds) :: rkind = (/4,8/)"
    export H5CONFIG_F_IKIND="INTEGER, DIMENSION(1:num_ikinds) :: ikind = (/1,2,4,8,16/)"
    export PAC_FORTRAN_NATIVE_INTEGER_SIZEOF="                    4"
    export PAC_FORTRAN_NATIVE_INTEGER_KIND="           4"
    export PAC_FORTRAN_NATIVE_REAL_SIZEOF="                    4"
    export PAC_FORTRAN_NATIVE_REAL_KIND="           4"
    export PAC_FORTRAN_NATIVE_DOUBLE_SIZEOF="                    8"
    export PAC_FORTRAN_NATIVE_DOUBLE_KIND="           8"
    export PAC_FORTRAN_NUM_INTEGER_KINDS="5"
    export PAC_FC_ALL_REAL_KINDS_SIZEOF="{4,8}"
    export PAC_FC_ALL_INTEGER_KINDS_SIZEOF="{1,2,4,8,16}"
    curl -sLO https://github.com/conda-forge/hdf5-feedstock/raw/2cb83b63965985fa8795b0a13150bf0fd2525ebd/recipe/patches/osx_cross_configure.patch
    curl -sLO https://github.com/conda-forge/hdf5-feedstock/raw/2cb83b63965985fa8795b0a13150bf0fd2525ebd/recipe/patches/osx_cross_fortran_src_makefile.patch
    curl -sLO https://github.com/conda-forge/hdf5-feedstock/raw/2cb83b63965985fa8795b0a13150bf0fd2525ebd/recipe/patches/osx_cross_hl_fortran_src_makefile.patch
    curl -sLO https://github.com/conda-forge/hdf5-feedstock/raw/2cb83b63965985fa8795b0a13150bf0fd2525ebd/recipe/patches/osx_cross_src_makefile.patch
    patch -p0 < osx_cross_configure.patch
    patch -p0 < osx_cross_fortran_src_makefile.patch
    patch -p0 < osx_cross_hl_fortran_src_makefile.patch
    patch -p0 < osx_cross_src_makefile.patch
    export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$BUILD_PREFIX/lib 
    #if [ -n "$IS_MACOS" ] && []; then
    #./configure --without-szlib --prefix=$BUILD_PREFIX --enable-threadsafe --enable-unsupported --with-pthread=yes --enable-build-mode=production  --host=aarch64-apple-darwin --enable-tests=no
    #else
    ./configure --with-szlib=$BUILD_PREFIX --prefix=$BUILD_PREFIX --enable-threadsafe --enable-unsupported --with-pthread=yes --enable-build-mode=production  --host=aarch64-apple-darwin --enable-tests=no
    #fi
    mkdir -p native-build/bin
    cd native-build/bin
    pwd
    clang ../../src/H5detect.c -I ../../src/ -o H5detect
    clang ../../src/H5make_libsettings.c -I ../../src/ -o H5make_libsettings
    ls -l
    cd ../..
    export PATH=$(pwd)/native-build/bin:$PATH
    make -j4
    make install
    cd ..
    touch hdf5-stamp
    else
    (cd hdf5-$HDF5_VERSION \
        && export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$BUILD_PREFIX/lib \
        && ./configure --with-szlib=$BUILD_PREFIX --prefix=$BUILD_PREFIX \
        --enable-threadsafe --enable-unsupported --with-pthread=yes \
        && make -j4 \
        && make install)
    touch hdf5-stamp
    fi
}

function build_libs {
    build_hdf5
    build_curl2
    if [ -z "$IS_OSX" ] && [ $MB_ML_VER -eq 1 ]; then
       export CFLAGS="-std=gnu99 -Wl,-strip-all"
    fi
    build_netcdf
}

function pre_build {
    # Any stuff that you need to do before you start building the wheels
    # Runs in the root directory of this repository.
    build_libs
}

function run_tests {
    # Runs tests on installed distribution from an empty directory
    pwd
    echo $PATH
    ls -l /usr/local/lib
    which python
    cp ../netcdf4-python/test/* .
    python run_all.py
}

