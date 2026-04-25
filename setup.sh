#!/usr/bin/env bash
set -euo pipefail

# ── Full setup: K3d cluster + ArgoCD + App ──────────────────────────────────

CLUSTER_NAME="argocd-cluster"
NAMESPACE_ARGOCD="argocd"
ARGOCD_VERSION="v2.13.5"

command_exists() { command -v "$1" &>/dev/null; }

echo ""
echo "=========================================="
echo " Step 1: Install dependencies"
echo "=========================================="

if ! command_exists brew; then
  echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

if ! command_exists kubectl; then
  echo "Installing kubectl..."
  brew install kubectl
else
  echo "kubectl already installed."
fi

if ! command_exists k3d; then
  echo "Installing k3d..."
  brew install k3d
else
  echo "k3d already installed."
fi

if ! command_exists argocd; then
  echo "Installing argocd CLI..."
  brew install argocd
else
  echo "argocd CLI already installed."
fi

echo ""
echo "=========================================="
echo " Step 2: Create K3d cluster"
echo "=========================================="

k3d cluster create "${CLUSTER_NAME}" \
  --agents 2 \
  --port "8080:80@loadbalancer" \
  --port "8443:443@loadbalancer" \
  --port "9090:80@loadbalancer"

k3d kubeconfig merge "${CLUSTER_NAME}" --kubeconfig-merge-default
kubectl config use-context "k3d-${CLUSTER_NAME}"

echo ""
echo "Nodes:"
kubectl get nodes

echo ""
echo "=========================================="
echo " Step 3: Install ArgoCD"
echo "=========================================="

kubectl create namespace "${NAMESPACE_ARGOCD}" --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -n "${NAMESPACE_ARGOCD}" \
  -f "https://raw.githubusercontent.com/argoproj/argo-cd/${ARGOCD_VERSION}/manifests/install.yaml"

echo "Waiting for ArgoCD server (up to 3 min)..."
kubectl rollout status deployment/argocd-server -n "${NAMESPACE_ARGOCD}" --timeout=180s

# Run argocd-server in HTTP mode so Traefik ingress works without TLS
kubectl patch deployment argocd-server -n "${NAMESPACE_ARGOCD}" \
  --type json \
  -p='[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--insecure"}]'

kubectl rollout status deployment/argocd-server -n "${NAMESPACE_ARGOCD}" --timeout=60s

echo ""
echo "=========================================="
echo " Step 4: Apply Ingresses"
echo "=========================================="

kubectl apply -f argocd/ingress.yml

# Add argocd.localhost to /etc/hosts if not already present
if ! grep -q "argocd.localhost" /etc/hosts; then
  echo "Adding argocd.localhost to /etc/hosts (requires sudo)..."
  echo "127.0.0.1 argocd.localhost" | sudo tee -a /etc/hosts
else
  echo "argocd.localhost already in /etc/hosts, skipping."
fi

echo ""
echo "=========================================="
echo " Step 5: Register App with ArgoCD"
echo "=========================================="

kubectl apply -f argocd/application.yml

echo ""
echo "=========================================="
echo " Done!"
echo "=========================================="

ARGOCD_PASS=$(kubectl get secret argocd-initial-admin-secret \
  -n "${NAMESPACE_ARGOCD}" \
  -o jsonpath="{.data.password}" | base64 --decode)

echo ""
echo "  ArgoCD UI : http://argocd.localhost:9090"
echo "  User      : admin"
echo "  Password  : ${ARGOCD_PASS}"
echo ""
echo "  App       : http://localhost:8080"
echo ""
echo "ArgoCD will auto-sync your repo every 3 minutes."
