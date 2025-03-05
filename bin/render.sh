#!/bin/bash

set -e -o pipefail

render() {
    local -r tmpl="$1"
    local -r dst_dir="$2"
    local -r base="$(basename "$tmpl")"
    local -r dst="${dst_dir}/${base}"
    echo "[RENDER] ${tmpl} -> ${dst}"
    envsubst < "$tmpl" > "$dst"
}


mkdir -p dist/bin
ls -1 template/*.qml | while read x ; do render "$x" dist ; done
