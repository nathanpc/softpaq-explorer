#!/bin/sh

### download_index.sh
### Downloads the file that contains the index of the SoftPAQ archives.
###
### Author: Nathan Campos <nathan@innoveworkshop.com>

# Variables
indexurl="https://ftp.zx.net.nz/pub/archive/ftp.compaq.com/pub/softpaq/allfiles.txt"
indexfile="allfiles.txt"

echo "Retrieving SoftPAQ archive index..."
wget "$indexurl" -O "$indexfile"
echo "Done."
