#!/bin/bash

git submodule init
git submodule update

TMP="firmware/ip_cores/general-cores/modules/common/tmp.py"
FILE="firmware/ip_cores/general-cores/modules/common/Manifest.py"

if grep -q "matrix_pkg.vhd" "$FILE"; then
    echo "Manifest already contains matrix_pkg.vhd file."
else
    echo "Missing matrix_pkg.vhd file in Manifest."
    cp "$FILE" "$TMP"
    sed '3i\\t"matrix_pkg.vhd",' "$TMP" > "$FILE"
    rm "$TMP"
fi
