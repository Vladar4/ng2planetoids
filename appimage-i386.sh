#!/bin/sh

# Configured for Ubuntu 12.04.5 LTS

NAME="Nimgame 2 Planetoids"
PROJ="ng2planetoids"
ARCH="i386"
DATA="data"
DEPS="\
/usr/local/lib/libSDL2.so \
/usr/local/lib/libSDL2_gfx.so \
/usr/local/lib/libSDL2_image.so \
/usr/local/lib/libSDL2_mixer.so \
/usr/local/lib/libSDL2_net.so \
/usr/local/lib/libSDL2_ttf.so \
/usr/lib/$ARCH-linux-gnu/libfreetype.so \
/usr/lib/$ARCH-linux-gnu/libogg.so.0 \
/lib/$ARCH-linux-gnu/libpng12.so.0 \
/usr/lib/$ARCH-linux-gnu/libvorbis.so.0 \
/usr/lib/$ARCH-linux-gnu/libvorbisfile.so.3 \
/lib/$ARCH-linux-gnu/libz.so.1"

rm -rf "$PROJ.AppDir"
mkdir -p "$PROJ.AppDir/usr/bin"
mkdir -p "$PROJ.AppDir/usr/lib"
cp "$PROJ" "$PROJ.AppDir/usr/bin"
cp "$PROJ".png "$PROJ.AppDir"

cp -R "$DATA" "$PROJ.AppDir/usr"
cd "$PROJ.AppDir"
cp $DEPS usr/lib
strip usr/bin/* usr/lib/*

echo "[Desktop Entry]
Type=Application
Name=$NAME
Exec=$PROJ
Icon=$PROJ" > "$PROJ.desktop"

wget -O AppRun https://github.com/probonopd/AppImageKit/releases/download/continuous/AppRun-i686
chmod a+x AppRun

cd ..
wget -N https://github.com/probonopd/AppImageKit/releases/download/continuous/appimagetool-i686.AppImage
chmod a+x appimagetool-i686.AppImage
./appimagetool-i686.AppImage "$PROJ.AppDir" "$PROJ-$ARCH.run"

