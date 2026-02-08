# Network Topologies for Trust-Aware BRPL Evaluation

This document describes the four network topologies used in the evaluation of trust-aware BRPL routing protocol.

## Common Experimental Setup

- **Field Size**: 200m × 200m (coordinates: x,y ∈ [0,200])
- **Root (Sink)**: Fixed at (100, 100)
- **Node Count** (Total, including Root):
  - **S (Small)**: 16 nodes (Root 1 + Normal 14 + Attacker 1)
  - **M (Medium)**: 36 nodes (Root 1 + Normal 34 + Attacker 1)
  - **L (Large)**: 64 nodes (Root 1 + Normal 62 + Attacker 1)
- **Radio Model**: UDGM (Unit Disk Graph Medium)
  - TX Range: 50m
  - Interference Range: 60m
- **Attackers**: 1 per topology (strategically positioned)

## Topology 1: GRID - High Path Diversity

**Purpose**: Evaluate protocol performance in environments with multiple alternative paths.

**Characteristics**:
- Regular grid layout with uniform node spacing
- High path diversity - multiple routing alternatives available
- Sinkhole attacks have measurable but limited impact
- Grayhole attacks show gradual degradation

**Node Placement Rules**:
- **S**: 4×4 grid, 40m step spacing
  - Grid points: x,y ∈ {40, 80, 120, 160}
  - Attacker: (120, 100) - near root for plausible good link
- **M**: 6×6 grid, 30m step spacing
  - Grid points: x,y ∈ {25, 55, 85, 115, 145, 175}
  - Attacker: (115, 100)
- **L**: 8×8 grid, 25m step spacing
  - Grid points: x,y ∈ {12.5, 37.5, 62.5, 87.5, 112.5, 137.5, 162.5, 187.5}
  - Attacker: (112.5, 100)

**Expected Observations**:
- Sinkhole: Moderate PDR degradation (alternative paths mitigate impact)
- Grayhole: Gradual performance curves as attack rate increases

## Topology 2: TWO-CLUSTER + BOTTLENECK - Gateway Vulnerability

**Purpose**: Model realistic scenarios with geographic clustering and gateway dependencies.

**Characteristics**:
- Two distinct clusters connected through a narrow gateway
- Bottleneck creates natural choke point
- Attacker at gateway position maximizes exposure
- Highest attack visibility among all topologies

**Node Placement Rules**:
- Left cluster center: (55, 100)
- Right cluster center: (145, 100)
- Gateway/Bottleneck attacker: (100, 120)
- **S**: 7 nodes per cluster in circular pattern
- **M**: 17 nodes per cluster (radius 25m from center)
- **L**: 31 nodes per cluster (radius 35m from center)

**Expected Observations**:
- Sinkhole: Severe impact - bottleneck control causes subtree traffic concentration
- Grayhole: Near-linear relationship between attack rate and PDR (high exposure)

## Topology 3: CORRIDOR/CHAIN - Minimal Path Diversity

**Purpose**: Evaluate worst-case scenarios with linear topology and minimal alternatives.

**Characteristics**:
- Linear corridor layout (smart building/tunnel/pipeline scenario)
- Extremely low path diversity
- Attack effects are critical and immediately visible
- No alternative paths for recovery

**Node Placement Rules**:
- All nodes along y=100 line (horizontal corridor)
- **S**: 12m spacing, x ∈ {20, 32, 44, ..., 180}
  - Attacker: (92, 100) - intermediate hop near root
- **M**: 5m spacing, x ∈ {10, 15, 20, ..., 175}
  - Attacker: (85, 100)
- **L**: 3m spacing, x ∈ {5, 8, 11, ..., 190}
  - Attacker: (88, 100)

**Expected Observations**:
- Sinkhole: Near-complete control possible (especially with RSSI/ETX-based selection)
- Grayhole: Direct mapping of attack rate to PDR (no path alternatives)

## Topology 4: RING + SPOKES - Intermediate Case

**Purpose**: Model industrial/smart city scenarios with hub-and-spoke architecture.

**Characteristics**:
- Central gateway with peripheral ring structure
- Intermediate path diversity (between GRID and CORRIDOR)
- Common in industrial monitoring and smart city deployments
- Attacker near root affects multiple spokes

**Node Placement Rules**:
- Ring center at root: (100, 100)
- Nodes uniformly distributed on ring
- **S**: Ring radius 60m, 14 nodes
  - Angular spacing: 360°/14 ≈ 25.7°
  - Attacker: (100, 120)
- **M**: Ring radius 70m, 35 nodes (inner + outer rings)
  - Attacker: (100, 120)
- **L**: Ring radius 80m, 67 nodes (multiple concentric rings)
  - Attacker: (100, 120)

**Expected Observations**:
- Sinkhole: Moderate to high impact depending on spoke count
- Grayhole: Intermediate performance degradation curves

## File Organization

All topology files are located in `configs/topologies/`:

```
GRID_S.csv, GRID_S.csc       # Grid Small (16 nodes)
GRID_M.csv, GRID_M.csc       # Grid Medium (36 nodes)
GRID_L.csv, GRID_L.csc       # Grid Large (64 nodes)

CLUSTER_S.csv, CLUSTER_S.csc # Two-Cluster Small (16 nodes)
CLUSTER_M.csv, CLUSTER_M.csc # Two-Cluster Medium (36 nodes)
CLUSTER_L.csv, CLUSTER_L.csc # Two-Cluster Large (64 nodes)

CORRIDOR_S.csv, CORRIDOR_S.csc # Corridor Small (16 nodes)
CORRIDOR_M.csv, CORRIDOR_M.csc # Corridor Medium (36 nodes)
CORRIDOR_L.csv, CORRIDOR_L.csc # Corridor Large (64 nodes)

RING_S.csv, RING_S.csc       # Ring Small (16 nodes)
RING_M.csv, RING_M.csc       # Ring Medium (36 nodes)
RING_L.csv, RING_L.csc       # Ring Large (64 nodes)
```

- `.csv` files: Node positions (node_id, x, y, role)
- `.csc` files: Complete Cooja simulation configurations

## Topology Selection Rationale

These four topologies provide comprehensive coverage of realistic WSN deployment scenarios:

1. **GRID**: Best-case for resilience (high path diversity)
2. **CLUSTER**: Realistic geography with identifiable vulnerabilities
3. **CORRIDOR**: Worst-case for attacks (minimal alternatives)
4. **RING**: Common industrial/IoT pattern (intermediate case)

The systematic variation in path diversity (PD) allows evaluation of topology-dependent attack effectiveness and trust mechanism performance across different network conditions.
