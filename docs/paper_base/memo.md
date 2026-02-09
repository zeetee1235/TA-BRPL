**연구 메모: 실험 진행 방식 / Trust 계산 / 토폴로지 / 측정 지표**

  

**1. 실험 진행 방식 (Workflow)**

1. 토폴로지 `.csc`를 준비한다. 기본 위치: `configs/topologies/*.csc`.

2. 단일 검증: `scripts/single_test.sh`를 사용한다.

3. 전체 스윕: `scripts/run_experiments.sh`를 사용한다.

4. 결과는 `results/experiments-YYYYMMDD-HHMMSS/` 아래에 저장된다.

5. 각 run 디렉토리에는 `COOJA.testlog` 및 trust_engine 출력(`exposure.csv`, `parent_switch.csv`, `stats.csv`, `trust_final.log`)이 있다.

  

**2. 실험 실행 커맨드**

1. 전체 실행: `./scripts/run_experiments.sh`

2. 빠른 미리보기: `QUICK_PREVIEW=1 ./scripts/run_experiments.sh`

3. 특정 토폴로지만: `TOPOLOGIES="configs/topologies/CLUSTER_S.csc configs/topologies/GRID_L.csc" ./scripts/run_experiments.sh`

4. 단일 실행: `TOPOLOGY=configs/topologies/GRID_L.csc ./scripts/single_test.sh`

  

**3. 공통 실험 파라미터**

1. Field: 200m × 200m

2. Radio: UDGM Distance Loss

3. TX Range: 45m

4. Interference Range: 90m

5. Root ID: 1

6. Attacker ID: 2

7. 기본 SIM 시간: 600s

8. Warmup: 120s

9. 송신 간격: 30s

10. Quick preview 모드: `SIM_TIME=240s`, `WARMUP=10s`, `SEND_INTERVAL=10s`, seed=1

  

**4. 토폴로지 구성**

1. 사용 토폴로지: `configs/topologies/*.csc`

2. 이름 패턴:

3. `CLUSTER_{S,M,L}.csc`

4. `CORRIDOR_{S,M,L}.csc`

5. `GRID_{S,M,L}.csc`

6. `RING_{S,M,L}.csc`

7. 토폴로지 변경 시 `.csc` 내부 `<commands>`의 build 경로는 `make -C ../motes`로 유지해야 한다.

8. `<source>` 경로는 `[CONFIG_DIR]/../motes/...` 형태여야 한다.

9. `PROJECT_CONF_PATH=../project-conf.h` 사용.

  

**5. RPL 컨버전스 파라미터 (project-conf.h)**

1. `RPL_CONF_DIO_INTERVAL_MIN=8`

2. `RPL_CONF_DIO_INTERVAL_DOUBLINGS=10`

3. `RPL_CONF_DIO_REDUNDANCY=10`

  

**6. 공격 모델 (Attack Modes)**

1. `ATTACK_MODE=0`: Selective Forwarding (Grayhole)

2. `ATTACK_MODE=1`: Sinkhole (rank manipulation only)

3. `ATTACK_MODE=2`: Combined (sinkhole + selective)

4. 공격 강도: `ATTACK_DROP_PCT` (ex: 30/50/70)

5. Sinkhole 강도: `SINKHOLE_RANK_DELTA` (ex: 1/2/4)

  

**7. Trust 계산 (Grayhole trust)**

1. Trust는 노드가 패킷을 정상 포워딩할 확률로 정의.

2. 베타 분포 기반 추정 + EWMA 평활.

3. 성공/실패 카운트: `s_j`, `f_j`

4. Beta mean:

5. `T_hat = (alpha0 + s_j) / (alpha0 + beta0 + s_j + f_j)`

6. EWMA:

7. `T_j(t) = lambda * T_j(t-1) + (1-lambda) * T_hat`

  

**8. Sinkhole Trust (Control-plane)**

1. DIO에서 광고된 rank와 자기 rank 간의 불일치량으로 이상도 계산.

2. 광고 이상도:

3. `Δ_ij = R_j + MIN_HOPRANKINC - R_i`

4. `s_ij = max(0, -Δ_ij - tau)`

5. 광고 기반 trust:

6. `T_adv = exp(-lambda_adv * s_ij)`

7. Parent 안정성 trust:

8. `ΔR_i = R_i(t) - R_i(t-W)`

9. `u_ij = max(0, ΔR_i - kappa)`

10. `T_stab = exp(-lambda_stab * u_ij)`

11. Sinkhole trust 결합:

12. `T_sink = (T_adv)^w1 * (T_stab)^w2`

  

**9. Total Trust 결합**

1. `T_total = (T_gray)^alpha * (T_sink)^(1-alpha)`

2. `alpha=1.0`이면 gray-only, `alpha=0.5`이면 sink 포함.

  

**10. Trust 기반 BRPL Metric**

1. 기본 BRPL weight를 `BP_ij`라고 할 때:

2. `BP_trust = BP_ij * (T_total^gamma) / (1 + lambda * (1 - T_total)^gamma)`

3. 스윕 파라미터:

4. `lambda ∈ {0,1,3,10}`

5. `gamma ∈ {1,2,4}`

  

**11. trust_engine 파라미터 (기록)**

1. `--metric ewma`

2. `--alpha 0.2`

3. `--ewma-min 0.7`

4. `--stats-interval 200`

5. `--miss-threshold 5`

6. `--forwarders-only`

7. `--fwd-drop-threshold 0.2`

8. Sinkhole trust params:

9. `--sink-min-hop 256`

10. `--sink-tau 0`

11. `--sink-lambda-adv 0.01`

12. `--sink-lambda-stab 0.01`

13. `--sink-beta 0.1`

14. `--sink-kappa 0`

15. `--sink-w1 0.5`

16. `--sink-w2 0.5`

17. `--trust-alpha {1.0, 0.5}`

  

**12. 측정 지표 (논문용 고정 정의)**

1. PDR: `RX_root / TX_sender`

2. E1 (Exposure–packet):

3. `E1 = (# root-delivered packets that passed attacker) / (# root-delivered packets)`

4. E3 (Exposure–time):

5. `E3 = (time attacker is preferred parent) / (time joined)`

6. Parent switching rate:

7. `switch_rate = parent_changes / parent_samples`

  

**13. 로그 출력 (필수)**

1. `CSV,TX` / `CSV,RX` (root 기준 RX)

2. `CSV,FWD_PKT` (attacker forwarding 확인)

3. `CSV,ROUTING` (joined, parent, rank)

4. `CSV,DIO_TX` / `CSV,DIO` (sinkhole 광고 추적)

5. `PARENT_CANDIDATE` (trust/metric 결정 근거)

  

**14. Invalid run 처리**

1. `tx==0` 또는 `rx==0`은 invalid 후보.

2. `lost == tx - rx` 불일치 시 invalid 처리.

3. `E1/E3` 분모가 0이면 invalid 처리.

4. invalid는 삭제하지 말고 별도 파일로 분리.

  

**15. 실험 스윕 구성**

1. Attack rate: 0/30/50/70

2. Seed: 기본 5개 (quick preview는 1개)

3. Attack mode: 0/1/2

4. Sink delta: 1/2/4

5. Trust alpha: 1.0, 0.5

6. lambda/gamma 스윕은 trust+attack 조합에서만 적용

  