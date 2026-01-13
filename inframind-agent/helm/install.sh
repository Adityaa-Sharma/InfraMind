#!/usr/bin/env bash
set -e

CHART_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NAMESPACE="inframind"

echo "========================================="
echo "🚀 InfraMind Agent Installation"
echo "========================================="

echo "📦 Installing InfraMind Agent with centralized logging..."
helm upgrade --install inframind "$CHART_DIR" \
  --namespace $NAMESPACE \
  --create-namespace \
  --wait \
  --timeout 5m

echo ""
echo "⏳ Waiting for Elasticsearch to be ready..."
kubectl wait --for=condition=ready pod \
  -l app=elasticsearch \
  -n $NAMESPACE \
  --timeout=300s

echo ""
echo "⏳ Waiting for Kibana to be ready..."
kubectl wait --for=condition=ready pod \
  -l app=kibana \
  -n $NAMESPACE \
  --timeout=300s

echo ""
echo "========================================="
echo "✅ InfraMind Agent Installed Successfully"
echo "========================================="
echo ""
echo "📊 All components:"
kubectl get pods -n $NAMESPACE
echo ""
echo "🌐 Access Kibana (Web UI for all logs):"
echo ""
echo "Option 1: NodePort (recommended)"
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
echo "  http://$NODE_IP:30561"
echo ""
echo "Option 2: Port-forward"
echo "  kubectl port-forward svc/kibana 5601:5601 -n $NAMESPACE"
echo "  Then open: http://localhost:5601"
echo ""
echo "📝 View logs in Kibana:"
echo "  1. Go to Menu → Discover"
echo "  2. Create index pattern: kubernetes-*"
echo "  3. Time field: @timestamp"
echo "  4. View all logs from all pods/services!"
echo ""
