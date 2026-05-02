#!/bin/bash

set -euo pipefail

trap 'echo "❌ Error on line $LINENO - deployment failed"' ERR
trap 'echo "👋 Deploy script finished"' EXIT

echo "🚀 Starting ArgoCD deployment..."

# Step 1 — Create the ArgoCD namespace
echo "Creating ArgoCD namespace..."
kubectl create namespace argocd 2>/dev/null || echo "Namespace already exists, skipping."

# Step 2 — Install ArgoCD
echo "Installing ArgoCD..."
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Step 3 — Wait for all pods to be ready
echo "Waiting for ArgoCD pods to be ready (up to 300s)..."
kubectl wait --for=condition=Ready pods --all -n argocd --timeout=300s

echo "✅ ArgoCD is ready!"
echo ""
echo "To get the initial admin password, run:"
echo "  kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
echo ""

# Step 4 — Apply ArgoCD app
echo "Applying ArgoCD app..."
kubectl apply -f argocd-apps/dota2-dev.yaml
echo "✅ ArgoCD app applied!"

# Step 5 — Port forward (blocking)
echo "Starting port-forward on http://localhost:8080 (Ctrl+C to stop)..."
kubectl port-forward svc/argocd-server -n argocd 8080:443