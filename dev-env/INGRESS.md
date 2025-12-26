# 🌐 InfraMind Ingress Setup

This document explains how to access InfraMind services via Nginx Ingress Controller.

## 📋 Prerequisites

The `rebuild-all.sh` script automatically installs and configures:
- Nginx Ingress Controller
- Ingress resources for all services
- Proper routing rules

## 🔧 Setup Hosts File

To access services via domain names, add these entries to your hosts file:

### Windows
Run PowerShell **as Administrator**:
```powershell
cd dev-env/scripts
.\setup-hosts.ps1
```

Or manually edit `C:\Windows\System32\drivers\etc\hosts`:
```
127.0.0.1 inframind.local
127.0.0.1 observability.local
```

### Linux/Mac
Run with sudo:
```bash
cd dev-env/scripts
sudo ./setup-hosts.sh
```

Or manually edit `/etc/hosts`:
```
127.0.0.1 inframind.local
127.0.0.1 observability.local
```

## 🌐 Access URLs

Once the cluster is running and hosts file is configured:

### Main Application
- **Frontend**: http://inframind.local
- **Checkout API**: http://inframind.local/api/checkout
- **Payment API**: http://inframind.local/api/payment

### Observability Stack
- **Prometheus**: http://observability.local/prometheus
- **Grafana**: http://observability.local/grafana
  - Default credentials: `admin` / `prom-operator`
- **Loki**: http://observability.local/loki

## 🔍 Verify Ingress

Check ingress resources:
```bash
kubectl get ingress -A
```

Expected output:
```
NAMESPACE       NAME                    CLASS   HOSTS                 PORTS   AGE
apps            inframind-ingress       nginx   inframind.local       80      5m
observability   observability-ingress   nginx   observability.local   80      5m
```

Check ingress controller:
```bash
kubectl get pods -n ingress-nginx
```

## 🐛 Troubleshooting

### Cannot access via domain names
1. Verify hosts file entries are correct
2. Clear browser cache or use incognito mode
3. Try `curl http://inframind.local` from terminal

### Ingress controller not ready
```bash
# Check controller status
kubectl get pods -n ingress-nginx

# View controller logs
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller
```

### 502 Bad Gateway
- Service might not be ready yet
- Check pod status: `kubectl get pods -n apps`
- Check service endpoints: `kubectl get endpoints -n apps`

### Port already in use
If ports 80 or 443 are already in use on your host:
1. Stop conflicting services (IIS, Apache, etc.)
2. Or use port-forward instead (see below)

## 🔄 Alternative: Port Forwarding

If you prefer not to use ingress or can't modify hosts file:

```bash
# Frontend
kubectl port-forward svc/inframind-frontend 3000:80 -n apps

# Prometheus
kubectl port-forward svc/prometheus-kube-prometheus-prometheus 9090:9090 -n observability

# Grafana
kubectl port-forward svc/prometheus-grafana 3001:80 -n observability
```

Then access at:
- Frontend: http://localhost:3000
- Prometheus: http://localhost:9090
- Grafana: http://localhost:3001

## 🏗️ Ingress Architecture

```
┌─────────────────────────────────────────┐
│         Nginx Ingress Controller        │
│              (Port 80/443)              │
└─────────────────┬───────────────────────┘
                  │
      ┌───────────┴──────────┐
      │                      │
      ▼                      ▼
┌─────────────┐      ┌──────────────────┐
│ inframind.  │      │ observability.   │
│   local     │      │     local        │
└──────┬──────┘      └────────┬─────────┘
       │                      │
   ┌───┴────┬────────┐   ┌───┴────┬────────┐
   ▼        ▼        ▼   ▼        ▼        ▼
frontend checkout payment  prom  grafana loki
```

## 📝 Custom Domain Configuration

To use custom domains:

1. Edit [ingress/ingress.yaml](ingress/ingress.yaml)
2. Change `host:` values to your desired domains
3. Update hosts file accordingly
4. Reapply: `kubectl apply -f ingress/`

Example:
```yaml
spec:
  rules:
  - host: myapp.example.com
    http:
      paths: ...
```
