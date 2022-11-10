#!/usr/bin/env bash
#
# Convert WebP to PNG in batches.

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
RECURSIVE=false

#----------------------------------------------------------
# functions

#######################################
# show help message function ('-h')
#######################################
help_message() {
  cat <<EOF
A simple conversion script that can bulk convert WebP to PNG.
----
usage: webp2png.sh [-h] [-d DIR] [-o DIR] [-r] [-y]

optional arguments:
-h       Show the help message.
-d       Specify the input directory, the default option is the folder where the script is located.
-o       Specify the output directory, if it is empty, the default output path is the same as the original image path.
-r       Process recursively.
-y       Skip confirmation and convert WebP images into PNG in the current directory only.
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
  ((FILE_COUNTS+=1))
}

#######################################
# check file format
# Globals:
#   None
# Arguments:
#   $1 - file path
# Returns:
#   0 - webp
#   1 - other files
#######################################
is_webp() {
  local suffix
  suffix=$(echo "${1##*.}" | awk '{print tolower($0)}')
  if [[ ${suffix} == "webp" ]]; then
    return 0
  fi
  return 1
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
    if [[ -d "${file}" && ${RECURSIVE} == true ]]; then # if it is dir

      # if specify '-o', create corresponding subfolders to keep the same file structure
      if [[ "${OUTPUT_DIR}" ]]; then
        local relative_subdirpath
        relative_subdirpath=$(realpath --relative-to="${INPUT_DIR}" "${file}")"/"
        if [[ ! -d "${OUTPUT_DIR}${relative_subdirpath}" ]]; then
          mkdir -p "${OUTPUT_DIR}${relative_subdirpath}"
        fi
      fi

      traverse_files "${file}"

    elif is_webp "${file}" && [[ -f "${file}" && -r "${file}" ]]; then # if it is a webp

      if [[ "${OUTPUT_DIR}" ]]; then # if specify '-o'
        # extract the image name and rename it to ".png"
        local filename
        filename=$(echo "${file##*/}" | cut -f1 -d".")".png"
        # add output folder prefix
        local output_path="${OUTPUT_DIR}${relative_subdirpath}${filename}"
      else
        local output_path="${file%.*}.png"
      fi

      # use dwebp to convert
      dwebp -o "${output_path}" -quiet -mt -- "${file}"  # -mt: multi-thread
      spin_progress

    elif is_webp "${file}" && [[ -f "${file}" && ! -r "${file}" ]]; then # if it is a webp and can not be read
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
  while getopts "d:ho:ry" opt; do
    case ${opt} in
      d)
        INPUT_DIR=${OPTARG} ;;
      h)
        help_message ;; # help function
      o)
        OUTPUT_DIR=${OPTARG} ;;
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
fi
if [[ ${OUTPUT_DIR} ]]; then
  if [[ ! -d "${OUTPUT_DIR}" ]]; then
    mkdir "${OUTPUT_DIR}" # create output dir
  fi
  if [[ ${OUTPUT_DIR:0-1:1} != "/" ]]; then
    OUTPUT_DIR="${OUTPUT_DIR}/"
  fi
fi

# execute conversion
if type dwebp &> /dev/null; then
  # hide cursor
  printf "\e[?25l"

  FILE_COUNTS=0
  TOTAL_FILES=$(find "${INPUT_DIR}" -type f -iname "*.webp" | wc -l)

  # dwebp exists
  traverse_files "${INPUT_DIR}"

  # show cursor
  printf "\e[?25h""\n"

else
  # dwebp does not exist, install hint
  err "Sorry, 'dwebp' is not installed in the system."
  case ${OSNAME} in
    "MacOS")
      err "It can be installed through 'brew install webp'." ;;
    "ubuntu" | "debian")
      err "It can be installed through 'apt install webp'." ;;
    *)
      err "Please download manually from https://developers.google.com/speed/webp/download." ;;
  esac
fi
