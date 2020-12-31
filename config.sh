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

source h5py-wheels/config.sh

function build_libs {
    build_hdf5
    if [ -z "$IS_OSX" ]; then
      build_curl
    else
      touch curl-stamp
    fi
    if [ -z "$IS_OSX" ] && [ $MB_ML_VER -eq 1 ]; then
       export CFLAGS="-std=gnu99 -Wl,-strip-all"
    fi
    build_netcdf
}

function pip_opts {
    echo "--find-links https://3f23b170c54c2533c070-1c8a9b3114517dc5fe17b7c3f8c63a43.ssl.cf2.rackcdn.com"
}

function run_tests {
    # Runs tests on installed distribution from an empty directory
    cp ../netcdf4-python/test/* .
    python run_all.py
}

