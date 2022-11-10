#!/usr/bin/env bash
#
# Convert pictures to WebP in batches.

#----------------------------------------------------------
# fail fast
set -Eeuo pipefail

# set global var, default value
if [[ $(uname) == "Darwin" ]]; then
  OSNAME="MacOS"
elif [[ $(uname) == "Linux" ]]; then
  OSNAME=$(cat /etc/*release | grep -E ^ID= | cut -f2 -d"=")
fi
readonly OSNAME

INPUT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd -P)  # go and get the location of script
OUTPUT_DIR=  # null, use the source file location.
RATIO=75
RECURSIVE=false

#----------------------------------------------------------
# functions

#######################################
# show help message function ('-h')
#######################################
help_message() {
  cat <<EOF
A simple conversion script that can bulk convert images to WebP.
----
usage: img2webp.sh [-h] [-d DIR] [-o DIR] [-q RATIO] [-r] [-y]

optional arguments:
-h       Show the help message.
-d       Specify the input directory, the default option is the folder where the script is located.
-o       Specify the output directory, if it is empty, the default output path is the same as the original image path.
-q       Quality ratio (0 ~ 100), default is 75.
-r       Process recursively.
-y       Skip confirmation and convert images into WebP in the current directory only.
EOF
  exit
}

#######################################
# error message
#######################################
err() {
  local msg
  msg="[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $*"
  echo -e "\033[31m$msg\033[0m" >&2  # print in red color
}

#######################################
# Show a spin progress when converting
# Arguments:
#   $1 - display message
#   $2 - file counts
# Returns:
#   None
#######################################
spin_progress() {
  local label=('|' '/' '-' "\\")
  local index=$((FILE_COUNTS%4))
  printf "Converting... [%d/%d] [%c] \r" $((FILE_COUNTS+1)) "$TOTAL_FILES" "${label[$index]}"
  sleep 0.1
  ((FILE_COUNTS+=1))
}

#######################################
# check file format
# Globals:
#   None
# Arguments:
#   $1 - file path
# Returns:
#   0 - images
#   1 - other files
#######################################
is_image() {
  local suffix
  suffix=$(echo "${1##*.}" | awk '{print tolower($0)}')
  case ${suffix} in
    "jpg" | "jpeg")
      return 0 ;;
    "png")
      return 0 ;;
    "tif" | "tiff")
      return 0 ;;
    *)
      return 1 ;;
  esac
}

#######################################
# recursive function
#
# If it is a folder, continue recursively;
# If it is a picture, convert.
#
# Globals:
#   IFS
#   RECURSIVE
#   OUTPUT_DIR
#   RATIO
# Arguments:
#   $1 - input dir path
# Returns:
#   None
#######################################
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
  for file in ${path}; do
    if [[ -d "${file}" && ${RECURSIVE} == true ]]; then # if it is a dir
      traverse_files "${file}"
    elif is_image "${file}" && [[ -f "${file}" && -r "${file}" ]]; then # if it is an image
      if [[ -d "${OUTPUT_DIR}" ]]; then # if specify '-o'
        # extract the image name and rename it to ".webp"
        local filename
        filename=$(echo "${file##*/}" | cut -f1 -d".")".webp"
        # add output folder prefix
        if [[ ${OUTPUT_DIR:0-1:1} = "/" ]]; then # check the path ends with "/" or not
          local output_path="${OUTPUT_DIR}${filename}"
        else
          local output_path="${OUTPUT_DIR}/${filename}"
        fi
      else
        local output_path="${file%.*}.webp"
      fi

      # use cwebp to convert
      cwebp -o "${output_path}" -q "${RATIO}" -quiet -mt -- "${file}"  # -mt: multi-thread
      spin_progress

    elif is_image "${file}" && [[ -f "${file}" && ! -r "${file}" ]]; then # if it is an image and can not be read
      err "'${file}' can not be read!"
    fi
  done

  # restore IFS
  IFS=${savedifs}
}

#----------------------------------------------------------
# main

# if no input arguments
if [[ $# -eq 0 ]]; then
  echo "Execute the conversion (only in the current directory) [Y|N]?"
  read -rn1 execarg
  case ${execarg} in
    Y | y)
      echo
      ;;
    N | n)
      echo
      err "Abort."
      exit 1
      ;;
    *)
      echo
      err "Unknown input."
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
        err "Unknown option."
        exit 1 ;;
    esac
  done
fi

# arguments check
if [[ ! -d "${INPUT_DIR}" ]]; then
  err "Input directory path[-d]: '${INPUT_DIR}' does not exist!"
  exit 1
elif [[ ${OUTPUT_DIR} && ! -d "${OUTPUT_DIR}" ]]; then
  mkdir "${OUTPUT_DIR}" # create output dir
elif [[ ${RATIO} -gt 100 || ${RATIO} -lt 0 ]]; then
  err "Quality ratio[-q] should be between 0 and 100."
  exit 1
fi

# execute conversion
if type cwebp &> /dev/null; then
  # hide cursor
  printf "\e[?25l"

  FILE_COUNTS=0
  TOTAL_FILES=$(find "${INPUT_DIR}" -type f -iname "*.webp" | wc -l)

  # cwebp exists
  traverse_files "${INPUT_DIR}"

  # show cursor
  printf "\e[?25h""\n"

else
  # cwebp does not exist, install hint
  err "Sorry, 'cwebp' is not installed in the system."
  case ${OSNAME} in
    "MacOS")
      err "It can be installed through 'brew install webp'." ;;
    "ubuntu" | "debian")
      err "It can be installed through 'apt install webp'." ;;
    *)
      err "Please download manually from https://developers.google.com/speed/webp/download." ;;
  esac
fi
