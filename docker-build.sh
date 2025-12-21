#!/bin/bash
# Build script using meriac/openxc7-litex container

set -e

PROJECT="blinky"
PART="xc7a35tcpg236-1"
DOCKER_IMAGE="ghcr.io/meriac/openxc7-litex:latest"
BUILD_DIR="build"

# Paths in container
BIN_PATH="/home/builder/.local/bin"
NEXTPNR_PYTHON="/home/builder/.local/share/nextpnr/python"
PRJXRAY_DB="/home/builder/.local/share/nextpnr/external/prjxray-db"

# Docker run wrapper
run_docker() {
    docker run --rm \
        -v /Users/yak/Projects/Claude/cmod7:/work \
        -w /work \
        -u "$(id -u):$(id -g)" \
        -e PATH="${BIN_PATH}:/usr/local/bin:/usr/bin:/bin" \
        ${DOCKER_IMAGE} \
        /bin/bash -c "$@"
}

echo "=== Step 1: Synthesis ==="
run_docker "yosys -p 'read_verilog src/top.v; synth_xilinx -flatten -abc9 -arch xc7 -top top; write_json ${BUILD_DIR}/${PROJECT}.json'"

echo "=== Step 2: Generate chipdb (if needed) ==="
run_docker "
if [ ! -f ${BUILD_DIR}/${PART}.bin ]; then
    echo 'Generating chipdb for ${PART}...'
    cd ${BUILD_DIR}
    python3 ${NEXTPNR_PYTHON}/bbaexport.py --device ${PART} --bba ${PART}.bba
    ${BIN_PATH}/bbasm -l ${PART}.bba ${PART}.bin
    /bin/rm -f ${PART}.bba
else
    echo 'Chipdb already exists'
fi
"

echo "=== Step 3: Place and Route ==="
run_docker "nextpnr-xilinx --json ${BUILD_DIR}/${PROJECT}.json --xdc constraints/cmod_a7.xdc --chipdb ${BUILD_DIR}/${PART}.bin --fasm ${BUILD_DIR}/${PROJECT}.fasm"

echo "=== Step 4: Convert FASM to frames ==="
# Run without user mapping and copy file out (permission workaround)
chmod 777 ${BUILD_DIR} 2>/dev/null || true
CONTAINER_ID=$(docker run -d \
    -v /Users/yak/Projects/Claude/cmod7:/work \
    -w /work \
    ${DOCKER_IMAGE} \
    /bin/bash -c "python3 ${BIN_PATH}/fasm2frames --part ${PART} --db-root ${PRJXRAY_DB}/artix7 ${BUILD_DIR}/${PROJECT}.fasm /tmp/${PROJECT}.frames && sleep 2")
docker wait $CONTAINER_ID > /dev/null
docker cp $CONTAINER_ID:/tmp/${PROJECT}.frames ${BUILD_DIR}/${PROJECT}.frames
docker rm $CONTAINER_ID > /dev/null

echo "=== Step 5: Generate bitstream ==="
run_docker "/home/builder/.local/usr/local/bin/xc7frames2bit --part_file ${PRJXRAY_DB}/artix7/${PART}/part.yaml --part_name ${PART} --frm_file ${BUILD_DIR}/${PROJECT}.frames --output_file ${BUILD_DIR}/${PROJECT}.bit"

echo "=== Build Complete! ==="
ls -lh build/${PROJECT}.bit
