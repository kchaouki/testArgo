#!/usr/bin/env bash
set -euo pipefail

# ── Full cleanup: removes everything installed by setup.sh ──────────────────

CLUSTER_NAME="argocd-cluster"

command_exists() { command -v "$1" &>/dev/null; }

echo ""
echo "=========================================="
echo " Step 1: Delete K3d cluster"
echo "=========================================="

if command_exists k3d && k3d cluster list | grep -q "^${CLUSTER_NAME}"; then
  k3d cluster delete "${CLUSTER_NAME}"
  echo "Cluster '${CLUSTER_NAME}' deleted."
else
  echo "Cluster '${CLUSTER_NAME}' not found, skipping."
fi

echo ""
echo "=========================================="
echo " Step 2: Remove argocd.localhost from /etc/hosts"
echo "=========================================="

if grep -q "argocd.localhost" /etc/hosts; then
  sudo sed -i '' '/argocd.localhost/d' /etc/hosts
  echo "Removed argocd.localhost from /etc/hosts."
else
  echo "argocd.localhost not in /etc/hosts, skipping."
fi

echo ""
echo "=========================================="
echo " Step 3: Uninstall CLI tools"
echo "=========================================="

if command_exists argocd; then
  brew uninstall argocd
  echo "argocd CLI uninstalled."
fi

if command_exists k3d; then
  brew uninstall k3d
  echo "k3d uninstalled."
fi

if brew list kubectl &>/dev/null 2>&1; then
  brew uninstall kubectl
  echo "kubectl uninstalled."
else
  echo "kubectl not managed by Homebrew, skipping."
fi

echo ""
echo "=========================================="
echo " Step 4: Clean up kubeconfig"
echo "=========================================="

if [ -f "$HOME/.kube/config" ]; then
  rm -f "$HOME/.kube/config"
  echo "Removed ~/.kube/config."
fi

echo ""
echo "=========================================="
echo " Done! Everything has been removed."
echo "=========================================="
