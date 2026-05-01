#!/bin/bash

set -euo pipefail

trap 'echo "❌ Error on line $LINENO - deployment failed"' ERR
trap 'echo "👋 Deploy script finished"' EXIT

confirm() {
    local message=$1
    local action=$2
    echo "⚠️  $message (y/n)"
    read -r answer
    if [ "$answer" == "y" ]; then
        $action
    else
        echo "⏭️  Skipped."
    fi
}

delete_argocd() {
    echo "🗑️  Deleting argocd..."
    kubectl delete -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
    kubectl delete namespace argocd
    echo "✅ Cluster deleted!"
}

delete_cluster() {
    echo "🗑️  Deleting cluster..."
    kind delete cluster --name dota2metalab-dev
    echo "✅ Cluster deleted!"
}

echo "⚠️  Are you sure you want to delete the dota2metalab argocd? (y/n)"
read -r answer

confirm "Delete ArgoCD?" delete_argocd
confirm "Delete the dota2metalab Kind cluster?" delete_cluster