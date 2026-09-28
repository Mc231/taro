#!/usr/bin/env bash
# One-off: create the SonarQube project `taro`, the advisory quality gate `Taro`
# (06 §9, RC88) and a project analysis token, then store SONAR_TOKEN and
# SONAR_HOST_URL as Gitea Actions secrets on the taro mirror.
#
# Reuses the admin credentials kept in the quiz_apps secrets bundle
# (shared.sonar_token, shared.sonar_host_url, shared.gitea_token). Never prints
# a secret value. Safe to re-run: existing project / gate / conditions are kept.
#
# Usage: SECRETS_PASSPHRASE=$QUIZ_SECRETS bash tools/ci/setup_sonar.sh [gitea_owner]
set -euo pipefail

owner="${1:-Volodya}"
qa_secrets="$HOME/pet/quiz_apps/.secrets"
: "${SECRETS_PASSPHRASE:?set SECRETS_PASSPHRASE (e.g. SECRETS_PASSPHRASE=\$QUIZ_SECRETS)}"

get() { (cd "$qa_secrets" && ./secrets-manager.sh get shared "$1" 2>/dev/null | tail -n 1); }
admin_token=$(get sonar_token)
host=$(get sonar_host_url)
gitea_token=$(get gitea_token)
[ -n "$admin_token" ] && [ -n "$host" ] || { echo "error: sonar credentials not found in quiz_apps bundle" >&2; exit 1; }
host="${host%/}"
echo "SonarQube: $host"

sq() { curl -sS -u "$admin_token:" "$@"; } # gitleaks:allow (shell variable, not a literal secret)
# POST and report: prints "ok" or the SonarQube error messages (never the token).
sq_post() {
  out=$(sq -X POST "$@")
  if printf '%s' "$out" | grep -q '"errors"'; then
    printf '%s' "$out" | python3 -c 'import json,sys; print("; ".join(e.get("msg","") for e in json.load(sys.stdin).get("errors",[])))'
    return 1
  fi
  echo ok
}
echo "SonarQube version: $(sq "$host/api/server/version")"

if sq "$host/api/projects/search?projects=taro" | grep -q '"key":"taro"'; then
  echo "project taro: exists"
else
  echo "project taro: create -> $(sq_post "$host/api/projects/create" -d name=Taro -d project=taro -d mainBranch=main || true)"
fi

if sq "$host/api/qualitygates/show?name=Taro" | grep -q '"name":"Taro"'; then
  echo "quality gate Taro: exists"
else
  echo "quality gate Taro: create -> $(sq_post "$host/api/qualitygates/create" -d name=Taro || true)"
fi

existing=$(sq "$host/api/qualitygates/show?name=Taro")
add_condition() { # metric op error
  if printf '%s' "$existing" | grep -q "\"metric\":\"$1\""; then
    echo "  condition $1: exists"
    return
  fi
  echo "  condition $1 $2 $3 -> $(sq_post "$host/api/qualitygates/create_condition" \
      -d gateName=Taro -d metric="$1" -d op="$2" -d error="$3" || true)"
}
add_condition new_coverage LT 90
add_condition coverage LT 90
add_condition new_duplicated_lines_density GT 3
add_condition new_bugs GT 0
add_condition new_vulnerabilities GT 0
add_condition new_security_hotspots_reviewed LT 100
add_condition new_maintainability_rating GT 1

echo "assign gate Taro to taro -> $(sq_post "$host/api/qualitygates/select" -d gateName=Taro -d projectKey=taro || true)"

if [ "${SKIP_TOKEN:-0}" = "1" ]; then
  echo "SKIP_TOKEN=1: token and Gitea secrets left as they are"
  exit 0
fi
token_name="taro-ci-$(date +%Y%m%d%H%M%S)"
project_token=$(sq -X POST "$host/api/user_tokens/generate" \
  -d name="$token_name" -d type=PROJECT_ANALYSIS_TOKEN -d projectKey=taro |
  python3 -c 'import json,sys; print(json.load(sys.stdin).get("token",""))')
[ -n "$project_token" ] || { echo "error: could not generate a project analysis token" >&2; exit 1; }
echo "project analysis token $token_name: generated"

# Keep a local copy for the taro secrets bundle (Phase 3 Sprint 3.4).
mkdir -p "$HOME/pet/secure/taro"
umask 077
printf '%s\n' "$project_token" > "$HOME/pet/secure/taro/sonar_token"
printf '%s\n' "$host" > "$HOME/pet/secure/taro/sonar_host_url"
echo "saved to ~/pet/secure/taro/{sonar_token,sonar_host_url} (mode 600)"

if [ -z "$gitea_token" ]; then
  echo "warning: no gitea_token in quiz_apps bundle; add SONAR_TOKEN / SONAR_HOST_URL in the Gitea UI"
  exit 0
fi
code=$(curl -s -o /dev/null -w '%{http_code}' -H "Authorization: token $gitea_token" \
  "http://localhost:3001/api/v1/repos/$owner/taro")
if [ "$code" != "200" ]; then
  echo "Gitea repo $owner/taro not found (HTTP $code). Create the mirror first (docs/phase3_notes/CI.md step 1), then re-run."
  exit 0
fi
put_secret() {
  body=$(python3 -c 'import json,sys; print(json.dumps({"data": sys.argv[1]}))' "$2")
  status=$(curl -s -o /dev/null -w '%{http_code}' -X PUT \
    -H "Authorization: token $gitea_token" -H 'Content-Type: application/json' \
    -d "$body" "http://localhost:3001/api/v1/repos/$owner/taro/actions/secrets/$1")
  echo "Gitea secret $1: HTTP $status"
}
put_secret SONAR_TOKEN "$project_token"
put_secret SONAR_HOST_URL "$host"
echo "done"
