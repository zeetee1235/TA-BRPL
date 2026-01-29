#!/bin/bash
# Quick test - 2 scenarios, 1 seed, short duration

set -e

PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
cd "$PROJECT_DIR"

# Configuration - MINIMAL FOR TESTING
SIM_TIME=120  # 2 minutes
SEEDS=(123456)  # Just 1 seed
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
RESULTS_BASE="results/quicktest-$TIMESTAMP"

mkdir -p "$RESULTS_BASE"

# Only 2 scenarios
declare -A SCENARIOS=(
    ["1_brpl_normal"]="BRPL,0"
    ["2_brpl_attack"]="BRPL,50"
)

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Summary file
SUMMARY_FILE="$RESULTS_BASE/summary.csv"
echo "scenario,seed,pdr,avg_delay_ms,tx,rx,lost" > "$SUMMARY_FILE"

TOTAL_RUNS=$((${#SCENARIOS[@]} * ${#SEEDS[@]}))
CURRENT_RUN=0

log_info "============================================"
log_info "Quick Test - 2 Scenarios × 1 Seed"
log_info "============================================"
log_info "Duration: ${SIM_TIME}s per run"
log_info "Total runs: $TOTAL_RUNS"
log_info "Results: $RESULTS_BASE"
log_info ""

# Setup
source scripts/setup_env.sh

# Run
for scenario_name in $(echo "${!SCENARIOS[@]}" | tr ' ' '\n' | sort); do
    IFS=',' read -r routing attack_rate <<< "${SCENARIOS[$scenario_name]}"
    
    for seed in "${SEEDS[@]}"; do
        CURRENT_RUN=$((CURRENT_RUN + 1))
        
        RUN_NAME="${scenario_name}_s${seed}"
        RUN_DIR="$RESULTS_BASE/$RUN_NAME"
        mkdir -p "$RUN_DIR"
        
        log_info "[$CURRENT_RUN/$TOTAL_RUNS] Running: $RUN_NAME"
        log_info "  Routing: $routing | Attack: ${attack_rate}% | Seed: $seed"
        
        # Create temp config
        TEMP_CONFIG="$PROJECT_DIR/configs/temp_${RUN_NAME}.csc"
        SIM_TIME_MS=$((SIM_TIME * 1000))
        
        sed -e "s/<randomseed>[0-9]*<\/randomseed>/<randomseed>$seed<\/randomseed>/g" \
            -e "s/@SIM_TIME_MS@/${SIM_TIME_MS}/g" \
            -e "s/@SIM_TIME_SEC@/${SIM_TIME}/g" \
            "$PROJECT_DIR/configs/simulation.csc" > "$TEMP_CONFIG"
        
        # Run simulation
        LOG_DIR="$PROJECT_DIR/$RUN_DIR/logs"
        mkdir -p "$LOG_DIR"
        
        timeout 200 java --enable-preview -Xmx4G -Xms2G \
            -jar "$CONTIKI_NG_PATH/tools/cooja/build/libs/cooja.jar" \
            --no-gui \
            --autostart \
            --contiki="$CONTIKI_NG_PATH" \
            --logdir="$LOG_DIR" \
            "$TEMP_CONFIG" > "$PROJECT_DIR/$RUN_DIR/cooja_output.log" 2>&1 || {
            log_error "Simulation failed for $RUN_NAME"
            rm -f "$TEMP_CONFIG"
            continue
        }
        
        rm -f "$TEMP_CONFIG"
        
        # Parse results
        if [ -f "$LOG_DIR/COOJA.testlog" ]; then
            python3 tools/parse_results.py "$LOG_DIR/COOJA.testlog" > "$RUN_DIR/analysis.txt" 2>&1 || true
            
            PDR=$(grep "Overall:.*PDR=" "$RUN_DIR/analysis.txt" | sed -n 's/.*PDR=\s*\([0-9.]*\)%.*/\1/p' || echo "0")
            AVG_DELAY=$(grep "Average:" "$RUN_DIR/analysis.txt" | awk '{print $2}' || echo "0")
            TX=$(grep "Overall:.*TX=" "$RUN_DIR/analysis.txt" | sed -n 's/.*TX=\s*\([0-9]*\).*/\1/p' || echo "0")
            RX=$(grep "Overall:.*RX=" "$RUN_DIR/analysis.txt" | sed -n 's/.*RX=\s*\([0-9]*\).*/\1/p' || echo "0")
            LOST=$(grep "Overall:.*Lost=" "$RUN_DIR/analysis.txt" | sed -n 's/.*Lost=\s*\([0-9]*\).*/\1/p' || echo "0")
            
            echo "$scenario_name,$seed,$PDR,$AVG_DELAY,$TX,$RX,$LOST" >> "$SUMMARY_FILE"
            
            log_info "  ✓ PDR=${PDR}% TX=$TX RX=$RX"
        fi
    done
done

log_info ""
log_info "============================================"
log_info "Quick test complete!"
log_info "Results: $RESULTS_BASE"
log_info "============================================"

cat "$SUMMARY_FILE"
