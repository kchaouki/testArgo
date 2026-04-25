#!/usr/bin/env bash
set -euo pipefail

# ── Register the ArgoCD Application ────────────────────────────────────────

echo "==> Applying ArgoCD Application manifest..."
kubectl apply -f argocd/application.yml

echo ""
echo "ArgoCD will now watch the repo defined in argocd/application.yml."
echo "Check sync status with:"
echo "  argocd app get myapp"
echo "  argocd app sync myapp   # force immediate sync"
