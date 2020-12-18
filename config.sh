# Define custom utilities
# Test for OSX with [ -n "$IS_OSX" ]
# Uncomment to disable net tests - the server is sometimes down
export NO_NET=1

# Compile libs for macOS 10.9 or later
export MACOSX_DEPLOYMENT_TARGET="10.9"
export NETCDF_VERSION="4.7.4"
export HDF5_VERSION="1.12.0"
export PERL_VERSION="5.16.0"

source h5py-wheels/config.sh

function build_libs {
    build_hdf5
    build_curl2
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

function build_curl2 {
    if [ -e curl-stamp ]; then return; fi
    local flags="--prefix=$BUILD_PREFIX"
    if [ -n "$IS_OSX" ]; then
        flags="$flags --with-darwinssl"
    else  # manylinux
        flags="$flags --with-ssl"
	# Install new Perl because OpenSSL configure scripts require > 5.10.0.
	echo "Old Perl version `perl -v`"
	curl -L https://install.perlbrew.pl | bash
	export PERLBREW_ROOT=/root/perl5/perlbrew
	source ${PERLBREW_ROOT}/etc/bashrc
	perlbrew install perl-${PERL_VERSION}
	perlbrew use perl-${PERL_VERSION}
	echo "New Perl version `perl -v`"
        build_openssl
    fi
    fetch_unpack https://curl.haxx.se/download/curl-${CURL_VERSION}.tar.gz
    (cd curl-${CURL_VERSION} \
        && if [ -z "$IS_OSX" ]; then \
        LIBS=-ldl ./configure $flags; else \
        ./configure $flags; fi\
        && make -j4 \
        && make install)
    touch curl-stamp
}
