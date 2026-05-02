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
echo "Installing ArgoCD chart ${ARGOCD_CHART_VERSION}..."
helm upgrade --install argocd argo/argo-cd \
  --namespace argocd \
  --create-namespace \
  --version ${ARGOCD_CHART_VERSION} \
  -f deploy/argocd/values.yaml

# Step 2 — Wait for all pods to be ready
echo "Waiting for ArgoCD pods to be ready (up to 300s)..."
kubectl wait --for=condition=Ready pods --all -n argocd --timeout=300s

echo "✅ ArgoCD is ready!"
echo ""
echo "To get the initial admin password, run:"
echo "  kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
echo ""

# Step 3 — Apply ArgoCD app
echo "Applying ArgoCD app..."
kubectl apply -f argocd-apps/dota2-dev.yaml
echo "✅ ArgoCD app applied!"

# Step 4 — Port forward (blocking)
echo "Starting port-forward on http://localhost:8080 (Ctrl+C to stop)..."
kubectl port-forward svc/argocd-server -n argocd 8080:443