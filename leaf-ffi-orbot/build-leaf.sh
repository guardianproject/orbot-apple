#!/usr/bin/env sh

# Get absolute path to this script.
SCRIPTDIR=$(cd `dirname $0` && pwd)
WORKDIR=$(cd "$SCRIPTDIR/../leaf" && pwd)

FILENAME="libleaf.a"

restore()
{
	cd "$WORKDIR"
	git restore .
	cd "$SCRIPTDIR"
}


restore
patch --directory="$WORKDIR" --strip=1 < "$SCRIPTDIR/leaf-ffi.patch"

# Delete old build remnants to avoid any issues.
rm -rf "${WORKDIR}/target"

# See https://github.com/TimNN/cargo-lipo/issues/41#issuecomment-774793892
if [[ -n "${DEVELOPER_SDK_DIR:-}" ]]; then
	# Assume we're in Xcode, which means we're probably cross-compiling.
	# In this case, we need to add an extra library search path for build scripts and proc-macros,
	# which run on the host instead of the target.
	# (macOS Big Sur does not have linkable libraries in /usr/lib/.)
	export LIBRARY_PATH="${SDKROOT}/usr/lib:${LIBRARY_PATH:-}"

	# The $PATH used by Xcode likely won't contain Cargo, fix that.
	# This assumes a default `rustup` setup.
	export PATH="$HOME/.cargo/bin:$PATH"

	# Delete old build, if any.
	rm -f "$BUILT_PRODUCTS_DIR/$FILENAME"

	# cargo lipo --xcode-integ is broken for arm64-sim, despite latest updates,
	# so we determine release flag and targets ourselves.

	RELEASE=""

	if [ $CONFIGURATION = "Release" ]; then
		RELEASE="--release"
	fi

	# Defaults to build for iOS, ARM64 only as needed for release.
	TARGETS="aarch64-apple-ios"

	if [ $PLATFORM_NAME = "macosx" ]; then
		# When building for MacOS, we build for both Intel and ARM64.
		TARGETS="aarch64-apple-darwin,x86_64-apple-darwin"
	elif [ $PLATFORM_NAME = "iphonesimulator" ]; then
		if [ $ARCHS = "arm64" ]; then
			TARGETS="aarch64-apple-ios-sim"
		else
			TARGETS="x86_64-apple-ios"
		fi
	fi

	CONF_LOWER="$(echo $CONFIGURATION | tr '[:upper:]' '[:lower:]')"

	# Otherwise, compilation might fail sometimes. Seems to be a race condition.
	IFS="," read -ra targets <<< "$TARGETS"
	for target in "${targets[@]}"; do
		echo "mkdir ${WORKDIR}/target/${target}/${CONF_LOWER}/deps"

		mkdir -p "${WORKDIR}/target/${target}/${CONF_LOWER}/deps"
	done

	cargo lipo $RELEASE --targets $TARGETS --manifest-path "${WORKDIR}/Cargo.toml" -p leaf-ffi

	# cargo-lipo drops result in different folder, depending on the config.
	SOURCE="${WORKDIR}/target/universal/${CONF_LOWER}/${FILENAME}"

	# Copy compiled library to BUILT_PRODUCTS_DIR. Use that in your Xcode project
	# settings under General -> Frameworks and Libraries.
	# You will also need to have leaf.h somewhere in your search paths!
	# (Easiest way: have it referenced in your project files list.)
	if [ -e "${SOURCE}" ]; then
		cp -a "${SOURCE}" "${BUILT_PRODUCTS_DIR}"
	fi
else
	# Direct command line usage.

	TARGETS=$1

	if [ -z "${TARGETS}" ]; then
		TARGETS="aarch64-apple-darwin,x86_64-apple-darwin"
	fi

	cargo lipo --targets $TARGETS --manifest-path "${WORKDIR}/Cargo.toml" -p leaf-ffi -v
fi

cbindgen --config "${WORKDIR}/leaf-ffi/cbindgen.toml" "${WORKDIR}/leaf-ffi/src/lib.rs" > "${SCRIPTDIR}/leaf.h"

restore
