#!/bin/bash

ls -1 *.qml | while read qml ; do
    ln -s "${PWD}/${qml}" "${PLUGINS_DIR}/${qml}"
done
