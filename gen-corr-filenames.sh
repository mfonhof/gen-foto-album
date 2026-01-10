#!/usr/bin/env bash
shopt -s nullglob
shopt -s nocaseglob

# ROOT directory instellen
ROOT="."

# Functie om een bestand te sanitiseren
sanitize_file() {
    local file="$1"
    local dir=$(dirname "$file")
    local base=$(basename "$file")

    # Verwijder uitvoerrechten
    chmod -x "$file"

    # Vervang spaties en quotes door puntjes, maak lowercase
    local newbase=$(echo "$base" | tr '[:upper:]' '[:lower:]' | tr ' ' '.' | tr -d "'\"")

    if [ "$base" != "$newbase" ]; then
        echo "Hernoemen: $file -> $dir/$newbase"
        mv -i "$file" "$dir/$newbase"
        file="$dir/$newbase"
    fi

    echo "$file"
}

# Functie die recursief door directories gaat
sanitize_tree() {
    local DIR="$1"
    
    # Eerst alle bestanden sanitiseren
    for f in "$DIR"/*; do
        [ -f "$f" ] || continue
        sanitize_file "$f"
    done

    # Dan recursief alle subdirectories
    for subd in "$DIR"/*/; do
        [ -d "$subd" ] || continue
        sanitize_tree "$subd"
    done
}

# Start
echo "Start met sanitiseren van $ROOT"
sanitize_tree "$ROOT"
echo "Klaar!"

