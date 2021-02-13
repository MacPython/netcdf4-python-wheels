# Define custom utilities
# Test for OSX with [ -n "$IS_OSX" ]
# Uncomment to disable net tests - the server is sometimes down
#export NO_NET=1

# Compile libs for macOS 10.9 or later
export MACOSX_DEPLOYMENT_TARGET="10.9"
export NETCDF_VERSION="4.7.4"
export HDF5_VERSION="1.12.0"
# old openssl, since building new version requires perl 5.10.0
export OPENSSL_ROOT=openssl-1.0.2u
export OPENSSL_HASH=ecd0c6ffb493dd06707d38b14bb4d8c2288bb7033735606569d8f90f89669d16
export CURL_VERSION="7.75.0"
export LIBNGHTTP2_VERSION="1.43.0"
export BROTLI_VERSION="1.0.9"

source h5py-wheels/config.sh

function build_curl2 {
    if [ -e curl-stamp ]; then return; fi
    local flags="--prefix=$BUILD_PREFIX"
    if [ -n "$IS_MACOS" ]; then
        flags="$flags --with-darwinssl"
    else  # manylinux
        flags="$flags --with-ssl"
        build_openssl
    fi
    flags="$flags --without-brotli --without--libnghttp2"
    #build_libnghttp2
    #build_brotli
    fetch_unpack https://curl.haxx.se/download/curl-${CURL_VERSION}.tar.gz
    (cd curl-${CURL_VERSION} \
        && if [ -z "$IS_MACOS" ]; then \
        LIBS=-ldl ./configure $flags; else \
        ./configure $flags; fi\
        && make -j4 \
        && make install)
    touch curl-stamp
}

function build_libnghttp2 {
    if [ -e libnghttp2-stamp ]; then return; fi
    fetch_unpack https://github.com/nghttp2/nghttp2/releases/download/v${LIBNGHTTP2_VERSION}/nghttp2-${LIBNGHTTP2_VERSION}.tar.gz
    (cd nghttp2-${LIBNGHTTP2_VERSIONN} \
        && ./configure --prefix=$BUILD_PREFIX --enable-shared \
        && make \
        && make install)
    touch libnghttp2-stamp
}

function build_brotli {
    if [ -e brotli-stamp ]; then return; fi
    fetch_unpack https://github.com/google/brotli/archive/v${BROTLI_VERSION}/v${BROTLI_VERSION}.tar.gz
    (cd brotli-${BROTLI_VERSIONN} \
        && ./configure-cmake --prefix=$BUILD_PREFIX --enable-shared \
        && make \
        && make install)
    touch brotli-stamp
}

function build_libs {
    build_hdf5
    # use built-in curl on OSX
    #if [ -z "$IS_OSX" ]; then
    #  build_curl
    #else
    #  touch curl-stamp
    #fi
    build_curl2
    if [ -z "$IS_OSX" ] && [ $MB_ML_VER -eq 1 ]; then
       export CFLAGS="-std=gnu99 -Wl,-strip-all"
    fi
    build_netcdf
}

function run_tests {
    # Runs tests on installed distribution from an empty directory
    cp ../netcdf4-python/test/* .
    export PATH="/usr/local/bin:${PATH}"
    python run_all.py
}

