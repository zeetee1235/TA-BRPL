## Trust-Aware BRPL for RPL-based IoT/WSN Networks

This repository presents an implementation of a **Trust-Aware Backpressure RPL (BRPL)** framework built on top of standard RPL/BRPL in **Contiki-NG** and evaluated using the **Cooja** simulator.

The proposed approach integrates **node-level trust metrics** into the backpressure-based routing decision process to improve network resilience against **routing-layer attacks**, including **selective forwarding (grayhole/blackhole)** and **sinkhole attacks**, in low-power and lossy IoT/WSN environments.

Unlike conventional RPL/BRPL, which primarily optimizes routing based on link metrics and queue backpressure, this work explicitly considers **forwarding behavior reliability** when selecting parents and forwarding paths. By penalizing untrustworthy nodes in the routing process, the protocol aims to:

* Reduce packet loss caused by malicious or misbehaving forwarders
* Maintain higher packet delivery ratios under increasing attack intensity
* Improve robustness without relying on heavyweight cryptographic or intrusion-detection mechanisms

The main objective of this repository is not to propose a standalone security protocol, but to **systematically analyze how trust-aware routing influences BRPL behavior** under adversarial conditions, with a focus on:

* Packet Delivery Ratio (PDR) degradation patterns
* Sensitivity to attack rate and topology structure
* Trade-offs between performance, overhead, and resilience

All experiments are conducted in a **fully reproducible simulation environment**, enabling controlled comparison between baseline RPL/BRPL and the proposed trust-aware variants across multiple network sizes and topologies.
