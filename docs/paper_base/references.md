논문 레퍼런스 달것들

---

# 1. 실험 진행 방식 / 시뮬레이션 환경

### Contiki-NG + Cooja 기반 실험 설계

- **출처**
    
    - Dunkels et al., _Contiki-NG: A Next Generation Open Source OS for the IoT_, 2017
        
    - Österlind et al., _Cross-Level Sensor Network Simulation with COOJA_, SenSys 2006
        

**왜 이 방식이 정당한가**

- Cooja는 **RPL 표준 구현을 그대로 사용하면서 공격 코드 삽입이 가능한 거의 유일한 시뮬레이터**
    
- `.csc + seed sweep + batch script` 구조는 **재현성(reproducibility)** 확보를 위한 표준적 접근
    


> _All experiments were conducted using Contiki-NG and the COOJA simulator, which has been widely adopted for RPL-based IoT routing evaluations._

---

# 2–5. 공통 파라미터 / RPL 컨버전스 설정

### RPL DIO 파라미터

```c
RPL_CONF_DIO_INTERVAL_MIN
RPL_CONF_DIO_INTERVAL_DOUBLINGS
RPL_CONF_DIO_REDUNDANCY
```

- **출처**
    
    - RFC 6550 – _RPL: IPv6 Routing Protocol for Low-Power and Lossy Networks_
        
    - Gnawali et al., _The Collection Tree Protocol_, SenSys 2009 (Trickle 기반 수렴)
        

**왜 이 값들이 의미 있는가**

- DIO interval min = 2⁸ ms는 **표준 RPL 실험에서 가장 흔한 설정**
    
- redundancy는 **control-plane 안정성 vs overhead trade-off**
    

“튜닝”이 아니라 **표준 설정 유지**라 연구윤리 문제 없음

---

# 6. 공격 모델 정의

## 6.1 Selective Forwarding (Grayhole)

- **출처**
    
    - Karlof & Wagner, _Secure Routing in Wireless Sensor Networks_, AdHoc Networks 2003
        
    - Wood & Stankovic, _Denial of Service in Sensor Networks_, IEEE Computer 2002
        

**정의 정당성**

- Grayhole = _probabilistic packet dropping_
    
- drop rate sweep (30/50/70%)은 **공격 강도 스케일링의 정석**
    

---

## 6.2 Sinkhole (Rank manipulation)

- **출처**
    
    - RFC 6550 (rank semantics)
        
    - Le et al., _The Impact of Rank Attack on RPL-based Networks_, IEEE ICC 2013
        
    - Perrey et al., _Attacks and Countermeasures in RPL-based IoT Networks_, AdHoc Networks 2020
        

**왜 rank delta로 모델링했는가**

- Sinkhole의 핵심은 **실제 link quality가 아니라 control-plane 허위 정보**
    
- rank 감소는 RPL에서 **부모 선택을 직접 조작하는 유일한 공격 벡터**
    

---

# 7. Grayhole Trust 수식

## 7.1 Trust를 “forwarding 성공 확률”로 정의

- **출처**
    
    - Ganeriwal & Srivastava, _Reputation-based Framework for Sensor Networks_, SecureComm 2004
        
    - Buchegger & Le Boudec, _A Robust Reputation System for P2P_, EPFL TR 2004
        

> Trust = probability of correct behavior

---

## 7.2 Beta distribution 기반 추정

$$ 
\hat{T} = \frac{\alpha_0 + s_j}{\alpha_0 + \beta_0 + s_j + f_j}  
$$

- **출처**
    
    - Ganeriwal et al., _Reputation-based Framework for High Integrity Sensor Networks_, ACM TOSN 2008
        
    - Sun et al., _Trust Modeling and Evaluation in Ad Hoc Networks_, GLOBECOM 2005
        

**왜 Beta인가**

- 이항 성공/실패 관측에 대해 **conjugate prior**
    
- low-observation 환경(WSN)에 매우 적합
    

---

## 7.3 EWMA 평활

$$
T_j(t) = \lambda T_j(t-1) + (1-\lambda)\hat{T}  
$$

- **출처**
    
    - Ganeriwal et al., TOSN 2008
        
    - Liu et al., _A Trust-Aware Routing Framework in WSNs_, IEEE TIFS 2012
        

**왜 EWMA를 붙였는가**

- 단기 noise 제거
    
- bursty drop 공격에 대한 안정성
    

---

# 8. Sinkhole Trust (Control-plane)

## 8.1 Rank inconsistency 기반 이상도

$$
\Delta_{ij} = R_j + \mathrm{MIN\_HOPRANKINC} - R_i
$$


- **출처**
    
    - RFC 6550 (rank monotonicity rule)
        
    - Le et al., IEEE ICC 2013
        

> 정상 RPL에서는 Δ ≥ 0 이 보장됨

---

## 8.2 Sinkhole deviation score

$$  
s_{ij} = \max(0, -\Delta_{ij} - \tau)  
$$

- **출처**
    
    - Wallner et al., _Misbehavior Detection in RPL_, IEEE WCNC 2016
        
    - Mayzaud et al., _A Taxonomy of Attacks in RPL-based Networks_, IEEE Comm Surveys 2016
        

**의미**

- τ는 measurement noise tolerance
    
- 음수 overshoot만 penalize
    

---

## 8.3 Exponential trust decay

$$
T_{adv} = e^{-\lambda_{adv} s_{ij}}  
$$

- **출처**
    
    - Sun et al., GLOBECOM 2005
        
    - Chen et al., _Trust-based Routing in WSNs_, IEEE MASS 2010
        

> exponential decay = small deviation은 관대, 큰 deviation은 급격히 패널티

---

## 8.4 Parent stability trust

$$
\Delta R_i = R_i(t) - R_i(t-W)  
$$

$$
u_{ij} = \max(0, \Delta R_i - \kappa)  
$$

- **출처**
    
    - Wallner et al., WCNC 2016
        
    - Raza et al., _Securing RPL_, IEEE Sensors 2013
        

**의미**

- Sinkhole은 **자기 rank 불안정 + 자주 변함**
    
- data-plane 없이도 감지 가능
    

---

## 8.5 Sinkhole trust 결합

$$
T_{sink} = (T_{adv})^{w_1} (T_{stab})^{w_2}  
$$

- **출처**
    
    - Liu et al., IEEE TIFS 2012
        
    - Momani & Challa, _Survey of Trust Models_, IEEE Comm Surveys 2010
        

---

# 9. Total Trust 결합

$$
T_{total} = (T_{gray})^\alpha (T_{sink})^{1-\alpha}  
$$

- **출처**
    
    - Liu et al., IEEE TIFS 2012
        
    - Chen et al., IEEE MASS 2010
        

**왜 α를 스윕했는가**

- attack knowledge가 없는 경우 vs 알려진 경우 비교
    
- “adaptive defense” 실험 설계
    

---

# 10. Trust-aware BRPL Metric

## 10.1 BRPL 기본

- **출처**
    
    - Moeller et al., _BRPL: Backpressure RPL_, IEEE INFOCOM 2016
        

---

## 10.2 Trust-penalized Backpressure

$$
BP_{trust} = BP_{ij} \cdot \frac{T^\gamma}{1 + \lambda(1-T)^\gamma}  
$$

- **출처**
    
    - Neely, _Stochastic Network Optimization_, 2010
        
    - Eryilmaz & Srikant, _Fair Resource Allocation_, IEEE INFOCOM 2005
        
    - Liu et al., _Risk-sensitive Routing_, IEEE TNET 2018
        

**왜 이 형태인가**

- numerator: 신뢰 노드 강화
    
- denominator: 저신뢰 노드 급격한 억제
    
- λ, γ는 **risk-sensitivity control parameter**
    

**논문의 가장 독창적인 수식 결합 포인트**

---

# 12. 측정 지표 정의

## PDR

- RFC 6550 / 거의 모든 WSN 논문 공통
    

## Exposure E1 / E3

- **출처**
    
    - Wallner et al., WCNC 2016
        
    - Le et al., IEEE ICC 2013
        

> 공격이 “성능으로 관측되는가”를 정량화하는 지표

## Parent switching rate

- **출처**
    
    - Moeller et al., INFOCOM 2016
        
    - Gnawali et al., SenSys 2009
        

---

