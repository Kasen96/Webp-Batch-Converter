# WebP Converter

A simple conversion script that can bulk convert images to WebP or vice versa.

## Install Dependencies

* macOS: `brew install webp`
* Debian / Ubuntu: `apt install webp`
* [Manual Download](https://developers.google.com/speed/webp/download)

## Usage

* Convert images to WebP:

   ``` Bash
   img2webp.sh [-h] [-d DIR] [-o DIR] [-q RATIO] [-r] [-y]

   optional arguments:
   -h       Show the help message.
   -d       Specify the input directory, the default option is the folder where the script is located.
   -o       Specify the output directory, if it is empty, the default output path is the same as the original image path.
   -q       Quality ratio (0 ~ 100), default is 75.
   -r       Process recursively.
   -y       Skip confirmation and convert images into WebP in the current directory only.
   ```

* Convert WebP to PNG:

   ``` Bash
   webp2png.sh [-h] [-d DIR] [-o DIR] [-r] [-y]

   optional arguments:
   -h       Show the help message.
   -d       Specify the input directory, the default option is the folder where the script is located.
   -o       Specify the output directory, if it is empty, the default output path is the same as the original image path.
   -r       Process recursively.
   -y       Skip confirmation and convert WebP images into PNG in the current directory only.
   ```

## LICENSE

GNU GPL v3
