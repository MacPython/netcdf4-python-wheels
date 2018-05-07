# Define custom utilities
# Test for OSX with [ -n "$IS_OSX" ]
# Uncomment to disable net tests - the server is sometimes down
# export NO_NET=1

source h5py-wheels/config.sh

function build_libs {
    build_hdf5
    build_curl
    build_netcdf
}

function run_tests {
    # Runs tests on installed distribution from an empty directory
    cp ../netcdf4-python/test/* .
    python run_all.py
}
