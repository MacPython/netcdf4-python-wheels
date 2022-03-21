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

#source h5py-wheels/config.sh

# copied from h5py-wheels/config.sh

#function build_wheel {
#    if [ -z "$IS_OSX" ]; then
#        build_linux_wheel $@
#    else
#        build_osx_wheel $@
#    fi
#}

#function build_linux_wheel {
#    source multibuild/library_builders.sh
#    build_libs
#    # Add workaround for auditwheel bug:
#    # https://github.com/pypa/auditwheel/issues/29
#    local bad_lib="/usr/local/lib/libhdf5.so"
#    if [ -z "$(readelf --dynamic $bad_lib | grep RUNPATH)" ]; then
#        patchelf --set-rpath $(dirname $bad_lib) $bad_lib
#    fi
#    build_pip_wheel $@
#}

#function build_osx_wheel {
#    local repo_dir=${1:-$REPO_DIR}
#    export CC=clang
#    export CXX=clang++
#    install_pkg_config
#    # Build libraries
#    source multibuild/library_builders.sh
#    export ARCH_FLAGS="-arch x86_64"
#    export CFLAGS=$ARCH_FLAGS
#    export CXXFLAGS=$ARCH_FLAGS
#    export FFLAGS=$ARCH_FLAGS
#    export LDFLAGS=$ARCH_FLAGS
#    build_libs
#    # Build wheel
#    export LDFLAGS="$ARCH_FLAGS -Wall -undefined dynamic_lookup -bundle"
#    export LDSHARED="$CC $LDFLAGS"
#    build_pip_wheel "$repo_dir"
#}

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

