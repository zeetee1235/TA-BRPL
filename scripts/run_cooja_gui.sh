#!/bin/bash
# Cooja GUI 모드로 실행 (디버깅/시각화용)

set -e

if [ -z "$CONTIKI_NG_PATH" ]; then
    echo "Error: CONTIKI_NG_PATH not set"
    echo "Please set it: export CONTIKI_NG_PATH=/path/to/contiki-ng"
    exit 1
fi

PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
SIMULATION_FILE="$PROJECT_DIR/configs/simulation.csc"

if [ ! -f "$SIMULATION_FILE" ]; then
    echo "Error: configs/simulation.csc not found"
    exit 1
fi

echo "Starting Cooja GUI..."
echo "Simulation file: $SIMULATION_FILE"
echo ""

cd "$CONTIKI_NG_PATH"

# GUI 모드로 실행
java --enable-preview -jar tools/cooja/build/libs/cooja.jar --gui "$SIMULATION_FILE"
