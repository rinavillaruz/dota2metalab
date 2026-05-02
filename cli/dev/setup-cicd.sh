#!/bin/bash

set -euo pipefail

trap 'echo "❌ Error on line $LINENO - deployment failed"' ERR
trap 'echo "👋 Deploy script finished"' EXIT

echo "🚀 Starting ArgoCD deployment..."

# Needs to get ARGOCD_CHART_VERSION from here
# helm repo add argo https://argoproj.github.io/argo-helm
# helm repo update
# helm search repo argo/argo-cd --versions | grep 3.3.9

# Step 1 Install ArgoCD via Helm
ARGOCD_CHART_VERSION="9.5.11"
echo "🚀 Step 1: Installing ArgoCD chart ${ARGOCD_CHART_VERSION}..."
helm upgrade --install argocd argo/argo-cd \
  --namespace argocd \
  --create-namespace \
  --version ${ARGOCD_CHART_VERSION} \
  -f deploy/argocd/values.yaml &

# Saves the process ID
HELM_PID=$!
count=0
while kill -0 $HELM_PID &>/dev/null; do
  count=$((count + 1))
  echo "  ${count}s - installing..."
  sleep 1
done

# wait for helm to finish and get its exit code
wait $HELM_PID    
echo "✅ ArgoCD installed after ${count}s!"

# Step 2 — Wait for all pods to be ready
echo "⏳ Step 2: Waiting for ArgoCD pods to be ready (up to 300s)..."
count=0
while ! kubectl wait --for=condition=Ready pods --all -n argocd --timeout=5s &>/dev/null; do
  count=$((count + 1))
  echo "  ${count}s - waiting..."
  sleep 1
done
echo "✅ ArgoCD pods ready after ${count}s!"

# Step 3 — Apply ArgoCD app
echo "⏳ Step 3: Applying ArgoCD app..."
kubectl apply -f argocd-apps/dota2-dev.yaml
echo "⏳ Waiting for dota2-dev app to sync..."
count=0
while [ "$(kubectl get application dota2-dev -n argocd -o jsonpath='{.status.sync.status}')" != "Synced" ]; do
  count=$((count + 1))
  STATUS=$(kubectl get application dota2-dev -n argocd -o jsonpath='{.status.sync.status}' 2>/dev/null || echo "pending")
  HEALTH=$(kubectl get application dota2-dev -n argocd -o jsonpath='{.status.health.status}' 2>/dev/null || echo "pending")
  echo "  ${count}s - sync: ${STATUS} | health: ${HEALTH}"
  sleep 5
done
echo "✅ ArgoCD app applied and ready!"

echo ""
echo "To get the initial admin password, run:"
echo "  kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
echo ""

# Step 4 — Port forward (blocking)
echo "🚀 Step 4: Starting port-forward on http://localhost:8080 (Ctrl+C to stop)..."
kubectl port-forward svc/argocd-server -n argocd 8080:443