#!/bin/bash
set -euo pipefail

BASE_URL="${1:-http://localhost}"
PASS=0
FAIL=0

check() {
    local name="$1"
    local url="$2"
    local expect="$3"

    status=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null || echo "000")
    if [ "$status" = "$expect" ]; then
        echo "  PASS  $name (HTTP $status)"
        PASS=$((PASS + 1))
    else
        echo "  FAIL  $name (expected $expect, got $status)"
        FAIL=$((FAIL + 1))
    fi
}

echo "Smoke Tests - ${BASE_URL}"
echo "================================"

check "Login page loads"           "${BASE_URL}/login/index.php"  "200"
check "Home page loads"            "${BASE_URL}/"                 "200"
check "Admin redirect"             "${BASE_URL}/admin/"           "303"
check "Theme CSS loads"            "${BASE_URL}/theme/styles.php/techcorp/1/all" "200"
check "Cron endpoint"              "${BASE_URL}/admin/cron.php"   "200"
check "Non-existent returns error" "${BASE_URL}/doesnotexist"     "404"

echo "================================"
echo "Results: ${PASS} passed, ${FAIL} failed"
echo

if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
