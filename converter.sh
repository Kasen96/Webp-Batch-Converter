#!/usr/bin/env bash
#
# batch convert images to webp format, or vice versa.

# fail fast
set -Eeuo pipefail

# get current dir
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

####
# Show help message function ('-h')
####
help_message() {
  cat <<EOF
A simple converter that can batch convert images to webp format, or vice versa.
----
usage: converter.sh [-h] [-d DIR] [-q RATIO] [-r]

optional arguments:
-h       show the help message.
-d       specify the input directory, default is the current directory.
-o       specify the output directory, default is the current directory.
-q       quality ratio (0 ~ 100), default is 75.
-r       process directories and files recursively.
EOF
  exit
}

####
# Set default value function
####
set_default_var() {
  # INPUT_DIR
  INPUT_DIR=${INPUT_DIR:-${SCRIPT_DIR}}
  # OUTPUT_DIR
  OUTPUT_DIR=${OUTPUT_DIR:-${SCRIPT_DIR}}
  # RATIO
  RATIO=${RATIO:-75}
  # RECURSIVE
  RECURSIVE=${RECURSIVE:=false}
}

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
      echo "Unknown option"
      exit 1
      ;;
  esac
done

####
# main function
####
main() {
  set_default_var

  echo "${INPUT_DIR}"
  echo "${OUTPUT_DIR}"
  echo "${RATIO}"
  echo "${RECURSIVE}"
}
main