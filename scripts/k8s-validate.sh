#!/usr/bin/env bash
set -euo pipefail

GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
NC="\e[0m"

pass() { echo -e "${GREEN}[PASS]${NC} $1"; }
fail() { echo -e "${RED}[FAIL]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

echo "------------------------------------------------------------"
echo " Kubernetes Cluster Validation"
echo "------------------------------------------------------------"

# 1. API Server Health
echo -n "Checking API server health... "
if kubectl get --raw='/healthz' >/dev/null 2>&1; then
  pass "API server is healthy"
else
  fail "API server is NOT healthy"
fi

# 2. Node Ready Status
echo -n "Checking node readiness... "
READY=$(kubectl get nodes -o jsonpath='{.items[*].status.conditions[?(@.type=="Ready")].status}' || echo "")
if [[ "$READY" == *"True"* ]]; then
  pass "Node(s) Ready"
else
  fail "Node(s) NOT Ready"
fi

# 3. Control Plane Components
echo "Checking control-plane components..."
for comp in etcd kube-apiserver kube-controller-manager kube-scheduler; do
  if kubectl get pods -n kube-system | grep -q "$comp"; then
    STATUS=$(kubectl get pods -n kube-system | grep "$comp" | awk '{print $3}')
    RESTARTS=$(kubectl get pods -n kube-system | grep "$comp" | awk '{print $4}')
    if [[ "$STATUS" == "Running" && "$RESTARTS" -lt 3 ]]; then
      pass "$comp running (restarts: $RESTARTS)"
    else
      fail "$comp unhealthy (status: $STATUS, restarts: $RESTARTS)"
    fi
  else
    fail "$comp pod not found"
  fi
done

# 4. CNI / Flannel
echo -n "Checking Flannel CNI... "
if kubectl get pods -n kube-flannel >/dev/null 2>&1; then
  FLANNEL_STATUS=$(kubectl get pods -n kube-flannel -o jsonpath='{.items[*].status.phase}')
  if [[ "$FLANNEL_STATUS" == *"Running"* ]]; then
    pass "Flannel running"
  else
    fail "Flannel not running"
  fi
else
  fail "Flannel namespace missing"
fi

# 5. kube-proxy
echo -n "Checking kube-proxy... "
if kubectl get pods -n kube-system | grep -q kube-proxy; then
  STATUS=$(kubectl get pods -n kube-system | grep kube-proxy | awk '{print $3}')
  if [[ "$STATUS" == "Running" ]]; then
    pass "kube-proxy running"
  else
    fail "kube-proxy unhealthy (status: $STATUS)"
  fi
else
  fail "kube-proxy pod missing"
fi

# 6. DNS Test
echo -n "Testing DNS resolution... "
if kubectl run dns-test --image=busybox:1.28 --restart=Never --rm -it -- nslookup kubernetes.default >/dev/null 2>&1; then
  pass "DNS resolution OK"
else
  fail "DNS resolution FAILED"
fi

# 7. Pod Scheduling Test
echo -n "Testing pod scheduling... "
kubectl run schedule-test --image=nginx --restart=Never >/dev/null 2>&1 || true
sleep 3
STATUS=$(kubectl get pod schedule-test -o jsonpath='{.status.phase}' 2>/dev/null || echo "")
if [[ "$STATUS" == "Running" ]]; then
  pass "Pod scheduling OK"
else
  fail "Pod scheduling FAILED (status: $STATUS)"
fi
kubectl delete pod schedule-test --force --grace-period=0 >/dev/null 2>&1 || true

# 8. Service Test
echo -n "Testing service creation... "
kubectl create deployment svc-test --image=nginx >/dev/null 2>&1 || true
kubectl expose deployment svc-test --port=80 --type=ClusterIP >/dev/null 2>&1 || true
if kubectl get svc svc-test >/dev/null 2>&1; then
  pass "Service creation OK"
else
  fail "Service creation FAILED"
fi
kubectl delete deployment svc-test --force --grace-period=0 >/dev/null 2>&1 || true
kubectl delete svc svc-test --force --grace-period=0 >/dev/null 2>&1 || true

echo "------------------------------------------------------------"
echo " Validation Complete"
echo "------------------------------------------------------------"
