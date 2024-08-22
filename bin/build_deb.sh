#!/bin/bash

## This script is meant to libgpiod v2 (Not the same as the debian package libgpiod2) and create deb packages
## that are going to be uploaded to a github repo as a PPA where we can pull them and install on our systems
## files are installed under /usr

LIBGPIOD_VERSION=2.1.3
ARCH=$(uname -m)

# Check that all needed packages are installed
INSTALL_COUNT=$(dpkg-query -l build-essential libtool pkg-config autoconf autoconf-archive | grep "ii" -c)
if  [ $INSTALL_COUNT -ne 5 ]; then
    echo "Please run 'sudo apt install -y build-essential libtool pkg-config autoconf autoconf-archive dpkg git' to install dependencies"
    exit 1
fi

# Chech the arch type, this script supports builds for arm64, armhf/v7, 
# and x86_64 which must of us use WSL with

if [ "$ARCH" == "aarch64" ]; then
    export TARGET_DIR=aarch64-linux-gnu
    export ARCH_SUFFIX=arm64
elif [ "$ARCH" == "x86_64" ]; then
    export TARGET_DIR=x86_64-linux-gnu
    export ARCH_SUFFIX=amd64
elif [ "$ARCH" == "armv7l" ]; then
    export TARGET_DIR=arm-linux-gnueabihf
    export ARCH_SUFFIX=armhf
else 
    echo "Architecture $ARCH not supported here"
    exit 1
fi

echo "Building libgpiod for $ARCH_SUFFIX..."

WRK_DIR=$PWD/.wrk
BUILD_DIR=$WRK_DIR/build
PACKAGE_DIR=$WRK_DIR/package
DEV_PACKAGE_DIR=$WRK_DIR/dev-package
PREFIX=usr

mkdir -p $BUILD_DIR
mkdir -p $PACKAGE_DIR
mkdir -p $DEV_PACKAGE_DIR

# We clone libgpiod repo
if [[ ! -d $WRK_DIR/libgpiod ]]; then
    git clone \
        --recursive https://git.kernel.org/pub/scm/libs/libgpiod/libgpiod.git \
        -b "v${LIBGPIOD_VERSION}" \
        $WRK_DIR/libgpiod

    if [ $? -ne 0 ]; then
        echo "failed to clone repo quiting."
        exit 1
    fi
fi

# Autogen and make the project, install into the proper system directories
cd $WRK_DIR/libgpiod
echo "Building with prefix $BUILD_DIR/$PREFIX..."
./autogen.sh --enable-tools=yes --prefix=$BUILD_DIR/$PREFIX || { echo 'Autogen failed...' ; exit 1; }
make
make install

# Build dev package and regular bin package directories
mkdir -p $PACKAGE_DIR/DEBIAN
mkdir -p $PACKAGE_DIR/$PREFIX

mkdir -p $DEV_PACKAGE_DIR/DEBIAN
mkdir -p $DEV_PACKAGE_DIR/$PREFIX

# Add control text to bin package
cat << EOF > $PACKAGE_DIR/DEBIAN/control 
Package: libgpiod$LIBGPIOD_VERSION
Version: $LIBGPIOD_VERSION
Section: universe/libs
Priority: optional
Source: libgpiod$LIBGPIOD_VERSION
Architecture: $ARCH_SUFFIX
Depends: libc6 (>= 2.4)
Maintainer: Alejandro Mata <alejandromata@nureva.com>
Description: libgpiod 2.x for Ubuntu Linux, made for Ubuntu 24.04
Homepage: https://git.kernel.org/pub/scm/libs/libgpiod/libgpiod.git/
EOF

# Add control text to dev package
cat << EOF > $DEV_PACKAGE_DIR/DEBIAN/control 
Package: libgpiod$LIBGPIOD_VERSION-dev
Version: $LIBGPIOD_VERSION
Section: universe/libs
Priority: optional
Source: libgpiod$LIBGPIOD_VERSION
Architecture: $ARCH_SUFFIX
Depends: libc6 (>= 2.4)
Maintainer: Alejandro Mata <alejandromata@nureva.com>
Description: libgpiod 2.x for Ubuntu Linux, made for Ubuntu 24.04
Homepage: https://git.kernel.org/pub/scm/libs/libgpiod/libgpiod.git/
EOF

# Copy all of the files into the package directories headers go into the dev package
# pkg-config stuff, bins, and libs go into the main package
cp -r $BUILD_DIR/$PREFIX/bin $PACKAGE_DIR/$PREFIX
cp -r $BUILD_DIR/$PREFIX/lib $PACKAGE_DIR/$PREFIX
cp -r $BUILD_DIR/$PREFIX/include $DEV_PACKAGE_DIR/$PREFIX

sed -i 's|^prefix=.*|prefix=/usr|' $PACKAGE_DIR/$PREFIX/lib/pkgconfig/libgpiod.pc

# Build the packages
dpkg-deb --root-owner-group --build $PACKAGE_DIR $WRK_DIR/libgpiod${LIBGPIOD_VERSION}_${ARCH_SUFFIX}.deb
dpkg-deb --root-owner-group --build $DEV_PACKAGE_DIR $WRK_DIR/libgpiod${LIBGPIOD_VERSION}-dev_${ARCH_SUFFIX}.deb
