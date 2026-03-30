#!/usr/bin/env bash
# ALB HA Failover Test — run from repo root: ./test-zadatak9.sh
set -euo pipefail

PROFILE="admin"

ALB_DNS=$(terraform output -raw alb_dns_name)
ALB_URL="http://$ALB_DNS/"
INSTANCE_1=$(terraform output -json test_ec2_instance_ids | jq -r '.[0]')
INSTANCE_2=$(terraform output -json test_ec2_instance_ids | jq -r '.[1]')
ALB_ARN=$(aws elbv2 describe-load-balancers \
  --query "LoadBalancers[?DNSName=='$ALB_DNS'].LoadBalancerArn | [0]" \
  --output text --profile "$PROFILE")
TG_ARN=$(aws elbv2 describe-target-groups \
  --load-balancer-arn "$ALB_ARN" \
  --query 'TargetGroups[0].TargetGroupArn' \
  --output text --profile "$PROFILE")

health() {
  aws elbv2 describe-target-health \
    --target-group-arn "$TG_ARN" \
    --query 'TargetHealthDescriptions[].{Id:Target.Id,State:TargetHealth.State}' \
    --output table --profile "$PROFILE"
}

echo "=== SETUP ==="
echo "ALB : $ALB_URL"
echo "EC2-1: $INSTANCE_1"
echo "EC2-2: $INSTANCE_2"

# --- 1. Baseline ---
echo ""
echo "=== 1. BASELINE ==="
health
echo "--- Round-robin (6 requests) ---"
for i in $(seq 1 6); do curl -s --http1.1 -H 'Connection: close' "$ALB_URL"; done

# --- 2. Failover: stop instance 1 ---
echo ""
echo "=== 2. FAILOVER: stopping EC2-1 ==="
aws ec2 stop-instances --instance-ids "$INSTANCE_1" --profile "$PROFILE" --output text
aws ec2 wait instance-stopped --instance-ids "$INSTANCE_1" --profile "$PROFILE"
echo "Stopped. Waiting 90s for ALB health check..."
sleep 90
health
echo "--- HTTP status (expect 200) ---"
curl -s -o /dev/null -w 'HTTP %{http_code}\n' "$ALB_URL"
echo "--- All traffic should go to EC2-2 only ---"
for i in $(seq 1 4); do curl -s --http1.1 -H 'Connection: close' "$ALB_URL"; done

# --- 3. Full outage: stop instance 2 ---
echo ""
echo "=== 3. FULL OUTAGE: stopping EC2-2 ==="
aws ec2 stop-instances --instance-ids "$INSTANCE_2" --profile "$PROFILE" --output text
aws ec2 wait instance-stopped --instance-ids "$INSTANCE_2" --profile "$PROFILE"
health
echo "--- HTTP status (expect 503 or 504) ---"
curl -s -o /dev/null -w 'HTTP %{http_code}\n' "$ALB_URL"

# --- 4. Recovery ---
echo ""
echo "=== 4. RECOVERY: starting both instances ==="
aws ec2 start-instances --instance-ids "$INSTANCE_1" "$INSTANCE_2" --profile "$PROFILE" --output text
aws ec2 wait instance-running --instance-ids "$INSTANCE_1" "$INSTANCE_2" --profile "$PROFILE"
echo "Running. Waiting 90s for health checks..."
sleep 90
health
echo "--- HTTP status (expect 200) ---"
curl -s -o /dev/null -w 'HTTP %{http_code}\n' "$ALB_URL"
echo "--- Round-robin should be back ---"
for i in $(seq 1 6); do curl -s --http1.1 -H 'Connection: close' "$ALB_URL"; done

echo ""
echo "=== DONE ==="
