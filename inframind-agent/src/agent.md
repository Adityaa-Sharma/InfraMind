# 🤖 InfraMind Agent - Architecture & Flow

## 📋 Table of Contents
- [Overview](#overview)
- [Agent Lifecycle](#agent-lifecycle)
- [Core Components](#core-components)
- [Data Flow](#data-flow)
- [Features](#features)
- [Configuration](#configuration)
- [API Endpoints](#api-endpoints)

---

## 🎯 Overview

The InfraMind Agent is a **Kubernetes-native, self-adapting observability intelligence layer** that:

1. **Discovers** service dependencies automatically
2. **Aggregates** logs from all pods/containers
3. **Computes** holistic health scores
4. **Analyzes** incidents using AI-powered causal reasoning
5. **Recommends** or executes remediation actions

---

## 🔄 Agent Lifecycle

```
┌─────────────────────────────────────────────────────────┐
│  Phase 1: INSTALLATION (Helm Install)                   │
├─────────────────────────────────────────────────────────┤
│  1. User runs: helm install inframind ./agent \         │
│     --set observability.prometheus.url=http://...       │
│     --set logs.provisionELK=true                        │
│                                                          │
│  2. Helm creates:                                        │
│     • Namespace (inframind)                             │
│     • ServiceAccount + RBAC (cluster-wide read access)  │
│     • ConfigMap (user-provided URLs + credentials)      │
│     • Secret (API keys for LLM, tokens)                 │
└─────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────┐
│  Phase 2: INITIALIZATION (Init Container)               │
├─────────────────────────────────────────────────────────┤
│  1. Validate connectivity to observability backends:    │
│     ✓ Prometheus (if URL provided)                      │
│     ✓ Elasticsearch (if existing)                       │
│                                                          │
│  2. Provision ELK stack (if enabled):                   │
│     • Deploy Fluent Bit DaemonSet (log collector)       │
│     • Deploy Elasticsearch StatefulSet (storage)        │
│     • Deploy Kibana Deployment (UI at port 5601)        │
│     • Wait for all pods Ready                           │
│                                                          │
│  3. Write bootstrap status to ConfigMap                 │
└─────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────┐
│  Phase 3: AGENT STARTUP (Main Container)                │
├─────────────────────────────────────────────────────────┤
│  1. Load configuration from ConfigMap/Secrets           │
│  2. Initialize adapters:                                │
│     • PrometheusAdapter (metrics queries)               │
│     • ElasticsearchAdapter (log queries)                │
│     • KubernetesWatcher (K8s events)                    │
│                                                          │
│  3. Start background workers:                           │
│     • Dependency Discovery Engine                       │
│     • Health Computation Loop                           │
│     • Incident Detector                                 │
│     • AI Analysis Queue                                 │
│                                                          │
│  4. Expose HTTP API on port 8080                        │
│  5. Send heartbeat to health check endpoint             │
└─────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────┐
│  Phase 4: RUNTIME OPERATION (Continuous)                │
├─────────────────────────────────────────────────────────┤
│  See "Data Flow" section below                          │
└─────────────────────────────────────────────────────────┘
```

---

## 🧩 Core Components

### **1. Configuration Loader**
**Purpose:** Parse user-provided settings and validate connectivity

**Inputs:**
- `/config/values.yaml` (Helm values)
- `/secrets/api-keys` (LLM credentials)

**Outputs:**
- `ObservabilityConfig` object
- Authenticated HTTP clients for Prometheus/ELK

**Logic:**
```python
class ConfigLoader:
    def load():
        1. Read values.yaml
        2. Extract URLs (Prometheus, Elasticsearch, Grafana)
        3. Extract auth credentials (tokens, passwords)
        4. Test connectivity (HTTP GET to each endpoint)
        5. Return config object OR fail fast with error
```

---

### **2. Kubernetes Watcher**
**Purpose:** Discover service dependencies in real-time

**Method:** Kubernetes WATCH API (event-driven, no polling)

**Watched Resources:**
- `Deployments` (apps/v1)
- `Services` (v1)
- `Pods` (v1)
- `ConfigMaps` (v1)
- `Events` (v1)

**Dependency Extraction Logic:**

```
For each Deployment:
  1. Parse environment variables
     • Look for: *_SERVICE_HOST, *_URL, DATABASE_URL, REDIS_URL
     • Example: PAYMENT_API_URL=http://payment-api.apps:80
     • Extract: checkout-api → payment-api

  2. Parse ConfigMaps (mounted as volumes)
     • Check for service endpoints in YAML/JSON

  3. Parse initContainers
     • Check for wait-for-service dependencies

  4. Infer from Service selectors
     • Match labels: app=checkout → depends on service with same label

Build graph:
  {
    "checkout-api": ["payment-api", "redis"],
    "payment-api": ["postgres"],
    "redis": []
  }
```

**Output:**
- Live dependency graph (updated every 5s)
- Stored in-memory (NetworkX graph or adjacency list)

---

### **3. Log Aggregator (Fluent Bit)**
**Purpose:** Collect logs from ALL pods/containers to single Elasticsearch

**Architecture:**
```
┌─────────────────────────────────────────────────┐
│  Kubernetes Node 1                              │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐        │
│  │ Pod A   │  │ Pod B   │  │ Pod C   │        │
│  │ stdout  │  │ stdout  │  │ stdout  │        │
│  └────┬────┘  └────┬────┘  └────┬────┘        │
│       │            │             │             │
│       └────────────┼─────────────┘             │
│                    │                           │
│         ┌──────────▼─────────┐                │
│         │  Fluent Bit Agent  │                │
│         │  (reads /var/log)  │                │
│         └──────────┬─────────┘                │
└────────────────────┼──────────────────────────┘
                     │
                     ▼
         ┌───────────────────────┐
         │   Elasticsearch       │
         │   Index: k8s-logs-*   │
         └───────────────────────┘
```

**Log Format (Enriched):**
```json
{
  "timestamp": "2026-01-14T10:30:45Z",
  "level": "ERROR",
  "message": "Connection timeout to payment-api",
  "kubernetes": {
    "namespace": "apps",
    "pod": "checkout-api-7d9f8b-abcd",
    "container": "checkout",
    "labels": {
      "app": "checkout-api",
      "version": "v1.2.3"
    }
  },
  "service": "checkout-api"
}
```

**Query Interface:**
```python
logs = elasticsearch.query({
  "namespace": "apps",
  "service": "checkout-api",
  "level": "ERROR",
  "time_range": "last_15m"
})
```

---

### **4. Health Scorer**
**Purpose:** Compute 0-100 health score for each service

**Inputs:**
- Kubernetes metrics (from Prometheus or K8s Metrics API)
- Pod events (restarts, OOMKills)
- Dependency health (recursive)

**Algorithm:**
```python
def compute_health(service: str) -> int:
    score = 100
    
    # 1. Pod-level signals (40% weight)
    pods = get_pods(service)
    for pod in pods:
        if pod.restarts > 3:
            score -= 15
        if pod.status != "Running":
            score -= 20
        if pod.ready == False:
            score -= 10
    
    # 2. Metrics-level signals (40% weight)
    metrics = prometheus.query(service)
    if metrics.error_rate > 0.05:  # 5% errors
        score -= 20
    if metrics.latency_p99 > 2000:  # 2s
        score -= 10
    
    # 3. Dependency health propagation (20% weight)
    deps = dependency_graph.get_dependencies(service)
    for dep in deps:
        dep_health = compute_health(dep)  # Recursive
        if dep_health < 70:
            score -= (100 - dep_health) * 0.2
    
    return max(0, score)
```

**Output:**
```json
{
  "checkout-api": 45,  // UNHEALTHY
  "payment-api": 85,   // HEALTHY
  "redis": 30          // CRITICAL
}
```

---

### **5. Incident Detector**
**Purpose:** Trigger incidents when health drops below threshold

**Trigger Logic:**
```python
UNHEALTHY_THRESHOLD = 60
SUSTAINED_DURATION = 90  # seconds

while True:
    health_scores = health_scorer.compute_all()
    
    for service, score in health_scores.items():
        if score < UNHEALTHY_THRESHOLD:
            # Check if sustained for 90s
            if unhealthy_duration[service] > SUSTAINED_DURATION:
                incident = create_incident(service, score)
                ai_queue.enqueue(incident)
                alert_manager.send(incident)
        else:
            unhealthy_duration[service] = 0
    
    sleep(10)
```

**Incident Object:**
```json
{
  "id": "inc-20260114-001",
  "service": "checkout-api",
  "health_score": 45,
  "detected_at": "2026-01-14T10:30:00Z",
  "symptoms": [
    "High error rate (8%)",
    "Redis dependency unhealthy (score: 30)",
    "3 pod restarts in last 5 minutes"
  ],
  "status": "open"
}
```

---

### **6. Causely Reasoning Engine**
**Purpose:** Perform root cause analysis using dependency graph

**Algorithm:**
```
Given: Unhealthy service S

1. Get all dependencies of S
   deps = graph.get_dependencies(S)

2. Check health of each dependency
   unhealthy_deps = [d for d in deps if health(d) < 60]

3. If unhealthy_deps exist:
   → Root cause likely in dependencies
   → Recurse: analyze_cause(unhealthy_deps[0])

4. If no unhealthy deps:
   → Check S's own metrics
   → Query logs for errors
   → Identify: OOM? High latency? Network issue?

5. Return causal chain:
   "Redis OOM → checkout-api errors → payment-api slow"
```

**Example Output:**
```json
{
  "root_cause": {
    "service": "redis",
    "issue": "Memory pressure (eviction policy triggered)",
    "evidence": [
      "Prometheus: redis_memory_usage > 95%",
      "Logs: 142 eviction events in 10min",
      "K8s Events: OOMKilled 2 times"
    ]
  },
  "propagation_path": [
    "redis (health: 30)",
    "checkout-api (health: 45) - retry storms",
    "payment-api (health: 72) - elevated latency"
  ]
}
```

---

### **7. AI Analysis Agent**
**Purpose:** Generate human-readable incident reports using LLM

**Inputs:**
- Incident object
- Root cause analysis from Causely
- Recent logs (last 15min)
- Metrics snapshots

**Prompt Template:**
```
You are an SRE analyzing a Kubernetes incident.

Service: {service}
Health Score: {health_score}
Symptoms: {symptoms}

Root Cause Analysis:
{causely_output}

Recent Error Logs:
{logs}

Tasks:
1. Summarize the incident in 2-3 sentences
2. Explain the root cause in plain English
3. Suggest 2-3 remediation actions
4. Estimate impact severity (LOW/MEDIUM/HIGH)

Format as structured JSON.
```

**LLM Response:**
```json
{
  "summary": "Checkout API experienced elevated error rates due to Redis memory saturation, causing retry storms.",
  "root_cause_explanation": "Redis hit memory limit and started evicting keys. This caused cache misses in checkout-api, leading to increased database load and retry logic amplifying the problem.",
  "remediation_steps": [
    "Increase Redis memory limit from 2GB to 4GB",
    "Add Redis replica for read distribution",
    "Implement exponential backoff in checkout-api retry logic"
  ],
  "severity": "HIGH",
  "estimated_recovery_time": "15 minutes"
}
```

---

### **8. Remediation Engine (Optional)**
**Purpose:** Execute approved fixes automatically

**Safety Modes:**
- **Manual:** Generate recommendations only
- **Approve:** Wait for human approval via API/Slack
- **Auto:** Execute if confidence > 90%

**Example Actions:**
```python
if remediation_mode == "auto":
    if confidence > 0.9:
        kubectl.scale("redis", replicas=3)
        kubectl.set_resources("redis", memory="4Gi")
        slack.notify("✅ Auto-remediation applied: Redis scaled")
```

---

## 🌊 Data Flow (Runtime)

```
┌─────────────────────────────────────────────────────────┐
│  1. CONTINUOUS MONITORING (Background Loops)            │
├─────────────────────────────────────────────────────────┤
│  • K8s Watcher:    Updates dependency graph (event-driven)
│  • Health Scorer:  Computes scores every 30s            │
│  • Log Aggregator: Streams logs to Elasticsearch        │
└──────────────────────┬──────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────┐
│  2. INCIDENT DETECTION                                  │
├─────────────────────────────────────────────────────────┤
│  Health(checkout-api) = 45 < 60 for 90s                │
│  → Trigger incident                                     │
└──────────────────────┬──────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────┐
│  3. ROOT CAUSE ANALYSIS (Causely)                       │
├─────────────────────────────────────────────────────────┤
│  • Query dependency graph                               │
│  • Check health of dependencies                         │
│  • Query logs for errors                                │
│  • Query Prometheus for anomalies                       │
│  → Output: Causal chain                                 │
└──────────────────────┬──────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────┐
│  4. AI ANALYSIS (LLM Agent)                             │
├─────────────────────────────────────────────────────────┤
│  • Send context to LLM (GPT-4/Claude)                   │
│  • Generate incident report                             │
│  • Suggest remediation steps                            │
└──────────────────────┬──────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────┐
│  5. ACTION & ALERTING                                   │
├─────────────────────────────────────────────────────────┤
│  • Store incident in database                           │
│  • Send alert (Slack/PagerDuty/Email)                   │
│  • Optionally execute auto-remediation                  │
│  • Expose via API: GET /api/incidents/{id}              │
└─────────────────────────────────────────────────────────┘
```

---

## ✨ Features

### **Feature 1: Zero-Config Dependency Discovery**
- ✅ Automatic (no manual service mesh required)
- ✅ Real-time updates (Kubernetes WATCH API)
- ✅ Confidence scoring for edges
- ✅ Visualizable graph (export as GraphML/JSON)

### **Feature 2: Centralized Log Access**
- ✅ Single port (Kibana at `:5601`)
- ✅ All namespaces/pods/containers
- ✅ Structured query interface
- ✅ Retention configurable (default 7 days)

### **Feature 3: Health-Based Triggers**
- ✅ Reduces alert fatigue (no raw metric thresholds)
- ✅ Dependency-aware (propagates health scores)
- ✅ Customizable thresholds per service

### **Feature 4: AI-Powered RCA**
- ✅ Natural language incident reports
- ✅ Actionable remediation steps
- ✅ Multi-LLM support (OpenAI, Azure, Anthropic)

### **Feature 5: Auto-Remediation (Optional)**
- ✅ Safe modes (manual/approve/auto)
- ✅ Rollback on failure
- ✅ Audit log for all actions

---

## ⚙️ Configuration

See [`values.yaml`](../helm/inframind-agent/values.yaml) for full reference.

**Key Settings:**

| Parameter | Description | Default |
|-----------|-------------|---------|
| `observability.prometheus.url` | Prometheus API endpoint | `""` |
| `observability.prometheus.auth.token` | Bearer token for auth | `""` |
| `logs.provisionELK` | Deploy ELK stack? | `true` |
| `logs.elasticsearch.storageSize` | ES persistent volume size | `10Gi` |
| `agent.health.unhealthyThreshold` | Health score trigger | `60` |
| `agent.ai.enabled` | Enable LLM analysis | `true` |
| `agent.ai.provider` | LLM provider | `openai` |

---

## 🌐 API Endpoints

**Base URL:** `http://inframind-agent.inframind:8080`

### **GET /health**
Agent health check
```json
{
  "status": "healthy",
  "uptime": "2h15m",
  "components": {
    "prometheus": "connected",
    "elasticsearch": "connected",
    "kubernetes": "connected"
  }
}
```

### **GET /api/dependencies**
Current dependency graph
```json
{
  "nodes": ["checkout-api", "payment-api", "redis"],
  "edges": [
    {"source": "checkout-api", "target": "payment-api", "confidence": 0.95},
    {"source": "checkout-api", "target": "redis", "confidence": 0.98}
  ]
}
```

### **GET /api/health-scores**
Current service health scores
```json
{
  "checkout-api": 45,
  "payment-api": 85,
  "redis": 30
}
```

### **GET /api/incidents**
List all incidents
```json
[
  {
    "id": "inc-001",
    "service": "checkout-api",
    "status": "open",
    "detected_at": "2026-01-14T10:30:00Z",
    "severity": "HIGH"
  }
]
```

### **GET /api/incidents/{id}**
Full incident report
```json
{
  "id": "inc-001",
  "service": "checkout-api",
  "health_score": 45,
  "root_cause": {
    "service": "redis",
    "issue": "Memory pressure"
  },
  "ai_analysis": {
    "summary": "...",
    "remediation_steps": [...]
  }
}
```

### **POST /api/incidents/{id}/remediate**
Trigger remediation (if approved mode)
```bash
curl -X POST http://inframind-agent:8080/api/incidents/inc-001/remediate
```

---

## 🔒 Security Considerations

- ✅ RBAC: Read-only access to K8s resources
- ✅ Secrets: LLM API keys stored in Kubernetes Secrets
- ✅ Auth: Bearer token validation for API endpoints
- ✅ Network: Internal service mesh (no public exposure)

---

## 📊 Performance Characteristics

| Metric | Value |
|--------|-------|
| Startup time | 30-60s |
| Memory usage | 512MB-2GB (depends on cluster size) |
| CPU usage | 0.2-0.5 cores |
| Log ingestion rate | 10K logs/sec (Fluent Bit) |
| Health check interval | 30s |
| Incident detection latency | <5s after threshold breach |
| AI analysis time | 10-30s (depends on LLM) |

---

## 🚀 Next Steps

1. **Implementation:** Build core components in Python
2. **Testing:** Create dev-env with sample apps
3. **Helm Chart:** Package as distributable chart
4. **Documentation:** API reference, troubleshooting guide
5. **CI/CD:** Automated testing and releases