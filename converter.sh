#!/usr/bin/env bash
#
# batch convert images to webp format.

#----------------------------------------------------------

# fail fast
set -Eeuo pipefail

# set Global Var
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd -P)
INPUT_DIR=${INPUT_DIR:-${SCRIPT_DIR}}
OUTPUT_DIR=${OUTPUT_DIR:-${SCRIPT_DIR}}
RATIO=${RATIO:-75}
RECURSIVE=${RECURSIVE:=false}

#----------------------------------------------------------
# functions

# show help message function ('-h')
help_message() {
  cat <<EOF
A simple converter that can batch convert images to webp format.
----
usage: converter.sh [-h] [-d DIR] [-q RATIO] [-r]

optional arguments:
-h       show the help message.
-d       specify the input directory, default is the current bash directory.
-o       specify the output directory, default is the current bash directory.
-q       quality ratio (0 ~ 100), default is 75.
-r       process directories and files recursively.
EOF
  exit
}

#----------------------------------------------------------
# main

# if no input arguments
if [[ $# -eq 0 ]]; then
  echo "Execute the conversion (only in the current directory)[Y|N]?"
  read -rn1 execarg
  case ${execarg} in
    Y | y)
      echo ;;
    N | n)
      echo
      exit 1;;
  esac
else
  # get user input argument
  while getopts "d:ho:q:r" opt; do
    case ${opt} in
      d)
        INPUT_DIR=${OPTARG} ;;
      h)
        help_message ;; # help function
      o)
        OUTPUT_DIR=${OPTARG} ;;
      q)
        RATIO=${OPTARG} ;;
      r)
        RECURSIVE=true ;;
      *)
        echo "Unknown option" >&2
        exit 1
        ;;
    esac
  done
fi

# arguments check
if [[ ! -d ${INPUT_DIR} ]]; then
  echo "Input directory path[-d]: '${INPUT_DIR}' does not exist!" >&2
  exit 1
elif [[ ! -d ${OUTPUT_DIR} ]]; then
  mkdir "${OUTPUT_DIR}" # create output dir
elif [[ ${RATIO} -gt 100 || ${RATIO} -lt 0 ]]; then
  echo "Quality ratio[-q] should be between 0 and 100!" >&2
  exit 1
fi

# execute conversion
if type cwebp > /dev/null 2>&1; then
  # cwebp exists
  echo "cwebp"
else
  # cwebp does not exist
  echo "Sorry, 'cwebp' is not installed in the system."
fi
