#!/bin/bash

set -euo pipefail

trap 'echo "❌ Error on line $LINENO - teardown failed"' ERR
trap 'echo "👋 Teardown script finished"' EXIT

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
    echo "🗑️  Deleting ArgoCD..."
    helm uninstall argocd --namespace argocd 2>/dev/null || echo "ArgoCD not found, skipping..."
    kubectl delete namespace argocd --ignore-not-found 2>/dev/null || true

    echo "⏳ Waiting for argocd namespace to be fully deleted..."
    count=0
    while kubectl get namespace argocd &>/dev/null; do
        count=$((count + 1))
        echo "  ${count}s - still deleting..."

        # After 10 seconds, force remove finalizers
        if [ $count -eq 10 ]; then
            echo "  ⚠️  Stuck! Force removing finalizers..."
            kubectl patch namespace argocd \
                -p '{"metadata":{"finalizers":[]}}' \
                --type=merge 2>/dev/null || true
        fi

        if [ $count -eq 30 ]; then
            echo "  ⚠️  Stuck for 30s! Skipping — cluster deletion will clean it up..."
            break
        fi

        sleep 1
    done
    echo "✅ ArgoCD deleted after ${count}s!"
}

delete_cluster() {
    echo "🗑️  Deleting cluster..."
    kind delete cluster --name dota2metalab 2>/dev/null || echo "Cluster not found, skipping..."
    echo "⏳ Waiting for cluster to be fully deleted..."
    count=0
    while kind get clusters | grep dota2metalab &>/dev/null; do
        count=$((count + 1))
        echo "${count}s - still deleting..."
        sleep 1
    done
    echo "✅ Cluster deleted! after ${count}s!"
}

confirm "Delete ArgoCD?" delete_argocd
confirm "Delete the dota2metalab Kind cluster?" delete_cluster