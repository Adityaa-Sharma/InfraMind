# 🧠 InfraMind Agent - Centralized Logging

## What This Does

Installs an **ELK stack** (Elasticsearch + Logstash + Kibana) in your Kubernetes cluster to collect logs from **all pods and services** and view them at a **single port (5601)**.

## Architecture

```
All Pods/Containers → Fluent Bit (DaemonSet) → Elasticsearch → Kibana (:5601)
```

## Quick Install

```bash
cd inframind-agent/helm
./install.sh
```

Or manually:

```bash
helm install inframind ./inframind-agent/helm \
  --namespace inframind \
  --create-namespace
```

## Access Logs

### Option 1: NodePort (External Access)
```bash
# Get node IP
kubectl get nodes -o wide

# Access Kibana at:
http://<NODE_IP>:30561
```

### Option 2: Port Forward
```bash
kubectl port-forward svc/kibana 5601:5601 -n inframind

# Open browser:
http://localhost:5601
```

## View Logs in Kibana

1. Open Kibana in browser
2. Go to **Menu → Discover**
3. Create index pattern: `kubernetes-*`
4. Select time field: `@timestamp`
5. Click **Create index pattern**
6. View all logs!

## Filter Logs

In Kibana Discover view, you can filter by:

- **Namespace:** `kubernetes.namespace_name: "apps"`
- **Pod:** `kubernetes.pod_name: "checkout-api-*"`
- **Container:** `kubernetes.container_name: "checkout"`
- **Log Level:** `level: "ERROR"`

Example query:
```
kubernetes.namespace_name: "apps" AND level: "ERROR"
```

## Configuration

Edit [`values.yaml`](values.yaml) to customize:

```yaml
# Change storage size
elasticsearch:
  storage:
    size: 20Gi  # Default: 10Gi

# Change resource limits
elasticsearch:
  resources:
    limits:
      memory: "4Gi"  # Default: 2Gi
```

## Components Installed

| Component | Type | Purpose |
|-----------|------|---------|
| Fluent Bit | DaemonSet | Collects logs from all pods |
| Elasticsearch | StatefulSet | Stores logs with indexing |
| Kibana | Deployment | Web UI for viewing logs |

## Uninstall

```bash
helm uninstall inframind -n inframind
kubectl delete namespace inframind
```

## Troubleshooting

### Elasticsearch won't start

Check if your cluster allows privileged containers (needed for `vm.max_map_count`):

```bash
kubectl get pods -n inframind
kubectl logs elasticsearch-0 -n inframind
```

### No logs appearing

Check Fluent Bit is running:

```bash
kubectl get daemonset fluent-bit -n inframind
kubectl logs -l app=fluent-bit -n inframind
```

### Kibana shows "No data"

Wait a few minutes for logs to be collected, then create the index pattern.

## Resource Requirements

| Component | CPU | Memory | Storage |
|-----------|-----|--------|---------|
| Fluent Bit | 0.1 | 128Mi | - |
| Elasticsearch | 0.5 | 1-2Gi | 10Gi (PV) |
| Kibana | 0.25 | 512Mi-1Gi | - |

**Total:** ~0.85 CPU, ~2-3Gi RAM, 10Gi storage
