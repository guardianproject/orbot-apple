#!/usr/bin/env sh

# Get absolute path to this script.
SCRIPTDIR=$(cd `dirname $0` && pwd)
WORKDIR=$(cd "$SCRIPTDIR/../leaf" && pwd)

IOS_XCFRAMEWORK="$SCRIPTDIR/libleaf-ios.xcframework"
MACOS_LIBFILE="$SCRIPTDIR/libleaf-macos.a"

if [ -r "$IOS_XCFRAMEWORK" ] && [ -r "$MACOS_LIBFILE" ]; then
	echo "$IOS_XCFRAMEWORK and $MACOS_LIBFILE already exists."
	exit
fi

FILENAME="libleaf.a"

if [[ -n "${DEVELOPER_SDK_DIR:-}" ]]; then
	# Assume we're in Xcode, which means we're probably cross-compiling.
	# In this case, we need to add an extra library search path for build scripts and proc-macros,
	# which run on the host instead of the target.
	# (macOS Big Sur does not have linkable libraries in /usr/lib/.)
	export LIBRARY_PATH="$SDKROOT/usr/lib:${LIBRARY_PATH:-}"

	# The $PATH used by Xcode likely won't contain Cargo, fix that.
	# This assumes a default `rustup` setup.
	export PATH="$HOME/.cargo/bin:$PATH"
fi

# Undo the patch, remove build dirs.
function clean {
	cd "$WORKDIR"

	git restore .

	rm -rf target

	cd "$SCRIPTDIR"
}

# Do an OPTIMIZED RELEASE build, but WITH DEBUG SYMBOLS for a given target.
#
# - parameter $1: The Rust target.
function build {
	RUSTFLAGS=-g cargo build --target $1 --manifest-path "$WORKDIR/Cargo.toml" -p leaf-ffi --release
}

# Create a universal binary.
#
# - parameter $1: folder name for the universal binary.
# - parameter $2: Rust target name for the x86_64 build.
# - parameter $3: Rust target name for the arm64 build.
function fatten {
	tdir="$WORKDIR/target/$1/release"

	rm -rf "$tdir"
	mkdir -p "$tdir"

	lipo -create \
		-arch x86_64 "$WORKDIR/target/$2/release/$FILENAME" \
		-arch arm64 "$WORKDIR/target/$3/release/$FILENAME" \
		-output "$tdir/$FILENAME"
}


# Apply patch.
clean
patch --directory="$WORKDIR" --strip=1 < "$SCRIPTDIR/leaf-ffi.patch"


# Build macOS library.
# This needs to be stored separately, not in the xcframework, as codesign gets mad at us later,
# when we try to release a macOS app which contains iOS simulator builds.
build x86_64-apple-darwin
build aarch64-apple-darwin
fatten universal_macos x86_64-apple-darwin aarch64-apple-darwin
mv "$WORKDIR/target/universal_macos/release/$FILENAME" "$MACOS_LIBFILE"

# Build iOS simulator.
build x86_64-apple-ios
build aarch64-apple-ios-sim
fatten universal_iossim x86_64-apple-ios aarch64-apple-ios-sim

# Build iOS.
build aarch64-apple-ios

# Create header.
cbindgen --config "$WORKDIR/leaf-ffi/cbindgen.toml" "$WORKDIR/leaf-ffi/src/lib.rs" > "$SCRIPTDIR/leaf.h"

# Create xcframework for iOS.
xcodebuild -create-xcframework \
	-library "$WORKDIR/target/universal_iossim/release/$FILENAME" \
	-headers "$SCRIPTDIR/leaf.h" \
	-library "$WORKDIR/target/aarch64-apple-ios/release/$FILENAME" \
	-headers "$SCRIPTDIR/leaf.h" \
	-output "$IOS_XCFRAMEWORK"

# Clean up behind ourselves.
clean
