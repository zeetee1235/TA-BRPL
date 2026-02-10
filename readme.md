## Trust-Aware BRPL (Contiki-NG/Cooja)

RPL/BRPL 기반 LLN에서 **신뢰(Trust) 기반 패널티를 backpressure 메트릭에 통합**해 routing 공격(Selective Forwarding/Grayhole, Sinkhole)에 대한 복원력을 평가하는 실험용 저장소입니다.

### 핵심 아이디어
- **행동 신뢰(Grayhole trust)**와 **제어면 신뢰(Sinkhole trust)**를 계산
- 이를 BRPL 메트릭에 패널티로 반영하여 **부모 선택/포워딩**을 제어

### Trust 계산 수식
- Grayhole trust (베타 추정 + EWMA)

```text
T_hat = (alpha0 + s_j) / (alpha0 + beta0 + s_j + f_j)
T_j(t) = lambda * T_j(t-1) + (1 - lambda) * T_hat
```

- Sinkhole trust (rank 불일치 + 안정성)

\[
\Delta_{ij} = R_j + \mathrm{MIN\_HOPRANKINC} - R_i,\quad
s_{ij} = \max(0, -\Delta_{ij} - \tau)
\]
\[
T_{adv} = e^{-\lambda_{adv} s_{ij}},\quad
u_{ij} = \max(0, \Delta R_i - \kappa),\quad
T_{stab} = e^{-\lambda_{stab} \nu_{ij}}
\]
\[
T_{sink} = (T_{adv})^{w_1} (T_{stab})^{w_2}
\]

- Total trust 결합

```text
T_total = (T_gray)^alpha * (T_sink)^(1 - alpha)
```

- Trust-aware BRPL 메트릭

```text
BP_trust = BP_ij * (T_total^gamma) / (1 + lambda * (1 - T_total)^gamma)
```

### 공격 모드
- `ATTACK_MODE=0`: Selective Forwarding (Grayhole)
- `ATTACK_MODE=1`: Sinkhole (rank manipulation)
- `ATTACK_MODE=2`: Combined (sinkhole + selective)

### 실행 방법
- 전체 스윕: `./scripts/run_experiments.sh`
- 빠른 미리보기: `QUICK_PREVIEW=1 ./scripts/run_experiments.sh`
- 단일 검증: `TOPOLOGY=configs/topologies/GRID_L.csc ./scripts/single_test.sh`
- 특정 토폴로지만: `TOPOLOGIES="configs/topologies/CLUSTER_S.csc configs/topologies/GRID_L.csc" ./scripts/run_experiments.sh`

### 결과 파일
각 run 디렉토리에는 아래 파일이 생성됩니다.
- `COOJA.testlog`
- `exposure.csv` / `parent_switch.csv` / `stats.csv` / `trust_final.log`

### 토폴로지/파라미터 참고
- 토폴로지: `configs/topologies/*.csc`
- 상세 실험 메모: `docs/paper_base/memo.md`
- 토폴로지 규칙/좌표: `docs/paper_base/topology.md`

