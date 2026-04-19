#!/usr/bin/env bash
set -euo pipefail

### CONFIG ###
BASE="https://interviewkobil.jfrog.io/artifactory"
USER="kobster2000@gmail.com"
PASS="Password@123"

auth=(-u "${USER}:${PASS}")
json=(-H "Content-Type: application/json")

log() { echo -e "\n=== $1 ==="; }

exists() {
  curl -s -o /dev/null -w "%{http_code}" "${auth[@]}" "$1" | grep -q "200"
}

put() {
  url="$1"; data="$2"
  echo "--> PUT $url"
  curl -sS "${auth[@]}" -X PUT "$url" "${json[@]}" -d "$data"
}

# =========================
log "STEP 1: Repositories (ordered)"

if ! exists "$BASE/api/repositories/auto2-maven-dev-remote"; then
  put "$BASE/api/repositories/auto2-maven-dev-remote" '{
    "rclass":"remote","packageType":"maven",
    "url":"https://repo1.maven.org/maven2"
  }'
else echo "Maven remote exists"; fi

if ! exists "$BASE/api/repositories/auto2-generic-dev-local"; then
  put "$BASE/api/repositories/auto2-generic-dev-local" '{
    "rclass":"local","packageType":"generic"
  }'
else echo "Generic local exists"; fi

if ! exists "$BASE/api/repositories/auto2-generic-dev-virtual"; then
  put "$BASE/api/repositories/auto2-generic-dev-virtual" '{
    "rclass":"virtual","packageType":"generic",
    "repositories":["auto2-generic-dev-local"],
    "defaultDeploymentRepo":"auto2-generic-dev-local"
  }'
else echo "Virtual repo exists"; fi

# =========================
log "STEP 2: Users"

USERS=(
  "manager-a:ManagerA2026!"
  "dev1-a:Dev1A2026!"
  "dev2-a:Dev2A2026!"
  "manager-b:ManagerB2026!"
  "dev1-b:Dev1B2026!"
  "dev2-b:Dev2B2026!"
)

for u in "${USERS[@]}"; do
  name="${u%%:*}"
  pass="${u##*:}"

  if exists "$BASE/api/security/users/$name"; then
    echo "User $name exists"
  else
    put "$BASE/api/security/users/$name" "{
      \"email\":\"$name@auto2.com\",
      \"password\":\"$pass\",
      \"admin\":false
    }"
  fi
done

# =========================
log "STEP 3: Groups (with users)"

put "$BASE/api/security/groups/auto2-team-a-group" '{
  "name":"auto2-team-a-group",
  "usersNames":["dev1-a","dev2-a"]
}'

put "$BASE/api/security/groups/auto2-team-b-group" '{
  "name":"auto2-team-b-group",
  "usersNames":["dev1-b","dev2-b"]
}'

put "$BASE/api/security/groups/auto2-team-managers-group" '{
  "name":"auto2-team-managers-group",
  "usersNames":["manager-a","manager-b"]
}'

# =========================
log "STEP 4: Permissions"

put "$BASE/api/v2/security/permissions/auto2-maven-read" '{
  "name":"auto2-maven-read",
  "repo":{
    "repositories":["auto2-maven-dev-remote"],
    "actions":{
      "groups":{
        "auto2-team-a-group":["read"],
        "auto2-team-b-group":["read"],
        "auto2-team-managers-group":["read"]
      }
    }
  }
}'

put "$BASE/api/v2/security/permissions/auto2-generic-team-a" '{
  "name":"auto2-generic-team-a",
  "repo":{
    "repositories":["auto2-generic-dev-local"],
    "include-patterns":["team-a/**","shared/**"],
    "actions":{
      "groups":{
        "auto2-team-a-group":["read","write"],
        "auto2-team-managers-group":["read","write","delete","manage"]
      }
    }
  }
}'

put "$BASE/api/v2/security/permissions/auto2-generic-team-b" '{
  "name":"auto2-generic-team-b",
  "repo":{
    "repositories":["auto2-generic-dev-local"],
    "include-patterns":["team-b/**","shared/**"],
    "actions":{
      "groups":{
        "auto2-team-b-group":["read","write"],
        "auto2-team-managers-group":["read","write","delete","manage"]
      }
    }
  }
}'

# =========================
log "STEP 5: Validation Artifacts"

TMP="/tmp/auto2.txt"
echo "auto2-init-file" > "$TMP"

upload_if_missing() {
  url="$1"
  if curl -s -I "${auth[@]}" "$url" | grep -q "200"; then
    echo "Exists: $url"
  else
    echo "Uploading: $url"
    curl -sS "${auth[@]}" -T "$TMP" "$url"
  fi
}

upload_if_missing "$BASE/auto2-generic-dev-virtual/team-a/init.txt"
upload_if_missing "$BASE/auto2-generic-dev-virtual/shared/config.txt"

log "ROLLOUT COMPLETE ✅"