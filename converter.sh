#!/usr/bin/env bash

set -Eeuo pipefail

# "-h", help message
usage() {
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

while getopts "d:ho:q:r" opt
do
    case $opt in
        d)
            input_dir=$OPTARG
            ;;
        h)
            usage
            ;;
        o)
            output_dir=$OPTARG
            ;;
        q)
            ratio=$OPTARG
            ;;
        r)
            recursive=true
            ;;
        ?)
            echo "Unknown option"
            exit 1
            ;;
    esac
done
