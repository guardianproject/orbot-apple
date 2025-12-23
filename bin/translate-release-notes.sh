#!/bin/bash

#  translate-release-notes.sh
#  OnionBrowser
#
#  Created by Benjamin Erhart on 19.12.25.
#  Copyright © 2025 Tigas Ventures, LLC (Mike Tigas). All rights reserved.
#
# Description: Translates the English release notes to all other languages present
#              in fastlane/metadata/* folders using the DeepL CLI.
# Requirements: DEEPL_AUTH_KEY environment variable set.

BASE=$(dirname "$0")
cd "$BASE"

python3 -m venv .
source "bin/activate"
pip install --upgrade deepl

cd ..

# Path to English release notes
SOURCE_FILE="fastlane/metadata/en-US/release_notes.txt"

# Check if source file exists
if [ ! -f "$SOURCE_FILE" ]; then
    echo "Source file $SOURCE_FILE does not exist."
    exit 1
fi

# Parallel arrays for mapping: folder names -> DeepL codes
FOLDERS=("ar-SA" "bg" "ca" "cs" "da" "de-DE" "el" "en-GB" "en-US" "es-ES" "es-MX" "et" "fi" \
"fr-FR" "he" "hi" "hr" "hu" "id" "it" "ja" "ko" "lt" "lv" "no" "nl-NL" "pl" "pt-BR" "pt-PT" \
"ro" "ru" "sk" "sl" "sv" "th" "tr" "uk" "vi" "zh" "zh-Hans" "zh-Hant")

CODES=("AR" "BG" "CA" "CS" "DA" "DE" "EL" "EN-GB" "EN-US" "ES" "ES-419" "ET" "FI" \
"FR" "HE" "HI" "HR" "HU" "ID" "IT" "JA" "KO" "LT" "LV" "NB" "NL" "PL" "PT-BR" "PT-PT" \
"RO" "RU" "SK" "SL" "SV" "TH" "TR" "UK" "VI" "ZH" "ZH-HANS" "ZH-HANT")  # same order as FOLDERS

# Function: map folder name to DeepL code
map_folder_to_code() {
    local folder="$1"
    for i in "${!FOLDERS[@]}"; do
        if [ "$folder" == "${FOLDERS[i]}" ]; then
            echo "${CODES[i]}"
            return
        fi
    done
    echo ""  # not found
}


# Loop through all subfolders in fastlane/metadata/
for DIR in fastlane/metadata/*/; do
    # Get the folder name (e.g., "de", "fr", "pt-BR")
    LANG_FOLDER=$(basename "$DIR")

    # Skip English source folder
    if [ "$LANG_FOLDER" == "en-US" ]; then
        continue
    fi

    # Check if folder exists in mapping
	TARGET_LANG=$(map_folder_to_code "$LANG_FOLDER")
    if [ -z "$TARGET_LANG" ]; then
        echo "No DeepL mapping for folder '$LANG_FOLDER', skipping..."
        continue
    fi

    echo "Translating release notes to $TARGET_LANG ..."

	# Delete old file first. DeepL will error, if file exists.
    rm -rf "$DIR/release_notes.txt"

    # Translate using DeepL CLI
    python3 -m deepl document --to="$TARGET_LANG" --from="EN" --extra-body-parameters '{"enable_beta_languages": true}' --output-format="txt" "$SOURCE_FILE" "$DIR"

#	python3 -m deepl --version

    echo "Completed: $OUTPUT_FILE"
done

cd "$BASE"
rm -rf .gitignore bin lib pyvenv.cfg

echo "All translations completed!"
