#!/bin/bash
# Simple progress monitor

while true; do
    clear
    echo "=================================================="
    echo "실험 진행 상황 - $(date '+%Y-%m-%d %H:%M:%S')"
    echo "=================================================="
    echo ""
    
    # Find latest experiment directory
    LATEST=$(ls -td results/experiments-* 2>/dev/null | head -1)
    
    if [ -z "$LATEST" ]; then
        echo "실험이 시작되지 않았습니다."
        sleep 5
        continue
    fi
    
    echo "디렉토리: $LATEST"
    echo ""
    
    # Count progress
    TOTAL=$(find "$LATEST" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l)
    COMPLETED=$(find "$LATEST" -name "analysis.txt" 2>/dev/null | wc -l)
    
    if [ $TOTAL -gt 0 ]; then
        PERCENT=$((COMPLETED * 100 / TOTAL))
        echo "진행: $COMPLETED / $TOTAL 완료 ($PERCENT%)"
    else
        echo "진행: 준비 중..."
    fi
    
    # Show last log line
    if [ -f "experiment_log.txt" ]; then
        echo ""
        echo "최근 로그:"
        tail -3 experiment_log.txt | sed 's/\x1b\[[0-9;]*m//g'
    fi
    
    # Check if still running
    echo ""
    if pgrep -f "run_experiments.sh" > /dev/null; then
        echo "상태: ✓ 실행 중"
    else
        echo "상태: ⚠ 종료됨"
        echo ""
        echo "완료! 결과 확인: cat $LATEST/experiment_summary.csv"
        break
    fi
    
    echo ""
    echo "중지: Ctrl+C | 자세히: tail -f experiment_log.txt"
    
    sleep 5
done
