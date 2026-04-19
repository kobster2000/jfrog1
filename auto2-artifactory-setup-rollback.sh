#!/usr/bin/env bash
set -euo pipefail

BASE="https://interviewkobil.jfrog.io/artifactory"
USER="kobster2000@gmail.com"
PASS="Password@123"

auth=(-u "${USER}:${PASS}")

del() {
  url="$1"
  code=$(curl -s -o /dev/null -w "%{http_code}" "${auth[@]}" -X DELETE "$url")
  if [[ "$code" == "200" || "$code" == "204" || "$code" == "404" ]]; then
    echo "OK ($code): $url"
  else
    echo "FAIL ($code): $url"
    return 1
  fi
}

echo "=== DELETE ARTIFACTS ==="
del "$BASE/auto2-generic-dev-local/team-a"
del "$BASE/auto2-generic-dev-local/shared"

echo "=== DELETE PERMISSIONS ==="
del "$BASE/api/v2/security/permissions/auto2-maven-read"
del "$BASE/api/v2/security/permissions/auto2-generic-team-a"
del "$BASE/api/v2/security/permissions/auto2-generic-team-b"

echo "=== DELETE GROUPS ==="
del "$BASE/api/security/groups/auto2-team-a-group"
del "$BASE/api/security/groups/auto2-team-b-group"
del "$BASE/api/security/groups/auto2-team-managers-group"

echo "=== DELETE USERS ==="
for u in manager-a dev1-a dev2-a manager-b dev1-b dev2-b; do
  del "$BASE/api/security/users/$u"
done

echo "=== DELETE REPOS ==="
del "$BASE/api/repositories/auto2-generic-dev-virtual"
del "$BASE/api/repositories/auto2-generic-dev-local"
del "$BASE/api/repositories/auto2-maven-dev-remote"

echo "ROLLBACK COMPLETE ✅"