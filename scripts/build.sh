#!/bin/bash
# 빌드 스크립트

set -e  # 에러 발생 시 즉시 종료

echo "============================================"
echo "Building Trust-Aware BRPL Project"
echo "============================================"

# Contiki-NG 경로 확인
if [ -z "$CONTIKI_NG_PATH" ]; then
    echo "Error: CONTIKI_NG_PATH not set"
    echo "Please set it: export CONTIKI_NG_PATH=/path/to/contiki-ng"
    exit 1
fi

echo "Contiki-NG path: $CONTIKI_NG_PATH"
echo ""

# 프로젝트 디렉토리로 이동
PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
cd "$PROJECT_DIR"

echo "Building for Cooja..."
echo ""

# Receiver (Root) 빌드
echo "[1/2] Building receiver_root..."
cd motes
make -f Makefile.receiver TARGET=cooja clean
make -f Makefile.receiver TARGET=cooja -j

if [ $? -ne 0 ]; then
    echo "Error: receiver_root build failed"
    exit 1
fi
echo "✓ receiver_root build successful"
echo ""

# Sender 빌드
echo "[2/3] Building sender..."
make -f Makefile.sender TARGET=cooja clean
make -f Makefile.sender TARGET=cooja -j

if [ $? -ne 0 ]; then
    echo "Error: sender build failed"
    exit 1
fi
echo "✓ sender build successful"
echo ""

# Attacker 빌드
echo "[3/3] Building attacker..."
make -f Makefile.attacker TARGET=cooja clean
make -f Makefile.attacker TARGET=cooja -j

if [ $? -ne 0 ]; then
    echo "Error: attacker build failed"
    exit 1
fi
echo "✓ attacker build successful"
echo ""

cd "$PROJECT_DIR"

echo "============================================"
echo "Build completed successfully!"
echo "============================================"
echo ""
echo "Next steps:"
echo "  1. Open Cooja: cd \$CONTIKI_NG_PATH && ./gradlew run"
echo "  2. Load simulation: File → Open → configs/simulation.csc"
echo "  3. Start simulation: Simulation → Start"
echo ""
echo "Or use: ./scripts/run_simulation.sh"
