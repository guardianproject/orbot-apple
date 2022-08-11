#!/usr/bin/env sh

# Get absolute path to this script.
SCRIPTDIR=$(cd `dirname $0` && pwd)
WORKDIR="$SCRIPTDIR/../leaf"

FILENAME="libleaf.a"

restore()
{
	cd "$WORKDIR"
	git restore .
	cd "$SCRIPTDIR"
}


restore
patch --directory="$WORKDIR" --strip=1 < "$SCRIPTDIR/leaf-ffi.patch"

# See https://github.com/TimNN/cargo-lipo/issues/41#issuecomment-774793892
if [[ -n "${DEVELOPER_SDK_DIR:-}" ]]; then
	# Assume we're in Xcode, which means we're probably cross-compiling.
	# In this case, we need to add an extra library search path for build scripts and proc-macros,
	# which run on the host instead of the target.
	# (macOS Big Sur does not have linkable libraries in /usr/lib/.)
	export LIBRARY_PATH="$DEVELOPER_SDK_DIR/MacOSX.sdk/usr/lib:${LIBRARY_PATH:-}"

	# The $PATH used by Xcode likely won't contain Cargo, fix that.
	# This assumes a default `rustup` setup.
	export PATH="$HOME/.cargo/bin:$PATH"

	# Delete old build, if any.
	rm -f "$BUILT_PRODUCTS_DIR/$FILENAME"

	# cargo lipo --xcode-integ is broken for arm64-sim, despite latest updates,
	# so we determine release flag and target ourselves.

	RELEASE=""

	if [ $CONFIGURATION = "Release" ]; then
		RELEASE="--release"
	fi

	TARGET="aarch64-apple-ios"

	if [ $PLATFORM_NAME = "macosx" ]; then
		if [ $ARCHS = "arm64" ]; then
			TARGET="aarch64-apple-darwin"
		else
			TARGET="x86_64-apple-darwin"
		fi
	elif [ $PLATFORM_NAME = "iphonesimulator" ]; then
		if [ $ARCHS = "arm64" ]; then
			TARGET="aarch64-apple-ios-sim"
		else
			TARGET="x86_64-apple-ios"
		fi
	fi

	cargo lipo $RELEASE --targets $TARGET --manifest-path "$WORKDIR/Cargo.toml" -p leaf-ffi

	CONF_LOWER="$(echo $CONFIGURATION | tr '[:upper:]' '[:lower:]')"

	# cargo-lipo drops result in different folder, depending on the config.
	SOURCE="$WORKDIR/target/universal/$CONF_LOWER/$FILENAME"

	# Copy compiled library to BUILT_PRODUCTS_DIR. Use that in your Xcode project
	# settings under General -> Frameworks and Libraries.
	# You will also need to have leaf.h somewhere in your search paths!
	# (Easiest way: have it referenced in your project files list.)
	if [ -e "${SOURCE}" ]; then
		cp -a "${SOURCE}" "$BUILT_PRODUCTS_DIR"
	fi
else
	# Direct command line usage.
	cargo lipo --manifest-path "$WORKDIR/Cargo.toml" -p leaf-ffi
fi

cbindgen --config "$WORKDIR/leaf-ffi/cbindgen.toml" "$WORKDIR/leaf-ffi/src/lib.rs" > "$SCRIPTDIR/leaf.h"

restore
