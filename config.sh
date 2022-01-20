# Define custom utilities
# Test for OSX with [ -n "$IS_OSX" ]
# Uncomment to disable net tests - the server is sometimes down
#export NO_NET=1
# ncdump/ncgen not installed in wheel, so tst_cdl.py fails
export NO_CDL=1

# Compile libs for macOS 10.9 or later
#export MACOSX_DEPLOYMENT_TARGET="10.9"
export NETCDF_VERSION="MASTER"
export HDF5_VERSION="1.12.1"
# old openssl, since building new version requires perl 5.10.0
export OPENSSL_ROOT=openssl-1.0.2u
export OPENSSL_HASH=ecd0c6ffb493dd06707d38b14bb4d8c2288bb7033735606569d8f90f89669d16
export CURL_VERSION="7.75.0"

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

function build_netcdf {
    if [ -e netcdf-stamp ]; then return; fi
    build_hdf5
    build_curl
    if [ $NETCDF_VERSION == "MASTER" ]; then
    git clone https://github.com/Unidata/netcdf-c
    cd netcdf-c
    autoreconf -i
    ./configure --prefix=$BUILD_PREFIX --enable-dap \
    make -j4 
    make install
    cd ..
    else
    fetch_unpack https://github.com/Unidata/netcdf-c/archive/v${NETCDF_VERSION}.tar.gz
    (cd netcdf-c-${NETCDF_VERSION} \
        && ./configure --prefix=$BUILD_PREFIX --enable-dap \
        && make -j4 \
        && make install)
    fi
    touch netcdf-stamp
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

