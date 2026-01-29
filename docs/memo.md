노드별 마지막 seq 추적 → 누락(missed) 계산
샘플 신뢰도: sample = 1000 / (1 + missed) (0~1000 스케일)
EWMA: trust = alpha*sample + (1-alpha)*prev
로그: CSV,TRUST,<node_id>,<seq>,<missed>,<trust>


일단은.. 먼저 brpl이 selective forwarding 공격에 더 취약하다는것을 증명
이후 해결방안까지 제공 신뢰기반



BRPL은 트래픽 상황에 따라 동적으로 경로를 조정하지만,
이러한 특성은 Selective Forwarding 공격 시
악성 노드를 오히려 우수한 경로로 인식하게 만들어
공격 효과를 증폭시킬 수 있다.

---

최근 진행 상황 요약
- 랜덤 토폴로지 생성기: `scripts/gen_random_topology.py`
  - 노드 51, 영역 200x200, attacker ID=3 (20,0) 고정
- BRPL/MRHOF 단일 런 비교 완료
- 10회 평균 비교 배치 실행 중
  - 결과: `results/batch-20260129-013513`
  - 로그: `logs/batch_run.log`
- 외부 Trust Engine 연동 초안
  - Rust 파서: `tools/trust_engine`
  - Cooja ScriptRunner가 `logs/trust_updates.txt`를 폴링
  - SerialSocketServer로 root 로그를 Rust가 직접 수신 가능(60001)
  - 이상 탐지/블랙리스트는 trust=0 주입으로 처리


1) “반드시 뽑아야 하는” 최소 시나리오 6개 (추천)

이 6개만 있어도 보고서/발표가 완성된다.

A. 정상 성능 비교(라우팅 자체 성능)

MRHOF, Attack OFF, Trust OFF → RPL baseline

BRPL, Attack OFF, Trust OFF → BRPL baseline

목적: “정상 상황에서 BRPL이 왜 쓰이는지” 보여주기

B. 공격 영향 비교(취약성 비교)

MRHOF, Attack ON, Trust OFF

BRPL, Attack ON, Trust OFF

목적: “Selective Forwarding에서 BRPL이 더 치명적일 수 있음”을 데이터로 증명

C. 방어 효과

MRHOF, Attack ON, Trust ON

BRPL, Attack ON, Trust ON

목적: “Trust가 성능 회복/완화에 효과적”을 보여주기
(특히 4 vs 6이 핵심 그림)

2) 옵션으로 추가하면 좋은 시나리오 2개 (시간 남으면)

MRHOF, Attack OFF, Trust ON

BRPL, Attack OFF, Trust ON

목적: 오탐/부작용 체크
“정상 상황에서 Trust가 성능을 얼마나 깎는지(Overhead/Delay 증가)”를 보여줌


3) 공격 드롭률(p_drop)은 어떻게 묶을까?

: 0.0, 0.3, 0.5, 0.7 (그래프가 예쁘게 나옴)

위 6개 시나리오 × p_drop 3~4개 × seed 5개 정도가 적당해.

4) 각 시나리오에서 뽑아야 하는 데이터(로그) 5종

너의 연구 질문(PDR/Delay/Overhead)에 딱 맞게:

PDR

sink 수신 / source 송신

E2E Delay

(source timestamp → sink receive timestamp)

Overhead

컨트롤 패킷 수(가능하면) + Trust 메시지 바이트

Recovery time

Attack ON 시점 이후 PDR이 일정 수준(예: baseline의 90%)로 회복되는 시간

Trust dynamics(증거용)

공격 노드의 trust 값이 시간에 따라 내려가는 그래프(한 장이면 설득력 끝)

5) “그래프 구성”까지 염두에 둔 추천 패키지

보고서에서 보통 이렇게 구성하면 완벽해:

Figure 1: 정상 (1 vs 2) PDR/Delay

Figure 2: 공격 (3 vs 4) PDR 급락 비교

Figure 3: 방어 (4 vs 6) BRPL에서 Trust로 회복

Figure 4: Trust 값 시간 변화 (공격노드 vs 정상노드)

Table 1: Overhead(Trust ON으로 증가한 바이트/패킷)