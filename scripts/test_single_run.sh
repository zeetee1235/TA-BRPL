#!/bin/bash
# Quick test - single scenario
set -e

PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
cd "$PROJECT_DIR"

SIM_TIME=120  # 2 minute test
SEED=123456
RUN_NAME="test_run"
RESULTS_BASE="results/test-$(date +%Y%m%d-%H%M%S)"
RUN_DIR="$RESULTS_BASE/$RUN_NAME"

mkdir -p "$RUN_DIR"

echo "============================================"
echo "Quick Test - Single Simulation"
echo "============================================"

# Setup env
source scripts/setup_env.sh

# Build motes if missing (config uses contikiapp paths)
echo "▶️  Building motes..."
rm -rf motes/build 2>/dev/null || true
cd motes
make -f Makefile.receiver receiver_root.cooja TARGET=cooja DEFINES="BRPL_MODE=1" 2>&1 | grep -E "CC|LD" || true
make -f Makefile.sender sender.cooja TARGET=cooja DEFINES="BRPL_MODE=1,SEND_INTERVAL_SECONDS=10,WARMUP_SECONDS=10" 2>&1 | grep -E "CC|LD" || true
make -f Makefile.attacker attacker.cooja TARGET=cooja DEFINES="BRPL_MODE=1,ATTACK_DROP_PCT=50,WARMUP_SECONDS=10" 2>&1 | grep -E "CC|LD" || true
cd "$PROJECT_DIR"

# Create temp config
TEMP_CONFIG="$PROJECT_DIR/configs/temp_${RUN_NAME}.csc"
SIM_TIME_MS=$((SIM_TIME * 1000))

sed -e "s/<randomseed>[0-9]*<\/randomseed>/<randomseed>$SEED<\/randomseed>/g" \
    -e "s/@SIM_TIME_MS@/${SIM_TIME_MS}/g" \
    -e "s/@SIM_TIME_SEC@/${SIM_TIME}/g" \
    -e "s/WARMUP_SECONDS=120/WARMUP_SECONDS=10/g" \
    -e "s/SEND_INTERVAL_SECONDS=30/SEND_INTERVAL_SECONDS=10/g" \
    "$PROJECT_DIR/configs/simulation.csc" > "$TEMP_CONFIG"

# Disable SerialSocketServer for headless runs (sandbox/network restrictions)
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

echo "✓ Config created: $TEMP_CONFIG"
echo "✓ Seed: $SEED"

# Run simulation
LOG_DIR="$PROJECT_DIR/$RUN_DIR/logs"
mkdir -p "$LOG_DIR"

echo "▶️  Running simulation (60 seconds)..."

timeout 100 java --enable-preview -Xmx4G -Xms2G \
    -jar "$CONTIKI_NG_PATH/tools/cooja/build/libs/cooja.jar" \
    --no-gui \
    --autostart \
    --contiki="$CONTIKI_NG_PATH" \
    --logdir="$LOG_DIR" \
    "$TEMP_CONFIG" > "$PROJECT_DIR/$RUN_DIR/cooja_output.log" 2>&1

echo "✓ Simulation complete"

# Clean up
rm -f "$TEMP_CONFIG"

# Check results
if [ -f "$LOG_DIR/COOJA.testlog" ]; then
    echo "✓ Log file created"
    python3 tools/parse_results.py "$LOG_DIR/COOJA.testlog" > "$RUN_DIR/analysis.txt" 2>&1 || true
    cat "$RUN_DIR/analysis.txt"
else
    echo "❌ No log file found"
    cat "$PROJECT_DIR/$RUN_DIR/cooja_output.log"
fi

echo ""
echo "Results directory: $RUN_DIR"
