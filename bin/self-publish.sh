#!/bin/bash

SIGNING_IDENTITY="Developer ID Application: The Tor Project, Inc (MADPSAYN6T)"


usage() {
    echo "Usage: $0 <command> [options]"
    echo ""
    echo "Commands:"
    echo "  resign     Prepare and sign the app and its extensions"
    echo "  notarize   Zip the signed app and submit it to Apple"
    echo "  log        Fetch the notarization log"
    echo "  staple     Staple the notarization ticket to the app"
    echo ""
    echo "Options for 'resign':"
    echo "  -a <path>  Path to the .xcarchive"
    echo "  -p <path>  Path to the App provision profile"
    echo "  -x <path>  Path to the System Extension provision profile"
    echo ""
    echo "Options for 'log':"
    echo "  -i <id>    Submission ID returned by 'notarize' command"
    echo ""
    echo "Example:"
    echo "  $0 resign -a MyApp.xcarchive -p app.prof -x ext.prof"
    echo "  $0 notarize"
    echo "  $0 log -i 2efe2717-52ef-43a5-96dc-0797e4ca1041"
    echo "  $0 staple"
    exit 1
}

# Helper function to avoid repetition
sign_item() {
    local target="$1"
    local entitlements="$2" # Optional

    if [ -n "$entitlements" ]; then
        echo "Signing with entitlements: $target"
        codesign -s "$SIGNING_IDENTITY" -f --entitlements "$entitlements" --timestamp -o runtime "$target"
    else
        echo "Signing: $target"
        codesign -s "$SIGNING_IDENTITY" -f --timestamp -o runtime "$target"
    fi
}

do_resign() {
    local archive=""
    local app_profile=""
    local ext_profile=""

    # Parse flags specific to the resign command
    while getopts "a:p:x:" opt; do
        case "$opt" in
            a) archive="$OPTARG" ;;
            p) app_profile="$OPTARG" ;;
            x) ext_profile="$OPTARG" ;;
            *) usage ;;
        esac
    done

    if [ -z "$archive" ] || [ -z "$app_profile" ] || [ -z "$ext_profile" ]; then
        echo "Error: 'resign' requires -a, -p, and -x arguments."
        usage
    fi

    echo "Starting Resign process…"

    # 1. Extract App from Archive
    APP_FULL_PATH=$(find "$archive/Products/Applications" -maxdepth 1 -name "*.app" -print -quit)
    if [ -z "$APP_FULL_PATH" ]; then
        echo "Error: No .app bundle found in $archive"
        exit 1
    fi

    APP_BUNDLE=$(basename "$APP_FULL_PATH")
    APP_NAME="${APP_BUNDLE%.app}"

    ditto "$APP_FULL_PATH" "$APP_BUNDLE"

    EXT_FULL_PATH=$(find "$APP_BUNDLE/Contents/Library/SystemExtensions" -maxdepth 1 -name "*.systemextension" -print -quit)
    if [ -z "$EXT_FULL_PATH" ]; then
        echo "Error: No .systemextension bundle found in $APP_BUNDLE"
        exit 1
    fi

    # 2. Handle Entitlements (Preparation)
    # We extract them, modify the packet-tunnel string, and save them as temp files
    codesign -d --entitlements "$APP_NAME.entitlements" --xml "$APP_BUNDLE"
    codesign -d --entitlements "$APP_NAME-ext.entitlements" --xml "$EXT_FULL_PATH"

    for f in "${APP_NAME}.entitlements" "$APP_NAME-ext.entitlements"; do
        plutil -convert xml1 "$f"
        sed 's/packet-tunnel-provider/packet-tunnel-provider-systemextension/g' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
    done

    # 3. Inject Provisioning Profiles
    cp "$app_profile" "$APP_BUNDLE/Contents/embedded.provisionprofile"
    cp "$ext_profile" "$EXT_FULL_PATH/Contents/embedded.provisionprofile"

	# 4. Sign libraries, if any.
    while IFS= read -r item; do sign_item "$item"; done < <(find "$APP_BUNDLE" -name "*.dylib")
    while IFS= read -r item; do sign_item "$item"; done < <(find "$APP_BUNDLE" -name "*.framework")

# TODO: Only necessary, when bundles contain binaries. Would complicate things, because frameworks can also
#       contain bundles, so more engineering necessary to control order.
#    while IFS= read -r item; do sign_item "$item"; done < <(find "$APP_BUNDLE" -name "*.bundle")

# TODO: Currently not using any. These would probably need profiles, too.
#    while IFS= read -r item; do sign_item "$item"; done < <(find "$APP_BUNDLE" -path "*/XPCServices/*")
#    while IFS= read -r item; do sign_item "$item"; done < <(find "$APP_BUNDLE" -path "*/Helpers/*")
#    while IFS= read -r item; do sign_item "$item"; done < <(find "$APP_BUNDLE" -name "*.appex")

    # 5. Sign system extension.
    sign_item "$EXT_FULL_PATH" "$APP_NAME-ext.entitlements"

    # 6. Sign the final app bundle.
    sign_item "$APP_BUNDLE" "$APP_NAME.entitlements"

    echo "Successfully resigned $APP_BUNDLE"

    # Cleanup temp entitlements
    rm -f "${APP_NAME}.entitlements" "$APP_NAME-ext.entitlements"
}

# https://developer.apple.com/documentation/security/customizing-the-notarization-workflow
do_notarize() {
    local app_bundle=$(find . -maxdepth 1 -name "*.app" -print -quit)

    if [ -z "$app_bundle" ]; then
        echo "Error: No .app bundle found in current directory. Run 'resign' first."
        exit 1
    fi

    local app_name="${app_bundle%.app}"

    echo "Packaging $app_bundle for notarization…"
    ditto -c -k --keepParent "$app_bundle" "$app_name.zip"

    echo "Submitting to notarytool…"
    xcrun notarytool submit "$app_name.zip" --keychain-profile="notarytool-password" --wait
    echo "Notarization complete!"
}

# https://developer.apple.com/documentation/security/customizing-the-notarization-workflow#Check-the-status-of-your-request
do_log() {
    local id=""

    # Parse flags specific to the log command
    while getopts "i:" opt; do
        case "$opt" in
            i) id="$OPTARG" ;;
            *) usage ;;
        esac
    done

    if [ -z "$id" ]; then
        echo "Error: 'log' requires -i argument."
        usage
    fi

    xcrun notarytool log "$id" --keychain-profile="notarytool-password"
}

# https://developer.apple.com/documentation/security/customizing-the-notarization-workflow#Staple-the-ticket-to-your-distribution
do_staple() {
    local app_bundle=$(find . -maxdepth 1 -name "*.app" -print -quit)

    if [ -z "$app_bundle" ]; then
        echo "Error: No .app bundle found in current directory. Run 'resign' and 'notarize' first."
        exit 1
    fi

    local app_name="${app_bundle%.app}"

    echo "Stapling notarization ticket to ${app_bundle}…"

    xcrun stapler staple "$app_bundle"

    rm -f "$app_name.zip"

    echo "Packaging $app_bundle again…"
    ditto -c -k --keepParent "$app_bundle" "$app_name.zip"

    echo "SUCCESS! You can now distribute $app_name.zip!"
}

# --- Main Entry Point ---

if [ $# -lt 1 ]; then
    usage
fi

COMMAND=$1
shift # Remove the command from the argument list so getopts can handle the rest

case "$COMMAND" in
    resign)
        do_resign "$@"
        ;;
    notarize)
        do_notarize "$@"
        ;;
    log)
        do_log "$@"
        ;;
    staple)
        do_staple "$@"
        ;;
    -h|--help|help)
        usage
        ;;
    *)
        echo "Error: Unknown command '$COMMAND'"
        usage
        ;;
esac
