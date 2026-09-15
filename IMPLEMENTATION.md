# FocusGuard - Technical Implementation Details

This document outlines key engineering decisions, mathematical models, and implementation trade-offs made during the creation of FocusGuard.

---

## 1. Key Design Decisions & Trade-Offs

### 1.1 Pure Dart Domain Layer vs Framework Tight-Coupling
- **Decision**: All domain models, the session state machine, monotonic timer logic, break managers, and override coordinators are written in pure, decoupled Dart with zero dependencies on `flutter/material.dart`.
- **Rationale**: Enables lightning-fast, headless unit testing in microseconds, guarantees deterministic behavior, and isolates core business logic from UI rendering lifecycles.

### 1.2 Hardware Monotonic Time vs Wall-Clock Timestamps
- **Decision**: Timers use continuous elapsed uptime (`elapsedRealtime`) rather than wall-clock `DateTime.now()`.
- **Trade-Off**: Reboots reset the hardware monotonic counter to 0.
- **Solution**: FocusGuard persists elapsed session duration checkpoints to SQLite every 5 seconds. On boot recovery, the engine calculates the duration gap and adjusts remaining seconds safely.

### 1.3 Polling UsageStats vs Native Accessibility Service
- **Decision**: Provide UsageStatsManager polling (500ms) as the default engine, with an optional Accessibility Service module.
- **Rationale**: While Accessibility provides zero-latency window interception, Google Play heavily restricts apps using accessibility services. By supporting both, FocusGuard offers maximum store compliance while allowing sideloaded users to enable instantaneous hardware interception.

### 1.4 Single-Process Flutter Architecture with Native Service Companion
- **Decision**: Run a lightweight Kotlin `ForegroundService` that maintains a sticky notification and monitoring loop, communicating with the Flutter engine via typed `MethodChannel`.
- **Rationale**: Keeps memory footprint low (<35MB idle) while ensuring the Android OS respects service execution priority.

---

## 2. Formal Specification of Session State Machine

Let $S = \{\text{idle}, \text{starting}, \text{active}, \text{inBreak}, \text{paused}, \text{completed}, \text{cancelled}, \text{emergencyExited}\}$ be the finite set of states.

Let $\Sigma = \{\text{start}, \text{activate}, \text{break}, \text{resume}, \text{pause}, \text{complete}, \text{cancel}, \text{emergencyExit}\}$ be the input alphabet.

The transition function $\delta: S \times \Sigma \to S$ is defined as follows:
- $\delta(\text{idle}, \text{start}) = \text{starting}$
- $\delta(\text{starting}, \text{activate}) = \text{active}$
- $\delta(\text{active}, \text{break}) = \text{inBreak}$
- $\delta(\text{inBreak}, \text{resume}) = \text{active}$
- $\delta(\text{active}, \text{pause}) = \text{paused}$
- $\delta(\text{paused}, \text{resume}) = \text{active}$
- $\delta(\text{active}, \text{complete}) = \text{completed}$
- $\delta(\text{inBreak}, \text{complete}) = \text{completed}$
- $\delta(\text{active}, \text{cancel}) = \text{cancelled}$
- $\delta(\text{paused}, \text{cancel}) = \text{cancelled}$
- $\forall s \in \{\text{starting}, \text{active}, \text{inBreak}, \text{paused}\}, \; \delta(s, \text{emergencyExit}) = \text{emergencyExited}$

All other transitions $\delta(s, \sigma)$ are undefined and throw a `StateError`.

---

## 3. Cryptographic State Checksumming

For tamper-evident audit logging, each audit record stores:
$$\text{Checksum} = \text{SHA-256}(\text{prevChecksum} \mathbin{\Vert} \text{timestamp} \mathbin{\Vert} \text{eventType} \mathbin{\Vert} \text{payload})$$
This forms a local cryptographic hash chain in `audit_logs`, preventing undetected tampering or row deletion in SQLite.
