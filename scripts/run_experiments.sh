#!/bin/bash
# Comprehensive experiment runner for Trust-Aware BRPL research
# Runs 6 essential + 2 optional scenarios with varying attack rates and seeds

set -e

PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
cd "$PROJECT_DIR"

# Configuration
SIM_TIME=300  # 5 minutes per simulation
ATTACK_RATES=(30 50 70)  # Drop percentages (only for attack scenarios)
SEEDS=(123456 234567 345678 456789 567890)  # 5 seeds for statistical stability
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
RESULTS_BASE="results/experiments-$TIMESTAMP"

mkdir -p "$RESULTS_BASE"

# Scenarios definition: routing,has_attack,trust_enabled
# 6 ESSENTIAL scenarios only
declare -A SCENARIOS=(
    ["1_mrhof_normal_notrust"]="MRHOF,NO_ATTACK,0"
    ["2_brpl_normal_notrust"]="BRPL,NO_ATTACK,0"
    ["3_mrhof_attack_notrust"]="MRHOF,ATTACK,0"
    ["4_brpl_attack_notrust"]="BRPL,ATTACK,0"
    ["5_mrhof_attack_trust"]="MRHOF,ATTACK,1"
    ["6_brpl_attack_trust"]="BRPL,ATTACK,1"
)

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Summary file
SUMMARY_FILE="$RESULTS_BASE/experiment_summary.csv"
echo "scenario,routing,attack_rate,trust,seed,pdr,avg_delay_ms,tx,rx,lost" > "$SUMMARY_FILE"

# Progress tracking
TOTAL_RUNS=$((${#SCENARIOS[@]} * ${#ATTACK_RATES[@]} * ${#SEEDS[@]}))
CURRENT_RUN=0

log_info "============================================"
log_info "Trust-Aware BRPL Comprehensive Experiments"
log_info "============================================"
log_info "Total scenarios: ${#SCENARIOS[@]}"
log_info "Attack rates: ${ATTACK_RATES[@]}"
log_info "Seeds: ${#SEEDS[@]}"
log_info "Total runs: $TOTAL_RUNS"
log_info "Results directory: $RESULTS_BASE"
log_info ""

# Build if needed
if [ ! -f "motes/build/cooja/receiver_root.cooja" ]; then
    log_info "Building motes..."
    source scripts/setup_env.sh
    ./scripts/build.sh
fi

# Build trust_engine if needed
if [ ! -f "tools/trust_engine/target/release/trust_engine" ]; then
    log_info "Building trust_engine..."
    cd tools/trust_engine
    cargo build --release
    cd "$PROJECT_DIR"
fi

# Run experiments
for scenario_name in $(echo "${!SCENARIOS[@]}" | tr ' ' '\n' | sort); do
    IFS=',' read -r routing attack trust <<< "${SCENARIOS[$scenario_name]}"
    
    for attack_rate in "${ATTACK_RATES[@]}"; do
        # Skip attack scenarios when attack_rate=0
        if [ "$attack" == "ATTACK" ] && [ "$attack_rate" -eq 0 ]; then
            continue
        fi
        # Skip non-attack scenarios when attack_rate>0
        if [ "$attack" == "NO_ATTACK" ] && [ "$attack_rate" -gt 0 ]; then
            continue
        fi
        
        for seed in "${SEEDS[@]}"; do
            CURRENT_RUN=$((CURRENT_RUN + 1))
            PROGRESS=$((CURRENT_RUN * 100 / TOTAL_RUNS))
            
            RUN_NAME="${scenario_name}_p${attack_rate}_s${seed}"
            RUN_DIR="$RESULTS_BASE/$RUN_NAME"
            mkdir -p "$RUN_DIR"
            
            log_info "[$CURRENT_RUN/$TOTAL_RUNS] ${PROGRESS}% - Running: $RUN_NAME"
            log_info "  Routing: $routing | Attack: ${attack_rate}% | Trust: $trust | Seed: $seed"
            
            # Set environment
            export CONTIKI_NG_PATH=${CONTIKI_NG_PATH:-/home/dev/contiki-ng}
            export SERIAL_SOCKET_DISABLE=1
            export JAVA_OPTS="-Xmx4G -Xms2G"
            
            # Prepare simulation config
            if [ "$routing" == "BRPL" ]; then
                BRPL_MODE=1
            else
                BRPL_MODE=0
            fi
            
            # Select config file (use working simulation.csc as base)
            BASE_CONFIG="configs/simulation.csc"
            
            # Determine BRPL_MODE
            if [ "$routing" == "BRPL" ]; then
                BRPL_MODE=1
            else
                BRPL_MODE=0
            fi
            
            # Create temporary config with all modifications
            TEMP_CONFIG="$PROJECT_DIR/configs/temp_${RUN_NAME}.csc"
            SIM_TIME_MS=$((SIM_TIME * 1000))
            TRUST_FEEDBACK_FILE="$PROJECT_DIR/$RUN_DIR/trust_feedback.txt"
            
            # Replace all parameters
            sed -e "s/<randomseed>[0-9]*<\/randomseed>/<randomseed>$seed<\/randomseed>/g" \
                -e "s/@SIM_TIME_MS@/${SIM_TIME_MS}/g" \
                -e "s/@SIM_TIME_SEC@/${SIM_TIME}/g" \
                -e "s|@TRUST_FEEDBACK_PATH@|${TRUST_FEEDBACK_FILE}|g" \
                -e "s/BRPL_MODE=[0-9]/BRPL_MODE=${BRPL_MODE}/g" \
                -e "s/ATTACK_DROP_PCT=[0-9][0-9]*/ATTACK_DROP_PCT=${attack_rate}/g" \
                "$PROJECT_DIR/$BASE_CONFIG" > "$TEMP_CONFIG"

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
            
            # CRITICAL: Delete entire build directory to force full recompilation
            log_info "  Deleting build directory for clean slate..."
            rm -rf motes/build 2>/dev/null || true
            
            # Run simulation
            LOG_DIR="$PROJECT_DIR/$RUN_DIR/logs"
            mkdir -p "$LOG_DIR"
            
            # Start trust_engine in background if trust is enabled
            TRUST_ENGINE_PID=""
            if [ "$trust" -eq 1 ]; then
                log_info "  Starting trust_engine in real-time mode..."
                touch "$TRUST_FEEDBACK_FILE"
                touch "$LOG_DIR/COOJA.testlog"  # Pre-create log file for --follow mode
                tools/trust_engine/target/release/trust_engine \
                    --input "$LOG_DIR/COOJA.testlog" \
                    --output "$TRUST_FEEDBACK_FILE" \
                    --metrics-out "$PROJECT_DIR/$RUN_DIR/trust_metrics.csv" \
                    --blacklist-out "$PROJECT_DIR/$RUN_DIR/blacklist.csv" \
                    --metric ewma \
                    --alpha 0.2 \
                    --ewma-min 700 \
                    --miss-threshold 5 \
                    --follow > "$PROJECT_DIR/$RUN_DIR/trust_engine.log" 2>&1 &
                TRUST_ENGINE_PID=$!
                sleep 2
            fi
            
            timeout 400 java --enable-preview ${JAVA_OPTS} \
                -jar "$CONTIKI_NG_PATH/tools/cooja/build/libs/cooja.jar" \
                --no-gui \
                --autostart \
                --contiki="$CONTIKI_NG_PATH" \
                --logdir="$LOG_DIR" \
                "$TEMP_CONFIG" > "$PROJECT_DIR/$RUN_DIR/cooja_output.log" 2>&1
            COOJA_EXIT=$?
            
            if [ $COOJA_EXIT -ne 0 ]; then
                log_error "Simulation failed for $RUN_NAME (exit code: $COOJA_EXIT)"
                [ -n "$TRUST_ENGINE_PID" ] && kill -9 $TRUST_ENGINE_PID 2>/dev/null || true
                rm -f "$TEMP_CONFIG"
                continue
            fi
            
            # Stop trust_engine if it was running
            if [ -n "$TRUST_ENGINE_PID" ]; then
                sleep 2
                kill $TRUST_ENGINE_PID 2>/dev/null || true
                sleep 1
                kill -9 $TRUST_ENGINE_PID 2>/dev/null || true
                wait $TRUST_ENGINE_PID 2>/dev/null || true
                log_info "  Trust engine stopped"
            fi
            
            # Clean up temp config
            rm -f "$TEMP_CONFIG"
            
            # Parse results
            if [ -f "$LOG_DIR/COOJA.testlog" ]; then
                python3 tools/parse_results.py "$LOG_DIR/COOJA.testlog" > "$RUN_DIR/analysis.txt" 2>&1 || true
                
                # Extract metrics for summary
                PDR=$(grep "Overall:.*PDR=" "$RUN_DIR/analysis.txt" | sed -n 's/.*PDR=\s*\([0-9.]*\)%.*/\1/p' || echo "0")
                AVG_DELAY=$(grep "Average:" "$RUN_DIR/analysis.txt" | awk '{print $2}' || echo "0")
                TX=$(grep "Overall:.*TX=" "$RUN_DIR/analysis.txt" | sed -n 's/.*TX=\s*\([0-9]*\).*/\1/p' || echo "0")
                RX=$(grep "Overall:.*RX=" "$RUN_DIR/analysis.txt" | sed -n 's/.*RX=\s*\([0-9]*\).*/\1/p' || echo "0")
                LOST=$((TX - RX))
                
                echo "$scenario_name,$routing,$attack_rate,$trust,$seed,$PDR,$AVG_DELAY,$TX,$RX,$LOST" >> "$SUMMARY_FILE"
                
                log_info "  Results: PDR=${PDR}% | Delay=${AVG_DELAY}ms | TX=$TX | RX=$RX"
            fi
            
            log_info "  Completed: $RUN_NAME"
            echo ""
        done
    done
done

log_info "============================================"
log_info "All experiments completed!"
log_info "============================================"
log_info "Results saved to: $RESULTS_BASE"
log_info "Summary file: $SUMMARY_FILE"
log_info ""
log_info "Next steps:"
log_info "  1. Run R analysis: Rscript scripts/analyze_results.R $RESULTS_BASE"
log_info "  2. Check docs/report/ for figures"
log_info ""
