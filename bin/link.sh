#!/bin/bash

set -e -o pipefail

ls -1 dist/*.qml | while read qml ; do
    base="$(basename "$qml")"
    ln -snvf "${PWD}/${qml}" "${PLUGINS_DIR}/${base}"
done
