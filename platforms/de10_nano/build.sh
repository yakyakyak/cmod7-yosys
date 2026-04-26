#!/bin/bash
set -e

QUARTUS_BIN=~/altera_lite/25.1std/quartus/bin
PROJECT_DIR=$(dirname "$(realpath "$0")")
PROJECT=de10_nano

export PATH=$QUARTUS_BIN:$PATH

cd "$PROJECT_DIR"
mkdir -p output_files

echo "==> Compiling $PROJECT with quartus_sh..."
quartus_sh --flow compile $PROJECT

echo ""
echo "==> Build complete: output_files/${PROJECT}.sof"
echo "==> Program with: openFPGALoader -b de10nano output_files/${PROJECT}.sof"
