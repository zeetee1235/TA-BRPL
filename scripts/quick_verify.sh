#!/bin/bash

# Quick verification test - run 1 scenario to check PDR > 0

PROJECT_DIR="/home/dev/WSN-IoT/trust-aware-brpl"
cd "$PROJECT_DIR"

echo "=== Quick Verification Test ==="
echo "Testing: 1 scenario (MRHOF, attack 30%, no trust, seed 123)"

# Setup
export CONTIKI_NG_PATH=${CONTIKI_NG_PATH:-/home/dev/contiki-ng}
export SERIAL_SOCKET_DISABLE=1
export JAVA_OPTS="-Xmx4G -Xms2G"

SIM_TIME=600  # 10 minutes
BRPL_MODE=0   # MRHOF
ATTACK_RATE=30
SEED=123456
TRUST=0

# Clean
rm -rf motes/build 2>/dev/null || true
rm -rf test_temp 2>/dev/null || true
mkdir -p test_temp

# Create temp config
TEMP_CONFIG="$PROJECT_DIR/test_temp/test.csc"
SIM_TIME_MS=$((SIM_TIME * 1000))
TRUST_FILE="$PROJECT_DIR/test_temp/trust_feedback.txt"
touch "$TRUST_FILE"

sed -e "s/<randomseed>[0-9]*<\/randomseed>/<randomseed>$SEED<\/randomseed>/g" \
    -e "s/@SIM_TIME_MS@/${SIM_TIME_MS}/g" \
    -e "s/@SIM_TIME_SEC@/${SIM_TIME}/g" \
    -e "s|@TRUST_FEEDBACK_PATH@|${TRUST_FILE}|g" \
    -e "s/BRPL_MODE=[0-9]/BRPL_MODE=${BRPL_MODE}/g" \
    -e "s/ATTACK_DROP_PCT=[0-9][0-9]*/ATTACK_DROP_PCT=${ATTACK_RATE}/g" \
    "$PROJECT_DIR/configs/simulation.csc" > "$TEMP_CONFIG"

# Verify replacement
echo ""
echo "=== Checking config replacements ==="
grep "BRPL_MODE=" "$TEMP_CONFIG" | head -3
echo ""
grep "ATTACK_DROP_PCT=" "$TEMP_CONFIG" | head -1
echo ""

# Disable SerialSocket
awk '
  $0 ~ /<plugin>/ { in_plugin = 1; plugin_buf = $0; next }
  in_plugin && $0 ~ /org.contikios.cooja.serialsocket.SerialSocketServer/ { skip = 1 }
  in_plugin {
    plugin_buf = plugin_buf "\n" $0
    if($0 ~ /<\/plugin>/) {
      if(!skip) { print plugin_buf }
      in_plugin = 0; skip = 0; plugin_buf = ""
    }
    next
  }
  { print }
' "$TEMP_CONFIG" > "${TEMP_CONFIG}.tmp" && mv "${TEMP_CONFIG}.tmp" "$TEMP_CONFIG"

# Run
echo "=== Running simulation (10 min) ==="
timeout $((SIM_TIME + 120)) java --enable-preview -Xmx2G -Xms1G \
    -Djava.util.logging.config.file=/dev/null \
    -jar "$CONTIKI_NG_PATH/tools/cooja/build/libs/cooja.jar" \
    --no-gui --autostart --contiki="$CONTIKI_NG_PATH" \
    --logdir="$PROJECT_DIR/test_temp" \
    "$TEMP_CONFIG" 2>&1 | grep -E "INFO|TX_INFO" > test_temp/sim_log.txt

# Parse results
echo ""
echo "=== Parsing results ==="
tail -30 test_temp/COOJA.testlog | grep "TX_INFO:" || echo "No TX_INFO found"
echo ""

# Count packets
TX_COUNT=$(grep "TX_INFO:" test_temp/COOJA.testlog 2>/dev/null | wc -l || echo "0")
RX_COUNT=$(grep "RX_INFO:" test_temp/COOJA.testlog 2>/dev/null | wc -l || echo "0")

echo "TX packets: $TX_COUNT"
echo "RX packets: $RX_COUNT"

if [ "$RX_COUNT" -gt 0 ]; then
    echo ""
    echo "✅ SUCCESS! Packets are being received (PDR > 0%)"
    echo "Ready to run full experiments!"
else
    echo ""
    echo "❌ FAILED! No packets received (PDR = 0%)"
    echo "Need to debug further"
fi
