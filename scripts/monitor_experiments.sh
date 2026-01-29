#!/bin/bash
# Real-time experiment progress monitor

# Find latest experiment directory
LATEST=$(ls -td results/experiments-* 2>/dev/null | head -1)

if [ -z "$LATEST" ]; then
    echo "No experiment directory found!"
    exit 1
fi

echo "============================================"
echo "Monitoring: $LATEST"
echo "============================================"
echo ""

# Watch mode
if [ "$1" == "--watch" ] || [ "$1" == "-w" ]; then
    while true; do
        clear
        echo "============================================"
        echo "실시간 모니터링: $LATEST"
        echo "업데이트: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "============================================"
        echo ""
        
        # Count completed runs
        COMPLETED=$(ls -1d "$LATEST"/*/analysis.txt 2>/dev/null | wc -l)
        TOTAL=$(find "$LATEST" -maxdepth 1 -type d | wc -l)
        TOTAL=$((TOTAL - 1))  # Exclude parent dir
        
        if [ $TOTAL -gt 0 ]; then
            PROGRESS=$((COMPLETED * 100 / TOTAL))
            echo "📊 진행도: $COMPLETED / $TOTAL 완료 ($PROGRESS%)"
        else
            echo "📊 진행도: 시작 대기 중..."
        fi
        
        # Show recent activity
        echo ""
        echo "📝 최근 5개 실행:"
        ls -td "$LATEST"/*/ 2>/dev/null | head -5 | while read dir; do
            name=$(basename "$dir")
            if [ -f "$dir/analysis.txt" ]; then
                pdr=$(grep "Overall:.*PDR=" "$dir/analysis.txt" | sed -n 's/.*PDR=\s*\([0-9.]*\)%.*/\1/p' 2>/dev/null)
                echo "  ✅ $name (PDR: ${pdr:-N/A}%)"
            elif [ -f "$dir/cooja_output.log" ]; then
                echo "  ⏳ $name (실행 중...)"
            else
                echo "  ⏺️  $name (대기 중)"
            fi
        done
        
        # Check if still running
        if ! pgrep -f "run_experiments.sh" > /dev/null; then
            echo ""
            echo "⚠️  실험 프로세스가 실행 중이 아닙니다"
            break
        fi
        
        sleep 5
    done
else
    # Single check mode
    COMPLETED=$(ls -1d "$LATEST"/*/analysis.txt 2>/dev/null | wc -l)
    TOTAL=$(find "$LATEST" -maxdepth 1 -type d | wc -l)
    TOTAL=$((TOTAL - 1))
    
    echo "📊 진행도: $COMPLETED / $TOTAL 완료"
    echo ""
    echo "최근 완료:"
    ls -td "$LATEST"/*/analysis.txt 2>/dev/null | head -3 | while read file; do
        dir=$(dirname "$file")
        name=$(basename "$dir")
        pdr=$(grep "Overall:.*PDR=" "$file" | sed -n 's/.*PDR=\s*\([0-9.]*\)%.*/\1/p')
        echo "  • $name: PDR=${pdr}%"
    done
    
    echo ""
    echo "실시간 모니터링: ./scripts/monitor_experiments.sh --watch"
    echo "로그 보기: tail -f experiment_log.txt"
fi
