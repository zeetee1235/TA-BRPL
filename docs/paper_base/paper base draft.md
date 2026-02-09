
---

## 0) 논문 포지셔닝 한 줄

**“RPL/BRPL 기반 LLN에서 selective forwarding·sinkhole 공격 하에서, trust-aware backpressure routing이 성능 붕괴 임계점을 얼마나 늦추는지 정량 평가”**

---

## 1) Title / Abstract / Keywords

### Title (예시)

- _Trust-Aware Backpressure RPL for Resilient Routing in Low-Power and Lossy Networks under Routing Attacks_
    
- _Mitigating Selective Forwarding and Sinkhole Attacks in RPL/BRPL using Trust-Integrated Backpressure_
    

### Abstract 구성(4문장 템플릿)

1. 배경: LLN에서 RPL/BRPL이 공격에 취약
    
2. 제안: BRPL 의사결정에 trust penalty를 통합
    
3. 방법: Contiki-NG/Cooja에서 공격 강도 스윕 + 토폴로지/스케일별 비교
    
4. 결과: PDR 유지, parent churn 감소/증가, 지연·오버헤드 trade-off, 임계 attack rate 변화
    

Keywords: RPL, BRPL, Backpressure, Trust, LLN, IoT Security, Selective Forwarding, Sinkhole, Contiki-NG, Cooja

---

## 2) Introduction

### 2.1 Problem statement

- LLN에서 라우팅은 **에너지·링크 품질·혼잡**에 민감
    
- BRPL은 혼잡/큐 기반으로 경로 다양성을 늘리지만, **신뢰성(공격/드랍)**은 기본적으로 고려하지 않음
    
- selective forwarding / sinkhole은 **지표(PDR 등)로 관측되기 어려운 구간**이 존재 → “언제부터 무너지나”가 중요
    

### 2.2 Contributions (3~4개로 칼같이)

- (C1) **Trust-aware BRPL**: backpressure routing metric에 trust penalty를 통합한 경량 설계
    
- (C2) **공격 모델 구현**: grayhole/blackhole(선택적 드랍), sinkhole(부모 유인/랭크 조작 등) 시나리오 구현 및 재현 가능한 스윕 파이프라인
    
- (C3) **정량 평가**: 여러 토폴로지/규모(S/M/L)에서 attack rate 스윕 → PDR/지연/오버헤드/parent switch/경로 안정성 비교
    
- (C4) **trade-off 분석**: λ(민감도) 스윕으로 “성능 vs 안전” 조절 가능함을 실험적으로 제시
    

### 2.3 Paper organization

- II 배경, III 설계, IV 공격모델, V 실험설정, VI 결과, VII 논의, VIII 결론
    

---

## 3) Background & Related Work

### 3.1 RPL 요약

- DODAG, rank, parent selection, trickle
    
- LLN 특성: lossy, low power, constrained
    

### 3.2 BRPL 요약

- backpressure routing 개념(큐 차이 + 경로 비용)
    
- BRPL이 주는 장점(혼잡 회피/부하분산)과 한계(보안/신뢰 고려 부재)
    

### 3.3 Trust-based routing (짧게)

- trust metric(행동 기반/평판 기반), watchdog 류의 어려움(무선 loss, overhearing 문제)
    
- **본 논문은 “경량 trust 점수”를 routing penalty로 넣는 쪽**에 초점 (IDS/crypto 대체가 아니라 보완)
    

> 여기서는 “네가 실제로 인용할 논문들”을 나중에 레퍼런스 확정하면서 촘촘히 박으면 됨. (지금은 뼈대만)

---

## 4) System & Threat Model

### 4.1 System model

- Contiki-NG, Cooja, 6LoWPAN/IPv6, RPL/BRPL stack
    
- Traffic pattern: periodic sensor-to-root / many-to-one (기본)
    

### 4.2 Threat model

- **Selective forwarding**: 특정 비율로 패킷 드랍(attack rate)
    
- **Sinkhole**: 더 좋은 경로처럼 보이게 만들어 트래픽을 빨아들임 (rank/advertisement 조작 또는 metric 악용)
    
- Attacker capabilities: 내부 노드(합법 노드), root는 정상, 암호화/인증은 기본 가정 X(또는 “out of scope”)
    

---

## 5) Trust-Aware BRPL Design

이 파트가 논문의 심장. “BRPL의 어떤 수식/의사결정 지점에 trust가 들어가고, 왜 그렇게 넣었는지”를 **수식+알고리즘**으로 박아.

### 5.1 Trust metric definition

- 노드 i가 이웃 j를 평가: (T_{ij}\in[0,1])
    
- 업데이트: (예) 성공 포워딩/관측 기반 EWMA, 또는 드랍/전달률 기반
    
- 관측 잡음(링크 loss) 때문에 **완전한 watchdog가 아니라 “통계적 노이즈 허용”** 강조
    

### 5.2 Integration into BRPL

- BRPL의 parent/next-hop score: (기존) backpressure term + path cost
    
- (제안) trust penalty term 추가:
    
    - 예: (Score_{ij} = BP_{ij} - \lambda\cdot f(T_{ij})) 또는 비용에 더하기
        
- λ의 의미: 공격 회피 민감도(보수적 vs 공격적)
    
- trust가 낮은 노드는 **부모 선택 확률/우선순위가 떨어짐**
    

### 5.3 Algorithm (Pseudo-code)

- 입력: neighbor table, queue length, rank/cost, trust table
    
- 출력: preferred parent / forwarding decision
    
- 꼭 넣을 것:
    
    - trust 업데이트 타이밍(패킷 전송/ACK/통계 주기)
        
    - 하한/상한 클리핑, 초기값, cold-start 처리
        
    - parent switching 억제(히스테리시스) 옵션
        

### 5.4 Complexity & overhead

- 메모리: neighbor당 trust 1개
    
- 연산: parent selection 시 O(deg)
    
- control overhead: 추가 메시지 없거나(로컬 관측) 있더라도 경량
    

---

## 6) Implementation in Contiki-NG

- 어디를 수정했는지: BRPL metric 계산부/parent selection hook/trust_engine 모듈
    
- 공격 노드 동작 구현:
    
    - selective forwarding: 확률 p로 드랍
        
    - sinkhole: metric/rank advertise 조작(구현 방식 명시)
        
- 재현성:
    
    - seeds, scripts(run_experiments.sh), 로그(exposure.csv 등)
        

**그림(필수)**

- Fig.1: 소프트웨어 구조도(Contiki stack + trust module 위치)
    
- Fig.2: trust update 흐름(상태머신/타임라인)
    

---

## 7) Experimental Setup

### 7.1 Topologies & scales

- 3~4개 토폴로지 × S/M/L (네가 말했던 구상 그대로)
    
- 공격자 위치/개수 명시(좌표까지 표로)
    
- 링크 모델(UDGM/MRM), radio range, interference 설정
    

### 7.2 Traffic & parameters

- packet interval, payload, simulation time, warm-up
    
- attack rate sweep: 0/30/50/70 등
    
- λ sweep(예: 0, 0.5, 1, 2 …) 또는 네가 쓰는 범위
    

### 7.3 Baselines

- RPL
    
- BRPL (no-trust)
    
- Trust-Aware BRPL (proposed)
    
- (선택) 공격 없는 trust-only(정상에서의 비용)
    

### 7.4 Metrics

- PDR (end-to-end)
    
- End-to-end delay / RTT
    
- Control overhead (DIO/DAO/전송량)
    
- Parent switch count / churn
    
- Path stretch or hop count
    
- Energy proxy(송신/수신 횟수)
    

**표(필수)**

- Table 1: 파라미터 요약
    
- Table 2: 토폴로지/공격자 좌표/노드 수
    

---

## 8) Results

이 섹션은 “그림으로 먹고 들어가는” 파트라 구조를 딱 잡아야 해.

### 8.1 Attack rate에 따른 PDR 곡선

- 토폴로지별로 PDR vs attack rate
    
- “임계점(갑자기 무너지는 구간)”을 강조
    

### 8.2 Delay & overhead trade-off

- trust가 높아질수록 우회로 선택 → delay/오버헤드 변화
    
- λ sweep로 곡선 패밀리 만들면 논문 느낌 확 올라감
    

### 8.3 Stability (parent switching)

- 공격 시 BRPL이 흔들리는지 vs trust-aware가 안정화시키는지
    
- parent_switch.csv 기반으로 정량
    

### 8.4 Sinkhole 시나리오 별도 결과

- sinkhole에서 “트래픽 집중/병목”이 생기는지
    
- trust가 sinkhole로의 흡입을 얼마나 막는지
    

**그림 추천(최소 6~8개)**

- Fig.3 PDR vs attack rate (topology별)
    
- Fig.4 Delay vs attack rate
    
- Fig.5 Overhead vs attack rate
    
- Fig.6 Parent switch count
    
- Fig.7 λ sweep에서 PDR/Delay 트레이드오프
    
- Fig.8 시간축 타임시리즈(초반 안정화→공격 시작→붕괴 여부)
    

---

## 9) Discussion

- 왜 특정 토폴로지에서 효과가 덜/더 나왔는가 (path diversity, attacker centrality)
    
- trust 오탐/미탐(링크 loss를 공격으로 오인) 가능성
    
- 파라미터 민감도(λ, 업데이트 윈도우)
    
- 한계:
    
    - Collusion, wormhole 등은 범위 밖
        
    - 완전한 보안(인증/암호) 대체가 아니라 resilience 향상
        

---

## 10) Conclusion & Future Work

- 결론: trust penalty 통합이 공격 하에서 성능 붕괴를 늦추고 안정성을 개선
    
- Future:
    
    - 멀티 공격자/협력 공격
        
    - 적응형 λ(상황별 자동 튜닝)
        
    - 다른 LLN 스택 또는 testbed 실험
        

---

