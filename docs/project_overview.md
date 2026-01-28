# Project Overview: Trust-Aware BRPL (Selective Forwarding)

## 목적
- BRPL(RPL-lite 기반) 환경에서 Selective Forwarding 공격을 시뮬레이션하고, Trust 기반 방어/평가를 수행한다.
- Cooja 시뮬레이터를 사용해 실험을 자동화하고 로그를 수집/분석한다.
- 외부 Trust Engine(Rust)을 통해 로그 기반 trust 계산 및 피드백 주입을 지원한다.

## 전체 구조 요약
```
trust-aware-brpl/
├── brpl-of.c                  # BRPL OF(ETX+Queue penalty) + Trust 필터링
├── project-conf.h             # BRPL 모드, Trust 파라미터, 로그 레벨
├── configs/                   # Cooja 시뮬레이션(.csc)
├── motes/                     # Root/Sender/Attacker mote 코드
├── scripts/                   # 실행/배치/토폴로지 생성 스크립트
├── tools/                     # 결과 분석 + 외부 Trust Engine
├── logs/                      # 실행 로그 (gitignore)
├── results/                   # 각 실행 결과 저장
├── docs/                      # 문서
└── readme.md                  # 기본 사용 안내
```

## 핵심 기능
### 1) 공격 시나리오 (Selective Forwarding)
- 공격 노드(attacker)가 **포워딩되는 UDP 패킷을 확률적으로 드롭**
- 드롭 대상: Root(aaaa::1)로 전달되는 UDP(포트 8765)
- 드롭 비율은 빌드 정의(ATTACK_DROP_PCT)로 제어
- 공격 상태/통계 로그 출력

### 2) Trust 계산 (내장)
- Root(receiver_root.c)에서 수신 seq 기반 **EWMA trust** 계산
- 계산식(요약)
  - missed = (seq gap)
  - sample = TRUST_SCALE / (1 + missed)
  - trust = alpha*sample + (1-alpha)*prev
- 로그: `CSV,TRUST,<node_id>,<seq>,<missed>,<trust>`

### 3) Trust 기반 Parent 선택 (BRPL OF)
- BRPL OF에서 **trust < TRUST_PARENT_MIN** 인 이웃을 parent 후보에서 배제
- ETX + queue penalty 기반 path cost와 결합

### 4) 외부 Trust Engine (Rust)
- Cooja 로그를 파싱하여 EWMA / Bayesian / Beta reputation 계산
- Trust 업데이트를 `logs/trust_updates.txt`로 출력
- ScriptRunner가 해당 파일을 폴링해 mote에 `TRUST,<node>,<value>` 주입
- 이상 탐지/블랙리스트: 임계치 기반으로 trust=0 주입

## 주요 컴포넌트 상세

### A) BRPL Objective Function
- 파일: `brpl-of.c`
- 기능:
  - ETX 기반 링크 신뢰도 + queue penalty
  - trust_table 유지, TRUST_PARENT_MIN 기준으로 parent 후보 제한
  - trust override API 제공: `brpl_trust_override()`

### B) Root (Sink)
- 파일: `motes/receiver_root.c`
- 기능:
  - RPL root 설정, UDP receiver
  - seq/RTT 로그 출력
  - EWMA trust 계산 및 CSV 출력

### C) Sender (Sensor)
- 파일: `motes/sender.c`
- 기능:
  - 주기적 UDP 전송 (seq + t0)
  - RTT 측정
  - preferred parent 로그
  - serial input으로 trust override 수신 (`TRUST,<node>,<value>`)

### D) Attacker
- 파일: `motes/attacker.c`
- 기능:
  - 포워딩 UDP 패킷 selective drop
  - preferred parent 로그
  - forwarding 통계(`CSV,FWD`)
  - serial input으로 trust override 수신

## 로그 포맷 요약
- 송신: `CSV,TX,<node>,<seq>,<t0>,<joined>`
- 수신: `CSV,RX,<ip>,<seq>,<t_recv>,<len>`
- RTT: `CSV,RTT,<seq>,<t0>,<t_ack>,<rtt>,<len>`
- Parent: `CSV,PARENT,<node>,<parent_ip|none>`
- Trust (root): `CSV,TRUST,<node>,<seq>,<missed>,<trust>`
- Trust override (mote): `CSV,TRUST_IN,<self>,<node>,<trust>`
- Forwarding stats: `CSV,FWD,<id>,<total>,<udp_to_root>,<dropped>`

## 시뮬레이션 설정
- 랜덤 토폴로지 생성기: `scripts/gen_random_topology.py`
  - 노드 수, 영역 크기, seed, 공격자 위치 고정 가능
- 기본 랜덤 시나리오(csc)
  - `configs/simulation_random_brpl_centered.csc`
  - `configs/simulation_random_brpl_centered_no_attack.csc`
  - `configs/simulation_random_mrhof_centered.csc`
  - `configs/simulation_random_mrhof_centered_no_attack.csc`

## 실행 스크립트
- `scripts/run_simulation.sh`
  - headless Cooja 실행
  - 결과를 `results/run-<timestamp>/`에 저장
  - `logs/COOJA.testlog` 생성
- `scripts/run_batch_compare.sh`
  - BRPL/MRHOF ON/OFF 여러 시드 배치 실행
  - 결과를 `results/batch-<timestamp>/` 구조로 저장

## 결과 분석
- Python: `tools/parse_results.py`
- R 요약: `tools/summary.R`

## 외부 Trust Engine (Rust)
- 위치: `tools/trust_engine`
- 기능
  - log 파싱(파일/serial socket)
  - EWMA/Bayes/Beta trust 계산
  - trust_updates.txt 출력
  - 이상탐지/블랙리스트 기록
- 출력
  - `logs/trust_updates.txt`
  - `logs/trust_metrics.csv`
  - `logs/blacklist.csv`

## 현재 상태 요약
- Selective forwarding 공격 구현 완료
- BRPL/MRHOF 기본 비교 실험 진행 중
- 외부 Trust Engine 연동(파일 폴링) 동작 확인
- headless 환경에서 SerialSocketServer는 제한되어 비활성화 필요

## 남은 확인/개선 포인트
- BRPL OF 로그 기반으로 trust→parent 배제 여부 검증 필요
- Cooja headless 환경의 JVM 크래시 원인 분석
- 패킷 필터링(blacklist drop)을 네트워크 계층에 추가 가능
