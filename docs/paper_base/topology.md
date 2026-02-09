

아래는 **Cooja 2D 좌표(미터)** 기준이고, 각 토폴로지는 **(1) Root 좌표, (2) 정상 노드 좌표 생성 규칙(=좌표 명시), (3) Sinkhole/Grayhole 공격자 좌표**까지 포함한다.  
(논문에는 “좌표를 이렇게 정의했다”로 적고, 부록/레포에 `.csc`/CSV로 공개하면 깔끔함)

---

## 공통 실험 설정(권장)

- **필드 크기**: 200m × 200m (좌표 범위 x,y ∈ [0,200])
    
- **Root(싱크)**: (100, 100) 고정
    
- **노드 수(총합, Root 포함)**
    
    - **S**: 16개 (Root 1 + normal 14 + attacker 1)
        
    - **M**: 36개 (Root 1 + normal 34 + attacker 1)
        
    - **L**: 64개 (Root 1 + normal 62 + attacker 1)
        
- **UDGM(예시)**: TX range 50m, Interference range 60m (너가 쓰는 값이 있으면 그대로)
    
- **공격자**: 기본 1개(필요하면 “2 attackers” 실험은 별도 섹션으로)
    

> 포인트: “공격이 보이게”는 **공격자가 경로에 자연스럽게 끼도록(Exposure↑)** 만드는 거고, 그게 연구윤리 위반이 아니려면 **(i) 규칙 기반 생성**, **(ii) 토폴로지별 목적(병목/다중경로)을 명시**, **(iii) 동일 규칙으로 S/M/L 확장**이면 충분히 정당화 가능.

---

# Topology 1) GRID (고경로다양성, sinkhole이 ‘완전 장악’은 어렵지만 “유의미한 영향”은 나옴)

**의도**: 경로 대안이 많은 환경. sinkhole은 “영향이 제한적”이라 오히려 논문에서 비교가 좋아짐(=토폴로지 민감도).

### 좌표 정의

- Root: **(100,100)**
    

### S (총 16)

- **normal 노드 14개**: 격자 4×4에서 Root 위치는 빼고, 하나 더 빼서 14개로 맞춤
    
    - 격자 step = 40m
        
    - 격자 점: x ∈ {40, 80, 120, 160}, y ∈ {40, 80, 120, 160}
        
    - Root(100,100)은 격자에 없으니 격자점 그대로 쓰되, 16개가 되므로 **(160,160)** 하나 제거해서 15개 → 여기서 attacker 1개 넣으면 총 16
        
- **sinkhole attacker (1개)**: **(120, 100)** (Root에서 20m, “Root 근처에 있어 좋은 링크를 가진 노드”로 자연스러움)
    
- **grayhole attacker를 할 때도 동일 좌표 사용**(공격 타입만 변경)
    

### M (총 36)

- 격자 6×6, step = 30m
    
    - x ∈ {25, 55, 85, 115, 145, 175}
        
    - y ∈ {25, 55, 85, 115, 145, 175}
        
- Root (100,100) 고정 (격자점과 겹치지 않음)
    
- attacker: **(115, 100)**
    

### L (총 64)

- 격자 8×8, step = 25m
    
    - x ∈ {12.5, 37.5, 62.5, 87.5, 112.5, 137.5, 162.5, 187.5}
        
    - y 동일
        
- attacker: **(112.5, 100)** (혹은 (112.5, 87.5)로 격자에 맞춰도 OK)
    

**논문에서 기대되는 관측**

- Sinkhole: PDR 하락이 “중간” 정도(대안 경로가 있어 완전 붕괴는 잘 안 남)
    
- Grayhole: drop-rate가 올라갈수록 PDR/지연이 완만히 악화(“완만한 곡선”이 나오는 쪽)
    

---

# Topology 2) TWO-CLUSTER + BOTTLENECK (병목 1개, sinkhole/grayhole이 가장 ‘잘 보임’)

**의도**: 현실에서도 흔한 “두 구역이 좁은 연결로 이어짐(복도/게이트웨이)” 구조.  
여기서 공격자가 병목에 있으면 **Exposure가 규칙적으로 커져서** 공격이 매우 명확히 보임.

### 좌표 정의(클러스터 + 브리지)

- Root: (100,100)
    
- 좌측 클러스터 중심: (55, 100)
    
- 우측 클러스터 중심: (145, 100)
    
- 브리지(게이트) 정상 노드: (100, 100) 근처에 두면 Root와 겹치니 **(100, 120)** 혹은 **(100, 80)** 사용
    

## S (총 16)

- 좌클러스터 normal 7개 (중심 55,100 주변)
    
    - (40, 85), (40, 115), (55, 80), (55, 120), (70, 85), (70, 115), (55, 100)
        
- 우클러스터 normal 7개 (중심 145,100 주변)
    
    - (130, 85), (130, 115), (145, 80), (145, 120), (160, 85), (160, 115), (145, 100)
        
- 브리지 normal 1개:
    
    - **(100, 120)**
        
- attacker 1개(병목 장악형):
    
    - **sinkhole attacker: (100, 95)** ← Root와 너무 겹치지 않으면서 “병목을 먹는” 위치
        
    - **grayhole도 동일 위치** 추천
        

> 총합: Root 1 + 좌7 + 우7 + 브리지1 + attacker1 = 17이므로, S=16 맞추려면 브리지 normal을 빼고 attacker가 브리지 역할까지 하게 만들면 됨.  
> 즉 S에서는 **브리지 normal 제거**, attacker를 **(100,120)**에 둬도 좋음.  
> 논문용으로는 이 편이 더 깔끔함: “공격자가 게이트웨이에 위치” (현실 시나리오로도 자연스러움)

### S 최종 추천(개수 딱 맞춤)

- 브리지 normal 삭제
    
- attacker: **(100,120)**
    

## M (총 36)

- 좌클러스터 17개: 중심 (55,100), 반경 25m 내 격자 점들
    
    - x ∈ {35, 45, 55, 65, 75}, y ∈ {80, 90, 100, 110, 120} 중 “원형에 가까운 17개” 선택
        
    - 선택 규칙(좌표 명시 규칙): **(x-55)²+(y-100)² ≤ 25²** 인 점 전부
        
- 우클러스터도 동일(중심 145,100)
    
- attacker: **(100,120)**
    

## L (총 64)

- 좌클러스터 31개: 중심 (55,100), 반경 35m
    
    - (x-55)²+(y-100)² ≤ 35² 를 만족하는 5m/10m 격자 점에서 31개 선택(규칙 고정)
        
- 우클러스터 31개 동일
    
- attacker: **(100,120)**
    

**논문에서 기대되는 관측**

- Sinkhole: 병목 장악 → 서브트리 트래픽이 attacker로 몰림 → PDR 급락/지연 급등 (특히 공격률↑일수록)
    
- Grayhole: 공격률이 곧바로 PDR에 반영(Exposure가 매우 커서 “선형/준선형” 관계가 예쁘게 나옴)
    

---

# Topology 3) CORRIDOR / CHAIN (초저 경로다양성, 공격이 “임계적으로” 보임)

**의도**: 복도형 배치(스마트빌딩/터널/파이프라인). 다중경로가 거의 없어서 공격이 명확하게 드러남.

### 좌표 정의

- Root: (100,100)
    
- 중심선 y=100 근처로 길게 늘어뜨림(좌표를 규칙으로 명시)
    

## S (총 16)

- normal 14개:
    
    - x ∈ {20, 32, 44, 56, 68, 80, 92, 108, 120, 132, 144, 156, 168, 180}, y=100
        
- attacker:
    
    - **sinkhole/grayhole attacker: (92, 100)**  
        (Root까지 한두 홉 거리에서 “중간 관문”을 먹게 함)
        

## M (총 36)

- normal 34개:
    
    - x = 10 + 5k, k=0..33 (즉 {10,15,20,...,175}), y=100
        
- attacker:
    
    - (85, 100)
        

## L (총 64)

- normal 62개:
    
    - x = 5 + 3k, k=0..61 (즉 {5,8,11,...,188}), y=100
        
- attacker:
    
    - (88, 100)
        

**논문에서 기대되는 관측**

- Sinkhole: “거의 지배” 가능(특히 RPL parent 선택이 RSSI/ETX 쏠림이면)
    
- Grayhole: attack rate 변화가 PDR에 직관적으로 반영(대체 경로가 없으니까)
    

---

# Topology 4) RING + SPOKES (중간 PD, sinkhole이 ‘루트 근처에서’ 영향)

**의도**: 산업 현장/스마트시티에서 흔한 “중앙 게이트 + 외곽 링” 구조.  
Grid보다 PD가 낮고, Corridor보단 높아서 **중간 케이스**로 예쁨.

### 좌표 정의(S/M/L 모두 규칙 동일)

- Root (100,100)
    
- Ring 반지름 R = 60m (S), 70m (M), 80m (L)
    
- Ring 점들: 각도 θ를 균등 분할
    

예: S에서 normal 14개를 링에 두려면

- θ = 0°, 25.7°, 51.4° … (360/14 간격)
    
- 좌표: (100 + R cosθ, 100 + R sinθ)
    

attacker:

- sinkhole attacker: **(100, 120)** (Root보다 약간 위, 여러 스포크 경로에 끼기 쉬움)
    

---

## “윤리적으로 깔끔하게” 보이게 만드는 논문 서술 팁 (중요)

너가 걱정하는 지점이 바로 “토폴로지 슬쩍 조정해서 효과만 보이게”인데, 아래 3줄이면 방어가 됨.

1. **토폴로지 목적을 명시**
    

- Grid: high path diversity
    
- Two-cluster: bottleneck (gateway)
    
- Corridor: low path diversity
    
- (Ring: mid)
    

2. **좌표는 규칙 기반으로 생성했고 S/M/L은 같은 규칙으로 확장했다**  
    → 지금 내가 준 방식이 딱 이거.
    
3. **공격자 위치도 규칙 기반(“gateway/central relay 후보”)으로 고정**
    

- “특정 결과를 위해 미세조정”이 아니라
    
- “현실적 위협 모델(게이트웨이 장악/중간 릴레이 장악)”이라고 설명 가능.
    

---

**토폴로지별 좌표표 (CSV 원본)**

  

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

---
