#!/usr/bin/env sh

# This could have been so great, unifying everything in an xcframework.
# However, as soon as it comes to uploading, Apple starts to hate us for
# packaging simulator builds alongside.
# So no xcframework, but instead library archives in different folders
# with adapted LIBRARY_SEARCH_PATHS.

# Get absolute path to this script.
SCRIPTDIR=$(cd `dirname $0` && pwd)
WORKDIR=$(cd "$SCRIPTDIR/../leaf" && pwd)

LIBDIR_MACOS="$SCRIPTDIR/macos"
LIBDIR_IOSSIM="$SCRIPTDIR/iossim"
LIBDIR_IOS="$SCRIPTDIR/ios"

FILENAME="libleaf.a"

export MACOSX_DEPLOYMENT_TARGET=11.0
export IPHONEOS_DEPLOYMENT_TARGET=15.0

if [ -r "$LIBDIR_MACOS/$FILENAME" ] && [ -r "$LIBDIR_IOSSIM/$FILENAME" ] && [ -r "$LIBDIR_IOS/$FILENAME" ]; then
	echo "leaf already exists."
	exit
fi

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

# Do a DEBUG build OR an OPTIMIZED RELEASE build, but WITH DEBUG SYMBOLS for a given target.
#
# - parameter $1: The Rust target.
# - parameter $2: "--release" to do an optimized release build with debug symbols.
function build {
	if [ "${2:-}" = "--release" ]; then
		RUSTFLAGS=-g cargo build --target $1 --manifest-path "$WORKDIR/Cargo.toml" -p leaf-ffi --release
	else
		cargo build --target $1 --manifest-path "$WORKDIR/Cargo.toml" -p leaf-ffi
	fi
}

# Create a universal binary.
#
# - parameter $1: folder name for the universal binary.
# - parameter $2: Rust target name for the x86_64 build.
# - parameter $3: Rust target name for the arm64 build.
# - parameter $4: "--release" to use release builds, else debug builds will be used.
function fatten {
	quality="debug"

	if [ "${4:-}" = "--release" ]; then
		quality="release"
	fi

	tdir="$WORKDIR/target/$1/$quality"

	rm -rf "$tdir"
	mkdir -p "$tdir"

	lipo -create \
		-arch x86_64 "$WORKDIR/target/$2/$quality/$FILENAME" \
		-arch arm64 "$WORKDIR/target/$3/$quality/$FILENAME" \
		-output "$tdir/$FILENAME"
}

function move {
	quality="debug"

	if [ "${3:-}" = "--release" ]; then
		quality="release"
	fi

	rm -rf "$2"
	mkdir -p "$2"

	mv "$WORKDIR/target/$1/$quality/$FILENAME" "$2/$FILENAME"
}


# Apply patch.
clean
patch --directory="$WORKDIR" --strip=1 < "$SCRIPTDIR/leaf-ffi.patch"


# Build macOS library.
build x86_64-apple-darwin --release
build aarch64-apple-darwin --release
fatten universal_macos x86_64-apple-darwin aarch64-apple-darwin --release
move universal_macos "$LIBDIR_MACOS" --release

# Build iOS simulator library.
build x86_64-apple-ios
build aarch64-apple-ios-sim
fatten universal_iossim x86_64-apple-ios aarch64-apple-ios-sim
move universal_iossim "$LIBDIR_IOSSIM"

# Build iOS.
build aarch64-apple-ios --release
move aarch64-apple-ios "$LIBDIR_IOS" --release


# Create header.
cbindgen --config "$WORKDIR/leaf-ffi/cbindgen.toml" "$WORKDIR/leaf-ffi/src/lib.rs" > "$SCRIPTDIR/leaf.h"

# Clean up behind ourselves.
clean
