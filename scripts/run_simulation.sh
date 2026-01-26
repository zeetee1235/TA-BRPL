#!/bin/bash
# Cooja 시뮬레이션 headless 실행 스크립트

set -e

# Contiki-NG 경로 자동 설정
if [ -z "$CONTIKI_NG_PATH" ]; then
    export CONTIKI_NG_PATH=/home/dev/contiki-ng
fi

# Contiki-NG 경로 확인
if [ ! -d "$CONTIKI_NG_PATH" ]; then
    echo "Error: CONTIKI_NG_PATH directory not found: $CONTIKI_NG_PATH"
    exit 1
fi

# 프로젝트 디렉토리
PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
cd "$PROJECT_DIR"

# 시뮬레이션 파일 확인
SIMULATION_FILE="$PROJECT_DIR/configs/simulation.csc"
if [ ! -f "$SIMULATION_FILE" ]; then
    echo "Error: $SIMULATION_FILE not found"
    exit 1
fi

# 시뮬레이션 시간 설정 (초 단위)
SIM_TIME_SEC=${1:-600}  # 기본 10분
SIM_TIME_MS=$((SIM_TIME_SEC * 1000))

# 로그 파일
LOG_DIR="$PROJECT_DIR/logs"
LOG_FILE="COOJA.testlog"
mkdir -p "$LOG_DIR"

echo "============================================"
echo "Running Cooja in Headless Mode"
echo "============================================"
echo "Simulation file: $SIMULATION_FILE"
echo "Simulation time: ${SIM_TIME_SEC}s (${SIM_TIME_MS}ms)"
echo "Log output:      $LOG_DIR/$LOG_FILE"
echo "Cooja path:      $CONTIKI_NG_PATH"
echo ""

# 이전 로그 삭제
if [ -f "$LOG_DIR/$LOG_FILE" ]; then
    echo "Removing old log file..."
    rm -f "$LOG_DIR/$LOG_FILE"
fi

# JavaScript 스크립트 생성 (시뮬레이션 시간 설정)
SCRIPT_FILE="$PROJECT_DIR/configs/cooja_run.js"
cat > "$SCRIPT_FILE" << EOF
// Auto-generated Cooja script
TIMEOUT(${SIM_TIME_MS}, log.log("SIMULATION_FINISHED\\n"); log.testOK(); );
log.log("Headless simulation started\\n");
log.log("Duration: ${SIM_TIME_SEC}s\\n");
log.log("Nodes: " + sim.getMotesCount() + "\\n");
EOF

echo "Starting simulation..."
echo "(This will take approximately ${SIM_TIME_SEC} seconds)"
echo ""

# Headless 모드로 Cooja 실행
cd "$CONTIKI_NG_PATH"

java --enable-preview -jar tools/cooja/build/libs/cooja.jar \
    --no-gui \
    --autostart \
    --contiki="$CONTIKI_NG_PATH" \
    --logdir="$LOG_DIR" \
    "$SIMULATION_FILE" 2>&1 | tee "$LOG_DIR/cooja_output.log"

# 실행 결과 확인
if [ -f "$LOG_DIR/$LOG_FILE" ]; then
    echo ""
    echo "============================================"
    echo "Simulation completed successfully!"
    echo "============================================"
    echo "Log saved to: $LOG_DIR/$LOG_FILE"
    echo "Lines in log: $(wc -l < "$LOG_DIR/$LOG_FILE")"
    echo ""
    echo "Analyze results with:"
    echo "  python3 tools/parse_results.py $LOG_DIR/$LOG_FILE"
    echo ""
else
    echo ""
    echo "Warning: Log file not found!"
    echo "Check $LOG_DIR/cooja_output.log for errors"
fi

# cooja_run.js는 simulation.csc에서 참조하므로 삭제하지 않음
