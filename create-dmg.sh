#!/usr/bin/env sh

brew list create-dmg || brew install create-dmg

file=$(realpath "$1")
path=$(dirname "$file")
name=$(basename "$file")
basename=$(echo "$name" | cut -f 1 -d '.')
scriptpath=$(dirname "$0")

dmg="${path}/${basename}.dmg"
src="${scriptpath}/Shared/Assets.xcassets/AppIcon.appiconset"
tmp="${path}/${basename}.iconset"
icns="${path}/${basename}.icns"

rm -f "$dmg"
rm -rf "$tmp"
rm -f "$icns"

mkdir "$tmp"

cp -a "$src/Icon-16.png" "$tmp/icon_16x16.png"
cp -a "$src/Icon-32.png" "$tmp/icon_16x16@2x.png"
cp -a "$src/Icon-32.png" "$tmp/icon_32x32.png"
cp -a "$src/Icon-64.png" "$tmp/icon_32x32@2x.png"
cp -a "$src/Icon-128.png" "$tmp/icon_128x128.png"
cp -a "$src/Icon-256.png" "$tmp/icon_128x128@2x.png"
cp -a "$src/Icon-256.png" "$tmp/icon_256x256.png"
cp -a "$src/Icon-512.png" "$tmp/icon_256x256@2x.png"
cp -a "$src/Icon-512.png" "$tmp/icon_512x512.png"
cp -a "$src/Icon-1024.png" "$tmp/icon_512x512@2x.png"


iconutil --convert icns --output "$icns" "$tmp"

rm -rf "$tmp"

create-dmg --volicon "$icns" --icon "$name" 0 0 --app-drop-link 200 0 "$dmg" "$file"

rm -f "$icns"
