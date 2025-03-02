#!/bin/bash

set -e

readonly d="$(cd "$(dirname "$0")" || exit; pwd)"

#
# settings
#

# MuseScore4 executable
readonly mscore="${MUSESCORE4_BIN}"
# https://github.com/berquerant/pneutrinoutil dir
readonly pneutrinoutil_dir="${PNEUTRINOUTIL_DIR}"
# executable to play wav, like https://github.com/mpv-player/mpv
readonly player="${PLAYER}"

#
# functions
#

# --workDir/process.log
log_file=""
log() {
    echo "$*" >> "${log_file}"
}

run() {
    log "RUN: $*"
    "$@" >> "${log_file}" 2>&1
}

extract_workdir_from_args() {
    echo "$*" | grep -oE "\-\-workDir [^ ]+" | cut -d " " -f 2-
}

extract_score_from_args() {
    echo "$*" | grep -oE "\-\-score [^ ]+" | cut -d " " -f 2-
}

score2musicxml() {
    local -r _score="$1"
    local -r _out="$2"
    log "Start: score2musicxml"
    run "${mscore}" -o "${_out}" "${_score}"
}

pneutrinoutil() {
    log "Start: pneutrinoutil"
    run "${pneutrinoutil_dir}/dist/pneutrinoutil" \
        --neutrinoDir "${pneutrinoutil_dir}/dist/NEUTRINO" \
        --play "${player}" \
        "$@"
}

#
# entrypoint
#

readonly work_dir="$(extract_workdir_from_args "$@")"
mkdir -p "${work_dir}"
log_file="${work_dir}/process.log"
touch "${log_file}"

readonly score="$(extract_score_from_args "$@")"
readonly score_base="$(basename "$score")"
readonly mxml="${work_dir}/${score_base%.*}.musicxml"
eval "$(/opt/homebrew/bin/brew shellenv)"
score2musicxml "${score}" "${mxml}"
pneutrinoutil $(echo "$*" | sed 's|${score}|${mxml}|')  # split arguments
