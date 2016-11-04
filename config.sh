# Define custom utilities
# Test for OSX with [ -n "$IS_OSX" ]

source h5py-wheels/config.sh

function build_libs {
    build_hdf5
    build_curl
    build_netcdf
}

function run_tests {
    # Runs tests on installed distribution from an empty directory
    (cd ../netcdf4-python/test &&
        python run_all.py &&
        if [ -n "$IS_OSX" ]; then arch -i386 python ../run_tests.py; fi)
}
