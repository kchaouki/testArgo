#!/usr/bin/env bash
set -euo pipefail

# ── ArgoCD installer ────────────────────────────────────────────────────────

ARGOCD_VERSION="v2.13.5"
NAMESPACE="argocd"

command_exists() { command -v "$1" &>/dev/null; }

# ── argocd CLI ──────────────────────────────────────────────────────────────
if ! command_exists argocd; then
  echo "==> Installing argocd CLI..."
  brew install argocd
else
  echo "argocd CLI already installed: $(argocd version --client --short 2>/dev/null | head -1)"
fi

# ── Install ArgoCD into the cluster ─────────────────────────────────────────
echo "==> Creating namespace '${NAMESPACE}'..."
kubectl create namespace "${NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -

echo "==> Applying ArgoCD manifests (${ARGOCD_VERSION})..."
kubectl apply -n "${NAMESPACE}" \
  -f "https://raw.githubusercontent.com/argoproj/argo-cd/${ARGOCD_VERSION}/manifests/install.yaml"

echo "==> Waiting for ArgoCD server to be ready (up to 3 min)..."
kubectl rollout status deployment/argocd-server -n "${NAMESPACE}" --timeout=180s

# ── Retrieve initial admin password ─────────────────────────────────────────
echo ""
echo "==> Initial admin password:"
kubectl get secret argocd-initial-admin-secret \
  -n "${NAMESPACE}" \
  -o jsonpath="{.data.password}" | base64 --decode
echo ""

# ── Port-forward instructions ────────────────────────────────────────────────
echo ""
echo "ArgoCD is ready."
echo ""
echo "To open the UI, run in a separate terminal:"
echo "  kubectl port-forward svc/argocd-server -n argocd 9090:443"
echo "Then open: https://localhost:9090  (user: admin)"
echo ""
echo "Next step: run ./apply-app.sh to register your app with ArgoCD."
