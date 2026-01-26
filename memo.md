노드별 마지막 seq 추적 → 누락(missed) 계산
샘플 신뢰도: sample = 1000 / (1 + missed) (0~1000 스케일)
EWMA: trust = alpha*sample + (1-alpha)*prev
로그: CSV,TRUST,<node_id>,<seq>,<missed>,<trust>