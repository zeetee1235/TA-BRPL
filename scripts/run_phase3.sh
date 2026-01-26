#!/bin/bash
set -e

SIM_TIME_SEC=${1:-600}
PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
RESULTS_DIR="$PROJECT_DIR/results"
PHASE_DIR="$RESULTS_DIR/phase3-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$PHASE_DIR"

run_and_capture() {
  local sim_file="$1"
  local tmp_log
  tmp_log=$(mktemp)
  "$PROJECT_DIR/scripts/run_simulation.sh" "$SIM_TIME_SEC" "$sim_file" | tee "$tmp_log" 1>&2
  sed -n 's/^Results saved to: //p' "$tmp_log" | tail -n 1
  rm -f "$tmp_log"
}

echo "Running NORMAL scenario..."
NORMAL_RUN_DIR=$(run_and_capture "$PROJECT_DIR/configs/simulation_normal.csc")

if [ -z "$NORMAL_RUN_DIR" ]; then
  echo "Failed to detect normal run output directory"
  exit 1
fi


echo "Running ATTACK scenario..."
ATTACK_RUN_DIR=$(run_and_capture "$PROJECT_DIR/configs/simulation_attack.csc")

if [ -z "$ATTACK_RUN_DIR" ]; then
  echo "Failed to detect attack run output directory"
  exit 1
fi

cp -f "$NORMAL_RUN_DIR/COOJA.testlog" "$PHASE_DIR/normal.COOJA.testlog"
cp -f "$ATTACK_RUN_DIR/COOJA.testlog" "$PHASE_DIR/attack.COOJA.testlog"

python3 "$PROJECT_DIR/tools/compare_scenarios.py" \
  "$PHASE_DIR/normal.COOJA.testlog" \
  "$PHASE_DIR/attack.COOJA.testlog" \
  "$PHASE_DIR"

echo "Phase 3 results saved to: $PHASE_DIR"
