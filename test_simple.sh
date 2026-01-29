#!/bin/bash
# 간단한 PDR 확인을 위한 빠른 테스트
cd /home/dev/WSN-IoT/trust-aware-brpl
echo "=== 실험 결과 요약 ===" 
echo ""
echo "실험 디렉토리: results/experiments-20260129-213802"
echo "총 실행: 60 runs"
echo ""
echo "CSV 데이터:"
head -1 results/experiments-20260129-213802/experiment_summary.csv
tail -10 results/experiments-20260129-213802/experiment_summary.csv
echo ""
echo "문제: PDR이 모두 0%"
echo "원인: Cooja 빌드 시스템 이슈 - pre-built 파일이 제대로 로드되지 않음"
echo ""
echo "해결 방안: run_experiments.sh에서 commands를 다시 활성화하고"
echo "            sed로 DEFINES를 직접 수정하는 방식"
