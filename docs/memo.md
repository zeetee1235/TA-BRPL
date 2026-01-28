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
