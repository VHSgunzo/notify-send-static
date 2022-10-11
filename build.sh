#!/bin/bash

export MAKEFLAGS="-j$(nproc)"

# WITH_UPX=1

platform="$(uname -s)"
platform_arch="$(uname -m)"

if [ -x "$(which apt 2>/dev/null)" ]
    then
        apt update && apt install -y python3-pip patchelf \
            libgdk-pixbuf-2.0-dev docbook-xsl-ns xmlto upx \
            build-essential clang pkg-config git cmake xsltproc gobject-introspection \
            meson libghc-gtk3-dev libgirepository1.0-dev gtk-doc-tools
fi
pip install staticx

if [ -d build ]
    then
        echo "= removing previous build directory"
        rm -rf build
fi

if [ -d release ]
    then
        echo "= removing previous release directory"
        rm -rf release
fi

# create build and release directory
mkdir build
mkdir release
pushd build

# download notify-send
git clone https://gitlab.gnome.org/GNOME/libnotify.git
notify_send_version="$(cd libnotify && git describe --long --tags|sed 's/^v//;s/\([^-]*-g\)/r\1/;s/-/./g')"
mv libnotify "notify-send-${notify_send_version}"
echo "= downloading notify-send v${notify_send_version}"

echo "= building notify-send"
pushd notify-send-${notify_send_version}
meson setup build && \
meson install -C build
popd # notify-send-${notify_send_version}

popd # build

shopt -s extglob

echo "= packaging notify-send binary"
if [[ "$WITH_UPX" == 1 && -x "$(which upx 2>/dev/null)" ]]
    then
        staticx --strip "$(which notify-send 2>/dev/null)" release/notify-send
    else
        staticx --no-compress --strip "$(which notify-send 2>/dev/null)" release/notify-send
fi

echo "= create release tar.xz"
tar --xz -acf notify-send-static-v${notify_send_version}-${platform_arch}.tar.xz release
# cp notify-send-static-*.tar.xz ~/ 2>/dev/null

if [ "$NO_CLEANUP" != 1 ]
    then
        echo "= cleanup"
        rm -rf release build
fi

echo "= notify-send v${notify-send_version} done"
