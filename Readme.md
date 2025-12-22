# 🧠 InfraMind

<div align="center">

**AI-Powered, Dependency-Aware Incident Intelligence for Kubernetes**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.24+-blue.svg)](https://kubernetes.io/)
[![Helm](https://img.shields.io/badge/Helm-3.0+-0f1689.svg)](https://helm.sh/)

</div>

---

## 📖 Overview

InfraMind is a Kubernetes-native **AIOps Copilot** that sits *above* your existing observability stack and answers the hardest operational question:

> **Why did this incident happen — and what should we do next?**

Unlike traditional monitoring tools that surface isolated alerts, InfraMind builds a **live service dependency graph**, computes **holistic service health**, correlates failures across the stack, and performs **causal root-cause analysis** using AI agents.

At its core, InfraMind is powered by **Causely**, a dependency-aware causal reasoning engine for distributed systems.

---

## ✨ Key Features

- 🧩 **Automatic Service Dependency Discovery** — Zero manual configuration required
- 🧠 **Dependency-Aware Root Cause Analysis** — Understand cascading failures
- 📊 **Health-Based Triggers** — Reduce alert fatigue with intelligent health scoring
- 🤖 **Multi-Agent AI Architecture** — Combines LLMs with deterministic logic
- 🚑 **Actionable Remediation** — Get fix suggestions or enable auto-remediation
- 📦 **Kubernetes-Native** — Helm-installable, follows cloud-native best practices
- 🔍 **Observability Integration** — Works with Prometheus, Loki, and Grafana

---

## 🎯 What InfraMind Is NOT

InfraMind does **not** replace your existing observability tools:

- ❌ Not a metrics system (use Prometheus)
- ❌ Not a visualization platform (use Grafana)
- ❌ Not a logging system (use Loki/ELK)
- ❌ Not an alerting system (use Alertmanager)

**InfraMind is the intelligence layer that sits above your observability stack.**

---

## 🧠 Core Philosophy

```
Metrics tell you WHAT happened.
Logs tell you WHERE it happened.
Dependencies tell you WHY it happened.
InfraMind tells you WHAT TO DO.
```

---

## 🏗️ Architecture

```
┌─────────────────────────────────────┐
│  Prometheus / Loki / Kubernetes     │
│  (Metrics, Logs, Events)            │
└──────────────────┬──────────────────┘
                   │
                   ▼
┌─────────────────────────────────────┐
│  InfraMind Ingest Layer             │
│  (Event Collection & Normalization) │
└──────────────────┬──────────────────┘
                   │
                   ▼
┌─────────────────────────────────────┐
│  Causely Reasoning Engine           │
│  (Dependency-Aware RCA)             │
└──────────────────┬──────────────────┘
                   │
                   ▼
┌─────────────────────────────────────┐
│  AI Action & Report Agents          │
│  (LLM-Powered Analysis)             │
└──────────────────┬──────────────────┘
                   │
                   ▼
┌─────────────────────────────────────┐
│  Alerts • Reports • Auto-Fixes      │
└─────────────────────────────────────┘
```

---

## 🧬 Automatic Service Dependency Mapping

InfraMind automatically builds and maintains a **live dependency graph** using:

### 1. **Kubernetes WATCH APIs**
- Monitors Deployments, Pods, Services, ConfigMaps
- Event-driven architecture (no polling)
- Real-time updates

### 2. **Runtime Signals** *(optional/advanced)*
- Observed network flows
- eBPF-based traffic analysis

### 3. **Log Semantics**
- Service names and hostnames
- Retry patterns and error correlations

### Example Dependency Graph

```
checkout-api
  ├── payment-api
  │   └── postgres
  └── redis
```

### Key Properties

- ✅ Event-driven (no polling overhead)
- ✅ Incrementally updated
- ✅ Confidence-weighted edges
- ✅ Automatic stale dependency pruning

---

## 🏥 Health-Based Intelligence

**Key Differentiator**: InfraMind doesn't trigger on raw metrics like CPU spikes.

Instead, it computes **logical health scores (0–100)** that consider:

### Health Layers

1. **Pod Health** — Container restarts, OOM kills, readiness
2. **Deployment Health** — Replica availability, rollout status
3. **Service Health** — Includes dependency health propagation
4. **Cluster Health** — Aggregate system state

### Example Trigger

```yaml
ServiceHealth(checkout-api) < 60 for 90s
```

This approach dramatically reduces alert fatigue and surfaces **only meaningful incidents**.

---



### Auto-Generated Incident Report

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  INCIDENT REPORT: checkout-api-degradation
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Summary:
  Checkout service experienced elevated latency due to 
  Redis memory saturation.

Timeline:
  10:02 — Redis memory pressure detected
  10:05 — checkout-api latency increased (+250ms p99)
  10:07 — Error rate crossed threshold (5%)

Root Cause:
  Redis eviction policy triggered retry storms in 
  checkout-api, amplifying load on payment-api.

Remediation:
  Automatically suggested scaling Redis replicas.
  Action pending approval.

Recommendations:
  • Increase Redis memory limits (2GB → 4GB)
  • Implement exponential backoff in checkout-api
  • Add Redis read replicas for better load distribution

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## 🚑 Remediation Modes

InfraMind supports three remediation modes:

### 1. **Observe-Only** *(Default)*
- No actions taken
- Only alerts and reports generated

### 2. **Approval-Based**
- Remediation suggestions require human approval
- Actions executed via Slack/PagerDuty integration

### 3. **Auto-Remediation** *(Advanced)*
- Executes safe actions automatically
- RBAC-restricted ServiceAccount
- Full audit trail maintained

### Supported Actions

| Action | Description | Safety Level |
|--------|-------------|--------------|
| `rollout restart` | Restart deployment pods | 🟢 Safe |
| `scale deployment` | Adjust replica count | 🟡 Moderate |
| `restart pod` | Force pod restart | 🟡 Moderate |
| `cache flush` | Clear Redis/Memcached | 🟠 Use with caution |

---
