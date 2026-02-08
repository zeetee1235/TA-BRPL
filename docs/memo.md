**연구 메모: 실험 진행 방식 / Trust 계산 / 토폴로지 / 측정 지표**

**1. 실험 진행 방식 (Workflow)**
1. 토폴로지 `.csc`를 준비한다. 기본 위치: `configs/topologies/*.csc`.
1. 단일 검증: `scripts/single_test.sh`를 사용한다.
1. 전체 스윕: `scripts/run_experiments.sh`를 사용한다.
1. 결과는 `results/experiments-YYYYMMDD-HHMMSS/` 아래에 저장된다.
1. 각 run 디렉토리에는 `COOJA.testlog` 및 trust_engine 출력(`exposure.csv`, `parent_switch.csv`, `stats.csv`, `trust_final.log`)이 있다.

**2. 실험 실행 커맨드**
1. 전체 실행: `./scripts/run_experiments.sh`
1. 빠른 미리보기: `QUICK_PREVIEW=1 ./scripts/run_experiments.sh`
1. 특정 토폴로지만: `TOPOLOGIES="configs/topologies/CLUSTER_S.csc configs/topologies/GRID_L.csc" ./scripts/run_experiments.sh`
1. 단일 실행: `TOPOLOGY=configs/topologies/GRID_L.csc ./scripts/single_test.sh`

**3. 공통 실험 파라미터**
1. Field: 200m × 200m
1. Radio: UDGM Distance Loss
1. TX Range: 45m
1. Interference Range: 90m
1. Root ID: 1
1. Attacker ID: 2
1. 기본 SIM 시간: 600s
1. Warmup: 120s
1. 송신 간격: 30s
1. Quick preview 모드: `SIM_TIME=240s`, `WARMUP=10s`, `SEND_INTERVAL=10s`, seed=1

**4. 토폴로지 구성**
1. 사용 토폴로지: `configs/topologies/*.csc`
1. 이름 패턴:
1. `CLUSTER_{S,M,L}.csc`
1. `CORRIDOR_{S,M,L}.csc`
1. `GRID_{S,M,L}.csc`
1. `RING_{S,M,L}.csc`
1. 토폴로지 변경 시 `.csc` 내부 `<commands>`의 build 경로는 `make -C ../motes`로 유지해야 한다.
1. `<source>` 경로는 `[CONFIG_DIR]/../motes/...` 형태여야 한다.
1. `PROJECT_CONF_PATH=../project-conf.h` 사용.

**5. RPL 컨버전스 파라미터 (project-conf.h)**
1. `RPL_CONF_DIO_INTERVAL_MIN=8`
1. `RPL_CONF_DIO_INTERVAL_DOUBLINGS=10`
1. `RPL_CONF_DIO_REDUNDANCY=10`

**6. 공격 모델 (Attack Modes)**
1. `ATTACK_MODE=0`: Selective Forwarding (Grayhole)
1. `ATTACK_MODE=1`: Sinkhole (rank manipulation only)
1. `ATTACK_MODE=2`: Combined (sinkhole + selective)
1. 공격 강도: `ATTACK_DROP_PCT` (ex: 30/50/70)
1. Sinkhole 강도: `SINKHOLE_RANK_DELTA` (ex: 1/2/4)

**7. Trust 계산 (Grayhole trust)**
1. Trust는 노드가 패킷을 정상 포워딩할 확률로 정의.
1. 베타 분포 기반 추정 + EWMA 평활.
1. 성공/실패 카운트: `s_j`, `f_j`
1. Beta mean:
1. `T_hat = (alpha0 + s_j) / (alpha0 + beta0 + s_j + f_j)`
1. EWMA:
1. `T_j(t) = lambda * T_j(t-1) + (1-lambda) * T_hat`

**8. Sinkhole Trust (Control-plane)**
1. DIO에서 광고된 rank와 자기 rank 간의 불일치량으로 이상도 계산.
1. 광고 이상도:
1. `Δ_ij = R_j + MIN_HOPRANKINC - R_i`
1. `s_ij = max(0, -Δ_ij - tau)`
1. 광고 기반 trust:
1. `T_adv = exp(-lambda_adv * s_ij)`
1. Parent 안정성 trust:
1. `ΔR_i = R_i(t) - R_i(t-W)`
1. `u_ij = max(0, ΔR_i - kappa)`
1. `T_stab = exp(-lambda_stab * u_ij)`
1. Sinkhole trust 결합:
1. `T_sink = (T_adv)^w1 * (T_stab)^w2`

**9. Total Trust 결합**
1. `T_total = (T_gray)^alpha * (T_sink)^(1-alpha)`
1. `alpha=1.0`이면 gray-only, `alpha=0.5`이면 sink 포함.

**10. Trust 기반 BRPL Metric**
1. 기본 BRPL weight를 `BP_ij`라고 할 때:
1. `BP_trust = BP_ij * (T_total^gamma) / (1 + lambda * (1 - T_total)^gamma)`
1. 스윕 파라미터:
1. `lambda ∈ {0,1,3,10}`
1. `gamma ∈ {1,2,4}`

**11. trust_engine 파라미터 (기록)**
1. `--metric ewma`
1. `--alpha 0.2`
1. `--ewma-min 0.7`
1. `--stats-interval 200`
1. `--miss-threshold 5`
1. `--forwarders-only`
1. `--fwd-drop-threshold 0.2`
1. Sinkhole trust params:
1. `--sink-min-hop 256`
1. `--sink-tau 0`
1. `--sink-lambda-adv 0.01`
1. `--sink-lambda-stab 0.01`
1. `--sink-beta 0.1`
1. `--sink-kappa 0`
1. `--sink-w1 0.5`
1. `--sink-w2 0.5`
1. `--trust-alpha {1.0, 0.5}`

**12. 측정 지표 (논문용 고정 정의)**
1. PDR: `RX_root / TX_sender`
1. E1 (Exposure–packet):
1. `E1 = (# root-delivered packets that passed attacker) / (# root-delivered packets)`
1. E3 (Exposure–time):
1. `E3 = (time attacker is preferred parent) / (time joined)`
1. Parent switching rate:
1. `switch_rate = parent_changes / parent_samples`

**13. 로그 출력 (필수)**
1. `CSV,TX` / `CSV,RX` (root 기준 RX)
1. `CSV,FWD_PKT` (attacker forwarding 확인)
1. `CSV,ROUTING` (joined, parent, rank)
1. `CSV,DIO_TX` / `CSV,DIO` (sinkhole 광고 추적)
1. `PARENT_CANDIDATE` (trust/metric 결정 근거)

**14. Invalid run 처리**
1. `tx==0` 또는 `rx==0`은 invalid 후보.
1. `lost == tx - rx` 불일치 시 invalid 처리.
1. `E1/E3` 분모가 0이면 invalid 처리.
1. invalid는 삭제하지 말고 별도 파일로 분리.

**15. 실험 스윕 구성**
1. Attack rate: 0/30/50/70
1. Seed: 기본 5개 (quick preview는 1개)
1. Attack mode: 0/1/2
1. Sink delta: 1/2/4
1. Trust alpha: 1.0, 0.5
1. lambda/gamma 스윕은 trust+attack 조합에서만 적용

**16. 토폴로지별 좌표표 (CSV 원본)**

**CLUSTER_L.csv**
파일: `configs/topologies/CLUSTER_L.csv`
```csv
# TWO-CLUSTER + BOTTLENECK Topology - Large (64 nodes total)
# Left cluster: 31 nodes (radius 35m), Right cluster: 31 nodes
# Attacker at bottleneck
node_id,x,y,role
1,100,100,root
2,25,70,sender
3,25,80,sender
4,25,90,sender
5,25,100,sender
6,25,110,sender
7,25,120,sender
8,25,130,sender
9,30,70,sender
10,30,80,sender
11,30,90,sender
12,30,100,sender
13,30,110,sender
14,30,120,sender
15,30,130,sender
16,35,65,sender
17,35,75,sender
18,35,85,sender
19,35,95,sender
20,35,105,sender
21,35,115,sender
22,35,125,sender
23,35,135,sender
24,45,65,sender
25,45,75,sender
26,45,85,sender
27,45,95,sender
28,45,105,sender
29,45,115,sender
30,45,125,sender
31,45,135,sender
32,55,65,sender
33,55,75,sender
34,55,85,sender
35,55,95,sender
36,55,105,sender
37,55,115,sender
38,55,125,sender
39,55,135,sender
40,65,65,sender
41,65,75,sender
42,65,85,sender
43,65,95,sender
44,65,105,sender
45,65,115,sender
46,65,125,sender
47,65,135,sender
48,75,75,sender
49,75,85,sender
50,75,95,sender
51,75,105,sender
52,75,115,sender
53,75,125,sender
54,125,75,sender
55,125,85,sender
56,125,95,sender
57,125,105,sender
58,125,115,sender
59,125,125,sender
60,135,65,sender
61,135,75,sender
62,135,85,sender
63,135,95,sender
64,135,105,sender
65,135,115,sender
66,135,125,sender
67,135,135,sender
68,145,65,sender
69,145,75,sender
70,145,85,sender
71,145,95,sender
72,145,105,sender
73,145,115,sender
74,145,125,sender
75,145,135,sender
76,155,65,sender
77,155,75,sender
78,155,85,sender
79,155,95,sender
80,155,105,sender
81,155,115,sender
82,155,125,sender
83,155,135,sender
84,165,65,sender
85,165,75,sender
86,165,85,sender
87,165,95,sender
88,165,105,sender
89,165,115,sender
90,165,125,sender
91,165,135,sender
92,175,70,sender
93,175,80,sender
94,175,90,sender
95,175,100,sender
96,175,110,sender
97,175,120,sender
98,175,130,sender
99,100,120,attacker
```

**CLUSTER_M.csv**
파일: `configs/topologies/CLUSTER_M.csv`
```csv
# TWO-CLUSTER + BOTTLENECK Topology - Medium (36 nodes total)
# Left cluster: 17 nodes in circle (radius 25m), Right cluster: 17 nodes
# Attacker at bottleneck position (100,120)
node_id,x,y,role
1,100,100,root
2,35,80,sender
3,35,90,sender
4,35,100,sender
5,35,110,sender
6,35,120,sender
7,45,80,sender
8,45,90,sender
9,45,100,sender
10,45,110,sender
11,45,120,sender
12,55,80,sender
13,55,90,sender
14,55,100,sender
15,55,110,sender
16,55,120,sender
17,65,80,sender
18,65,90,sender
19,65,100,sender
20,65,110,sender
21,65,120,sender
22,75,90,sender
23,75,100,sender
24,75,110,sender
25,125,90,sender
26,125,100,sender
27,125,110,sender
28,135,80,sender
29,135,90,sender
30,135,100,sender
31,135,110,sender
32,135,120,sender
33,145,80,sender
34,145,90,sender
35,145,100,sender
36,145,110,sender
37,145,120,sender
38,155,80,sender
39,155,90,sender
40,155,100,sender
41,155,110,sender
42,155,120,sender
43,165,80,sender
44,165,90,sender
45,165,100,sender
46,165,110,sender
47,165,120,sender
48,100,120,attacker
```

**CLUSTER_S.csv**
파일: `configs/topologies/CLUSTER_S.csv`
```csv
# TWO-CLUSTER + BOTTLENECK Topology - Small (16 nodes total)
# Two clusters connected through a bottleneck - attacker at gateway position
# Left cluster center: (55,100), Right cluster center: (145,100)
node_id,x,y,role
1,100,100,root
2,40,85,sender
3,40,115,sender
4,55,80,sender
5,55,120,sender
6,70,85,sender
7,70,115,sender
8,55,100,sender
9,130,85,sender
10,130,115,sender
11,145,80,sender
12,145,120,sender
13,160,85,sender
14,160,115,sender
15,145,100,sender
16,100,120,attacker
```

**CORRIDOR_L.csv**
파일: `configs/topologies/CORRIDOR_L.csv`
```csv
# CORRIDOR/CHAIN Topology - Large (64 nodes total)
# Linear corridor layout, 3m spacing
node_id,x,y,role
1,100,100,root
2,5,100,sender
3,8,100,sender
4,11,100,sender
5,14,100,sender
6,17,100,sender
7,20,100,sender
8,23,100,sender
9,26,100,sender
10,29,100,sender
11,32,100,sender
12,35,100,sender
13,38,100,sender
14,41,100,sender
15,44,100,sender
16,47,100,sender
17,50,100,sender
18,53,100,sender
19,56,100,sender
20,59,100,sender
21,62,100,sender
22,65,100,sender
23,68,100,sender
24,71,100,sender
25,74,100,sender
26,77,100,sender
27,80,100,sender
28,83,100,sender
29,86,100,sender
30,89,100,sender
31,92,100,sender
32,95,100,sender
33,103,100,sender
34,106,100,sender
35,109,100,sender
36,112,100,sender
37,115,100,sender
38,118,100,sender
39,121,100,sender
40,124,100,sender
41,127,100,sender
42,130,100,sender
43,133,100,sender
44,136,100,sender
45,139,100,sender
46,142,100,sender
47,145,100,sender
48,148,100,sender
49,151,100,sender
50,154,100,sender
51,157,100,sender
52,160,100,sender
53,163,100,sender
54,166,100,sender
55,169,100,sender
56,172,100,sender
57,175,100,sender
58,178,100,sender
59,181,100,sender
60,184,100,sender
61,187,100,sender
62,190,100,sender
63,88,100,attacker
```

**CORRIDOR_M.csv**
파일: `configs/topologies/CORRIDOR_M.csv`
```csv
# CORRIDOR/CHAIN Topology - Medium (36 nodes total)
# Linear corridor layout, 5m spacing
node_id,x,y,role
1,100,100,root
2,10,100,sender
3,15,100,sender
4,20,100,sender
5,25,100,sender
6,30,100,sender
7,35,100,sender
8,40,100,sender
9,45,100,sender
10,50,100,sender
11,55,100,sender
12,60,100,sender
13,65,100,sender
14,70,100,sender
15,75,100,sender
16,80,100,sender
17,105,100,sender
18,110,100,sender
19,115,100,sender
20,120,100,sender
21,125,100,sender
22,130,100,sender
23,135,100,sender
24,140,100,sender
25,145,100,sender
26,150,100,sender
27,155,100,sender
28,160,100,sender
29,165,100,sender
30,170,100,sender
31,175,100,sender
32,180,100,sender
33,185,100,sender
34,190,100,sender
35,85,100,attacker
```

**CORRIDOR_S.csv**
파일: `configs/topologies/CORRIDOR_S.csv`
```csv
# CORRIDOR/CHAIN Topology - Small (16 nodes total)
# Linear corridor layout with very low path diversity
# Root at (100,100), nodes along y=100 line
node_id,x,y,role
1,100,100,root
2,20,100,sender
3,32,100,sender
4,44,100,sender
5,56,100,sender
6,68,100,sender
7,80,100,sender
8,108,100,sender
9,120,100,sender
10,132,100,sender
11,144,100,sender
12,156,100,sender
13,168,100,sender
14,180,100,sender
15,92,100,attacker
```

**GRID_L.csv**
파일: `configs/topologies/GRID_L.csv`
```csv
# GRID Topology - Large (64 nodes total)
# 8x8 grid with 25m step
node_id,x,y,role
1,100,100,root
2,12.5,12.5,sender
3,12.5,37.5,sender
4,12.5,62.5,sender
5,12.5,87.5,sender
6,12.5,112.5,sender
7,12.5,137.5,sender
8,12.5,162.5,sender
9,12.5,187.5,sender
10,37.5,12.5,sender
11,37.5,37.5,sender
12,37.5,62.5,sender
13,37.5,87.5,sender
14,37.5,112.5,sender
15,37.5,137.5,sender
16,37.5,162.5,sender
17,37.5,187.5,sender
18,62.5,12.5,sender
19,62.5,37.5,sender
20,62.5,62.5,sender
21,62.5,87.5,sender
22,62.5,112.5,sender
23,62.5,137.5,sender
24,62.5,162.5,sender
25,62.5,187.5,sender
26,87.5,12.5,sender
27,87.5,37.5,sender
28,87.5,62.5,sender
29,87.5,87.5,sender
30,87.5,112.5,sender
31,87.5,137.5,sender
32,87.5,162.5,sender
33,87.5,187.5,sender
34,112.5,12.5,sender
35,112.5,37.5,sender
36,112.5,62.5,sender
37,112.5,87.5,sender
38,112.5,112.5,sender
39,112.5,137.5,sender
40,112.5,162.5,sender
41,112.5,187.5,sender
42,137.5,12.5,sender
43,137.5,37.5,sender
44,137.5,62.5,sender
45,137.5,87.5,sender
46,137.5,112.5,sender
47,137.5,137.5,sender
48,137.5,162.5,sender
49,137.5,187.5,sender
50,162.5,12.5,sender
51,162.5,37.5,sender
52,162.5,62.5,sender
53,162.5,87.5,sender
54,162.5,112.5,sender
55,162.5,137.5,sender
56,162.5,162.5,sender
57,162.5,187.5,sender
58,187.5,12.5,sender
59,187.5,37.5,sender
60,187.5,62.5,sender
61,187.5,87.5,sender
62,187.5,112.5,sender
63,187.5,137.5,sender
64,187.5,162.5,sender
65,187.5,187.5,sender
66,112.5,100,attacker
```

**GRID_M.csv**
파일: `configs/topologies/GRID_M.csv`
```csv
# GRID Topology - Medium (36 nodes total)
# 6x6 grid with 30m step
node_id,x,y,role
1,100,100,root
2,25,25,sender
3,25,55,sender
4,25,85,sender
5,25,115,sender
6,25,145,sender
7,25,175,sender
8,55,25,sender
9,55,55,sender
10,55,85,sender
11,55,115,sender
12,55,145,sender
13,55,175,sender
14,85,25,sender
15,85,55,sender
16,85,85,sender
17,85,115,sender
18,85,145,sender
19,85,175,sender
20,115,25,sender
21,115,55,sender
22,115,85,sender
23,115,115,sender
24,115,145,sender
25,115,175,sender
26,145,25,sender
27,145,55,sender
28,145,85,sender
29,145,115,sender
30,145,145,sender
31,145,175,sender
32,175,25,sender
33,175,55,sender
34,175,85,sender
35,175,115,sender
36,175,145,sender
37,175,175,sender
38,115,100,attacker
```

**GRID_S.csv**
파일: `configs/topologies/GRID_S.csv`
```csv
# GRID Topology - Small (16 nodes total)
# High path diversity, sinkhole has limited but measurable impact
# Root at center (100,100), 4x4 grid with 40m step
node_id,x,y,role
1,100,100,root
2,40,40,sender
3,40,80,sender
4,40,120,sender
5,40,160,sender
6,80,40,sender
7,80,80,sender
8,80,120,sender
9,80,160,sender
10,120,40,sender
11,120,80,sender
12,120,120,sender
13,120,160,sender
14,160,40,sender
15,160,80,sender
16,160,120,sender
17,120,100,attacker
```

**RING_L.csv**
파일: `configs/topologies/RING_L.csv`
```csv
# RING + SPOKES Topology - Large (64 nodes total)
# Ring radius 80m
node_id,x,y,role
1,100,100,root
2,180,100,sender
3,178,111,sender
4,174,122,sender
5,168,132,sender
6,160,142,sender
7,150,151,sender
8,139,158,sender
9,127,164,sender
10,114,168,sender
11,100,170,sender
12,86,168,sender
13,73,164,sender
14,61,158,sender
15,50,151,sender
16,40,142,sender
17,32,132,sender
18,26,122,sender
19,22,111,sender
20,20,100,sender
21,22,89,sender
22,26,78,sender
23,32,68,sender
24,40,58,sender
25,50,49,sender
26,61,42,sender
27,73,36,sender
28,86,32,sender
29,100,30,sender
30,114,32,sender
31,127,36,sender
32,139,42,sender
33,150,49,sender
34,160,58,sender
35,168,68,sender
36,174,78,sender
37,178,89,sender
38,160,100,sender
39,158,110,sender
40,154,120,sender
41,148,129,sender
42,140,137,sender
43,130,144,sender
44,119,148,sender
45,108,150,sender
46,97,150,sender
47,86,148,sender
48,75,144,sender
49,65,137,sender
50,57,129,sender
51,51,120,sender
52,47,110,sender
53,45,100,sender
54,47,90,sender
55,51,80,sender
56,57,71,sender
57,65,63,sender
58,75,56,sender
59,86,52,sender
60,97,50,sender
61,108,50,sender
62,119,52,sender
63,130,56,sender
64,140,63,sender
65,148,71,sender
66,154,80,sender
67,158,90,sender
68,100,120,attacker
```

**RING_M.csv**
파일: `configs/topologies/RING_M.csv`
```csv
# RING + SPOKES Topology - Medium (36 nodes total)
# Ring radius 70m
node_id,x,y,role
1,100,100,root
2,170,100,sender
3,167,119,sender
4,160,137,sender
5,149,153,sender
6,135,166,sender
7,118,175,sender
8,100,177,sender
9,82,175,sender
10,65,166,sender
11,51,153,sender
12,40,137,sender
13,33,119,sender
14,30,100,sender
15,33,81,sender
16,40,63,sender
17,51,47,sender
18,65,34,sender
19,82,25,sender
20,100,23,sender
21,118,25,sender
22,135,34,sender
23,149,47,sender
24,160,63,sender
25,167,81,sender
26,145,100,sender
27,144,114,sender
28,137,127,sender
29,127,137,sender
30,114,144,sender
31,100,146,sender
32,86,144,sender
33,73,137,sender
34,63,127,sender
35,56,114,sender
36,55,100,sender
37,100,120,attacker
```

**RING_S.csv**
파일: `configs/topologies/RING_S.csv`
```csv
# RING + SPOKES Topology - Small (16 nodes total)
# Ring radius 60m, nodes evenly distributed
# Root at center (100,100), attacker at (100,120)
node_id,x,y,role
1,100,100,root
2,160,100,sender
3,155,133,sender
4,141,152,sender
5,118,163,sender
6,90,163,sender
7,67,152,sender
8,53,133,sender
9,45,109,sender
10,45,91,sender
11,53,67,sender
12,67,48,sender
13,90,37,sender
14,118,37,sender
15,141,48,sender
16,155,67,sender
17,100,120,attacker
```
