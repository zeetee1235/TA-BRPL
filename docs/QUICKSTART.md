# Trust-Aware BRPL - Quick Start Guide

## 빠른 시작

### 1. 환경 변수 설정
```bash
source scripts/setup_env.sh
```

### 2. 빌드
```bash
./scripts/build.sh
```

### 3. Headless 모드로 시뮬레이션 실행
```bash
./scripts/run_simulation.sh 600  # 10분 실행
```

### 3-1. Phase 3 자동 비교 (정상 vs 공격)
```bash
./scripts/run_phase3.sh 600
```

**또는 GUI 모드로 실행** (디버깅용):
```bash
./scripts/run_cooja_gui.sh
# Start 버튼 클릭
```

### 4. 결과 분석
```bash
python3 tools/parse_results.py logs/COOJA.testlog
```

**자동 저장 위치**
- `results/run-YYYYMMDD-HHMMSS/` (개별 실행)
- `results/phase3-YYYYMMDD-HHMMSS/` (정상 vs 공격 비교)

---

## 현재 구현 상태

✅ **완료된 작업**
- [x] BRPL Objective Function (brpl-of.c)
- [x] RPL Root + UDP Receiver (receiver_root.c)
- [x] Sensor Sender (sender.c)
- [x] Selective Forwarding 공격 노드 (attacker.c)
- [x] Trust 계산 (EWMA)
- [x] Trust 기반 Parent 선택
- [x] Cooja 시뮬레이션 설정 (normal/attack)
- [x] 빌드 스크립트
- [x] 결과 분석 스크립트

📋 **다음 단계**
- [ ] 결과 시각화 (matplotlib)

---

## 네트워크 구성

- **노드 수**: 8개 (Root 1 + Attacker 1 + Sender 6)
- **토폴로지**: Multi-hop with redundant paths
- **전송 주기**: 30초
- **Warmup 시간**: 120초

---

## 주요 파라미터

### project-conf.h
```c
#define SEND_INTERVAL_SECONDS 30    // 패킷 전송 주기
#define WARMUP_SECONDS 120          // 네트워크 안정화
#define BRPL_QUEUE_WEIGHT (...)     // BRPL 큐 페널티
```

### configs/simulation.csc
- Radio range: 50m
- Interference range: 100m
- Success ratio: 1.0 (100%)

### configs/simulation_normal.csc / simulation_attack.csc
- Node 3: 공격 노드 (attack 시 drop=50%)
- normal/attack 비교를 위한 별도 시뮬 파일

---

## 성능 지표

### 측정 항목
1. **PDR (Packet Delivery Ratio)**
   - 전송 성공률
   - 목표: > 95%

2. **End-to-End Delay**
   - RTT 기반 측정
   - 목표: < 100ms

3. **Overhead**
   - RPL 제어 패킷 수
   - Control/Data ratio

---

## 파일 설명

| 파일 | 설명 |
|------|------|
| `brpl-of.c` | BRPL Objective Function (큐 기반 backpressure) |
| `project-conf.h` | 프로젝트 설정 및 파라미터 |
| `motes/receiver_root.c` | RPL Root + UDP Receiver (Sink) |
| `motes/sender.c` | Sensor node (주기적 데이터 전송) |
| `configs/simulation.csc` | Cooja 시뮬레이션 설정 |
| `tools/parse_results.py` | 성능 지표 분석 스크립트 |
| `scripts/build.sh` | 빌드 자동화 |
| `scripts/run_simulation.sh` | 시뮬레이션 자동 실행 |

---

## 트러블슈팅

### 빌드 오류
```bash
# Contiki-NG 경로 확인
echo $CONTIKI_NG_PATH

# 수동 빌드
cd motes
make -f Makefile.receiver TARGET=cooja
```

### 시뮬레이션 오류
- Java 버전 확인: `java -version` (OpenJDK 11+ 권장)
- Cooja 빌드: `cd $CONTIKI_NG_PATH && ./gradlew jar`

### 노드 연결 안됨
- WARMUP_SECONDS 증가 (120 → 180초)
- Radio range 확인 (configs/simulation.csc)

---

## 연락처 & 참고자료

- Contiki-NG: https://github.com/contiki-ng/contiki-ng
- RPL-lite: `$CONTIKI_NG_PATH/os/net/routing/rpl-lite/`
- Cooja Manual: https://docs.contiki-ng.org/en/develop/doc/tutorials/Running-Contiki-NG-in-Cooja.html
