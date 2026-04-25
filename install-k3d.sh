#!/usr/bin/env bash
set -euo pipefail

# ── K3d + kubectl installer for macOS ──────────────────────────────────────

CLUSTER_NAME="argocd-cluster"
K3D_VERSION="v5.7.4"

command_exists() { command -v "$1" &>/dev/null; }

echo "==> Checking dependencies..."

# ── Homebrew ────────────────────────────────────────────────────────────────
if ! command_exists brew; then
  echo "Homebrew not found. Installing..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# ── kubectl ─────────────────────────────────────────────────────────────────
if ! command_exists kubectl; then
  echo "==> Installing kubectl..."
  brew install kubectl
else
  echo "kubectl already installed: $(kubectl version --client --short 2>/dev/null || kubectl version --client)"
fi

# ── K3d ─────────────────────────────────────────────────────────────────────
if ! command_exists k3d; then
  echo "==> Installing k3d ${K3D_VERSION}..."
  brew install k3d
else
  echo "k3d already installed: $(k3d version)"
fi

# ── Create cluster ───────────────────────────────────────────────────────────
echo "==> Creating k3d cluster '${CLUSTER_NAME}'..."
k3d cluster create "${CLUSTER_NAME}" \
  --agents 2 \
  --port "8080:80@loadbalancer" \
  --port "8443:443@loadbalancer" \
  --port "9090:80@loadbalancer"

echo "==> Setting kubectl context..."
k3d kubeconfig merge "${CLUSTER_NAME}" --kubeconfig-merge-default
kubectl config use-context "k3d-${CLUSTER_NAME}"

echo ""
echo "Cluster is ready. Nodes:"
kubectl get nodes
echo ""
echo "Next step: run ./install-argocd.sh"
