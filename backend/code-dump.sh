#!/bin/bash

# Usage: ./scripts/stitch-code.sh [target_directory] [output_file]
# Default: ./scripts/stitch-code.sh . codebase_dump.txt

TARGET_DIR=${1:-"."}
OUTPUT_FILE=${2:-"codebase_dump.txt"}

# Clear the output file if it exists
> "$OUTPUT_FILE"

echo "Scanning $TARGET_DIR and writing to $OUTPUT_FILE..."

find "$TARGET_DIR" -type f \
    -not -path "*/__pycache__/*" \
    -not -path "*/node_modules/*" \
    -not -path "*/.venv/*" \
    -not -path "*/.git/*" \
    -not -path "*/migrations/*" \
    -not -name "*.pyc" \
    -not -name "*.png" \
    -not -name "*.csv" \
    -not -name "*.jpg" \
    -not -name "*.jpeg" \
    -not -name "db.sqlite3" \
    -not -name "*.ico" \
    -not -name "$OUTPUT_FILE" \
    -print0 | while IFS= read -r -d '' FILE; do

    echo "-------------------------------------------------------------------------------" >> "$OUTPUT_FILE"
    echo "FILE: $(realpath "$FILE")" >> "$OUTPUT_FILE"
    echo "-------------------------------------------------------------------------------" >> "$OUTPUT_FILE"
    
    # Safely append file content
    cat "$FILE" >> "$OUTPUT_FILE"
    
    # Add spacing
    printf "\n\n" >> "$OUTPUT_FILE"
done

echo "Done! Full dump available at $OUTPUT_FILE"
