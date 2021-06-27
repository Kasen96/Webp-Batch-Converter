#!/usr/bin/env bash
#
# batch convert images to webp format.

#----------------------------------------------------------

# fail fast
set -Eeuo pipefail

# set Global Var
OSNAME=$(cat /etc/*release | grep -E ^ID | cut -f2 -d"=")
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
usage: converter.sh [-h] [-d DIR] [-q RATIO] [-r] [-y]

optional arguments:
-h       Show the help message.
-d       Specify the input directory, default is the current directory.
-o       Specify the output directory, default is the current directory.
-q       Quality ratio (0 ~ 100), default is 75.
-r       Process recursively.
-y       Skip confirmation and convert images in the current directory only.
EOF
  exit
}

# traverse and execute files
# require argument:
#     INPUT_DIR
traverse_files() {
  # change IFS
  local savedifs=${IFS}
  IFS=$'\n'

  # check the path ends with "/" or not
  if [[ ${1:0-1:1} = "/" ]]; then
    local path="$1*"
  else
    local path="$1/*"
  fi

  # traverse files
  for file in ${path}; do # do not use $(ls ...)
    if [[ -d "${file}" && ${RECURSIVE} = true ]]; then
      traverse_files "${file}"
    elif [[ -f "${file}" && -r "${file}" ]]; then
      echo "'${file}' is a file"
    elif [[ -f "${file}" && ! -r "${file}" ]]; then
      echo "'${file}' can not be read!"
    fi
  done

  # restore IFS
  IFS=${savedifs}
}

#----------------------------------------------------------
# main

# if no input arguments
if [[ $# -eq 0 ]]; then
  echo "Execute the conversion (only in the current directory)[Y|N]?"
  read -rn1 execarg
  case ${execarg} in
    Y | y)
      echo
      ;;
    N | n)
      echo
      exit 1
      ;;
    *)
      echo
      echo "Unknown input."
      exit 1
      ;;
  esac
else
  # get user input argument
  while getopts "d:ho:q:ry" opt; do
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
      y)
        ;;
      *)
        echo "Unknown option."
        exit 1
        ;;
    esac
  done
fi

# arguments check
if [[ ! -d "${INPUT_DIR}" ]]; then
  echo "Input directory path[-d]: '${INPUT_DIR}' does not exist!"
  exit 1
elif [[ ! -d "${OUTPUT_DIR}" ]]; then
  mkdir "${OUTPUT_DIR}" # create output dir
elif [[ ${RATIO} -gt 100 || ${RATIO} -lt 0 ]]; then
  echo "Quality ratio[-q] should be between 0 and 100!"
  exit 1
fi

# execute conversion
if type cwebp > /dev/null 2>&1; then
  # cwebp exists
  traverse_files "${INPUT_DIR}"
else
  # cwebp does not exist, install hint
  echo "Sorry, 'cwebp' is not installed in the system."
  case ${OSNAME} in
    "ubuntu" | "debian")
      echo "Use 'apt install webp' to install." ;;
    "centos")
      echo "Use 'yum install libwebp-tools' to install." ;;
    "fedora")
      echo "Use 'dnf install libwebp-tools' to install." ;;
    *)
      echo "Please download manually from https://developers.google.com/speed/webp/download." ;;
  esac
fi
