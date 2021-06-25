#!/usr/bin/env bash

set -euo pipefail

while getopts "d:hq:r" opt
do
    case $opt in
        d)
            echo "The dirctory is $OPTARG"
            ;;
        h)
            echo "This is the help command"
            ;;
        q)
            echo "The picture quality is $OPTARG"
            ;;
        r)
            echo "Process images recursively"
            ;;
        ?)
            echo "Unknown option"
            exit 1
            ;;
    esac
done
