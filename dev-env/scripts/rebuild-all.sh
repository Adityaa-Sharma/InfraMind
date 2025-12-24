#!/usr/bin/env bash
set -e

CLUSTER_NAME="inframind"

echo "========================================="
echo "🧨 InfraMind FULL CLUSTER REBUILD STARTED"
echo "========================================="

echo "🗑️  Deleting existing kind cluster (if any)..."
kind delete cluster --name $CLUSTER_NAME || true

echo "🚀 Creating kind cluster..."
kind create cluster --name $CLUSTER_NAME --config kind/cluster.yaml

echo "⏳ Waiting for cluster to stabilize..."
sleep 10

echo "📦 Creating namespaces..."
kubectl apply -f namespaces/

echo "📊 Installing Prometheus..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts || true
helm repo update

helm install prometheus prometheus-community/kube-prometheus-stack \
  -n observability \
  -f observability/prometheus/values.yml

echo "📜 Installing Loki..."
helm repo add grafana https://grafana.github.io/helm-charts || true
helm repo update

helm install loki grafana/loki-stack \
  -n observability \
  -f observability/loki/values.yml

echo "⏳ Waiting for observability stack..."
sleep 30

echo "🧩 Deploying sample applications..."
kubectl apply -f apps/checkout/
kubectl apply -f apps/payments/
kubectl apply -f apps/redis/
kubectl apply -f traffic/

echo "🎨 Deploying dev frontend..."
kubectl apply -f frontend/

echo "⏳ Waiting for apps to become ready..."
kubectl rollout status deployment checkout-api -n apps
kubectl rollout status deployment payment-api -n apps
kubectl rollout status deployment redis -n apps

echo "========================================="
echo "✅ InfraMind DEV CLUSTER READY"
echo "========================================="

echo ""
echo "🔎 Verify:"
echo "kubectl get pods -A"
echo ""
echo "🌐 Access:"
echo "Prometheus : kubectl port-forward svc/prometheus-kube-prometheus-prometheus 9090:9090 -n observability"
echo "Grafana    : kubectl port-forward svc/prometheus-grafana 3001:80 -n observability"
echo "Frontend   : kubectl port-forward svc/inframind-frontend 3000:80 -n inframind-dev"
