#!/usr/bin/env bash
# Taro secrets manager (06 QA10, Phase 3 Sprint 3.4).
#
# Ported from quiz_apps/.secrets/secrets-manager.sh. One GPG-encrypted JSON
# bundle, .secrets/secrets.json.gpg (AES-256, symmetric), unlocked by one
# passphrase: the Gitea repository secret SECRETS_PASSPHRASE in CI, or a
# pinentry prompt locally. Only the .gpg file is ever committed.
#
# Differences from quiz_apps:
#   - lives in tools/, operates on <repo>/.secrets/ (override: SECRETS_DIR);
#   - `init` creates the first plaintext skeleton (quiz_apps' add-app could
#     not bootstrap an empty bundle);
#   - `decrypt-to <path>` writes the plaintext elsewhere (CI uses
#     $RUNNER_TEMP, never /tmp, 06 §8) with mode 600;
#   - `clean` removes the plaintext; jq paths are passed as arguments, never
#     spliced into the filter, so keys and values need no escaping;
#   - sections are `shared`, `taro` (app) and `worker`, not one per app.
#
# Usage: tools/secrets-manager.sh <command> [args]   (run with no args for help)

# jq filters are single-quoted on purpose: $s/$k/$v are jq variables bound
# with --arg, not shell expansions.
# shellcheck disable=SC2016

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SECRETS_DIR="${SECRETS_DIR:-$REPO_ROOT/.secrets}"
ENCRYPTED_FILE="$SECRETS_DIR/secrets.json.gpg"
DECRYPTED_FILE="$SECRETS_DIR/secrets.json"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Keys each section is expected to hold once the relevant phase lands.
# `validate` reports gaps; it never fails on them, because the bundle fills
# up phase by phase (Phase 6 Worker, Phase 10 stores, Phase 21 release).
SHARED_KEYS="apple_team_id apple_distribution_cert_base64 apple_distribution_cert_password app_store_connect_api_key_id app_store_connect_api_issuer_id app_store_connect_api_key_base64 google_play_service_account_base64"
TARO_KEYS="ios_bundle_id android_package_name ios_provisioning_profile_base64 android_keystore_base64 android_keystore_password android_key_alias android_key_password"
WORKER_KEYS="cloudflare_account_id cloudflare_api_token anthropic_api_key app_store_server_api_key_id app_store_server_api_issuer_id app_store_server_api_key_base64 play_service_account_base64"

die() {
  printf '%b\n' "${RED}Error: $*${NC}" >&2
  exit 1
}

need() {
  command -v "$1" >/dev/null 2>&1 || die "'$1' is required (brew install $2)"
}

print_usage() {
  cat <<EOF

Usage: $0 <command> [options]

Commands:
  init                          Create an empty plaintext skeleton (first run only)
  list                          List sections and their keys (never values)
  get <section> <key>           Print one value
  set <section> <key> <value>   Set a value in the plaintext file
  set-file <section> <key> <f>  Set a value from a file (base64 encoded)
  delete <section> <key>        Delete a key
  add-section <section>         Add an empty section
  delete-section <section>      Delete a section (asks for confirmation)
  decrypt                       Decrypt the bundle to .secrets/secrets.json
  decrypt-to <path>             Decrypt the bundle to <path> (mode 600), e.g. \$RUNNER_TEMP/secrets.json
  encrypt                       Encrypt .secrets/secrets.json and remove it
  clean                         Remove the plaintext .secrets/secrets.json
  validate                      Check JSON and report missing expected keys

Sections: shared, taro, worker. SECRETS_PASSPHRASE (env) avoids the prompt.
Files: $ENCRYPTED_FILE (committed), $DECRYPTED_FILE (never committed).

Examples:
  $0 init
  $0 set taro ios_bundle_id com.vshyrochuk.taro
  $0 set-file taro android_keystore_base64 ~/pet/secure/taro/upload.jks
  $0 encrypt
  SECRETS_PASSPHRASE=... $0 decrypt-to "\$RUNNER_TEMP/secrets.json"

EOF
}

gpg_decrypt() {
  # $1: output path
  local out=$1
  [ -f "$ENCRYPTED_FILE" ] || die "no bundle at $ENCRYPTED_FILE (run '$0 init', then 'encrypt')"
  need gpg gnupg
  (
    umask 077
    if [ -n "${SECRETS_PASSPHRASE:-}" ]; then
      printf '%s' "$SECRETS_PASSPHRASE" \
        | gpg --batch --yes --quiet --pinentry-mode loopback --passphrase-fd 0 \
              --output "$out" --decrypt "$ENCRYPTED_FILE"
    else
      gpg --yes --quiet --output "$out" --decrypt "$ENCRYPTED_FILE"
    fi
  )
  chmod 600 "$out"
}

decrypt_secrets() {
  # quiz_apps lost keys once: `set` writes only the plaintext, and a later
  # decrypt with --yes overwrote it. Refuse when the plaintext is newer.
  if [ -f "$DECRYPTED_FILE" ] && [ "$DECRYPTED_FILE" -nt "$ENCRYPTED_FILE" ] \
     && [ "${FORCE_DECRYPT:-}" != "1" ]; then
    printf '%b\n' "${RED}Refusing to decrypt: secrets.json is newer than secrets.json.gpg${NC}" >&2
    echo "" >&2
    echo "The plaintext has changes that were never encrypted; decrypting would lose them." >&2
    echo "  Keep them:     $0 encrypt" >&2
    echo "  Discard them:  FORCE_DECRYPT=1 $0 decrypt" >&2
    exit 1
  fi
  printf '%b\n' "${BLUE}Decrypting secrets...${NC}"
  gpg_decrypt "$DECRYPTED_FILE"
  printf '%b\n' "${GREEN}✓ Decrypted to $DECRYPTED_FILE (never commit it)${NC}"
}

decrypt_to() {
  local out=${1:-}
  [ -n "$out" ] || die "Usage: $0 decrypt-to <path>"
  case "$out" in
    /tmp/*|/private/tmp/*) die "refusing to write secrets under /tmp (06 §8); use \$RUNNER_TEMP" ;;
  esac
  gpg_decrypt "$out"
  echo "Decrypted to $out"
}

encrypt_secrets() {
  [ -f "$DECRYPTED_FILE" ] || die "$DECRYPTED_FILE not found"
  need jq jq
  need gpg gnupg
  jq empty "$DECRYPTED_FILE" 2>/dev/null || die "invalid JSON in $DECRYPTED_FILE"

  printf '%b\n' "${BLUE}Encrypting secrets...${NC}"
  if [ -n "${SECRETS_PASSPHRASE:-}" ]; then
    printf '%s' "$SECRETS_PASSPHRASE" \
      | gpg --batch --yes --quiet --pinentry-mode loopback --passphrase-fd 0 \
            --symmetric --cipher-algo AES256 --output "$ENCRYPTED_FILE" "$DECRYPTED_FILE"
  else
    gpg --yes --quiet --symmetric --cipher-algo AES256 --output "$ENCRYPTED_FILE" "$DECRYPTED_FILE"
  fi
  printf '%b\n' "${GREEN}✓ Encrypted to $ENCRYPTED_FILE${NC}"
  remove_plaintext "$DECRYPTED_FILE"
  printf '%b\n' "${GREEN}✓ Removed plaintext${NC}"
}

remove_plaintext() {
  # macOS has no shred; `rm -P` overwrites before unlinking there.
  local f=$1
  [ -f "$f" ] || return 0
  if command -v shred >/dev/null 2>&1; then
    shred -u "$f"
  else
    rm -P "$f" 2>/dev/null || rm -f "$f"
  fi
}

ensure_decrypted() {
  need jq jq
  if [ ! -f "$DECRYPTED_FILE" ]; then
    [ -f "$ENCRYPTED_FILE" ] || die "no secrets yet; run '$0 init' first"
    decrypt_secrets
  fi
}

require_section() {
  jq -e --arg s "$1" 'has($s)' "$DECRYPTED_FILE" >/dev/null \
    || die "section '$1' not found (sections: shared, taro, worker; or '$0 add-section $1')"
}

write_json() {
  # $@: jq args; replaces the plaintext atomically, keeping mode 600.
  local tmp
  tmp=$(mktemp "$SECRETS_DIR/.secrets.XXXXXX")
  chmod 600 "$tmp"
  if jq "$@" "$DECRYPTED_FILE" > "$tmp"; then
    mv "$tmp" "$DECRYPTED_FILE"
  else
    rm -f "$tmp"
    die "jq failed; $DECRYPTED_FILE unchanged"
  fi
}

remind_encrypt() {
  echo ""
  printf '%b\n' "${YELLOW}Don't forget to run: $0 encrypt${NC}"
}

cmd_init() {
  need jq jq
  [ -f "$ENCRYPTED_FILE" ] && die "$ENCRYPTED_FILE already exists; use '$0 decrypt'"
  [ -f "$DECRYPTED_FILE" ] && die "$DECRYPTED_FILE already exists; run '$0 encrypt'"
  mkdir -p "$SECRETS_DIR"
  (
    umask 077
    jq -n \
      --arg shared "$SHARED_KEYS" --arg taro "$TARO_KEYS" --arg worker "$WORKER_KEYS" '
      def section($keys): $keys | split(" ") | map({(.): ""}) | add;
      {shared: section($shared), taro: section($taro), worker: section($worker)}
      | .taro.android_key_alias = "upload"' > "$DECRYPTED_FILE"
  )
  printf '%b\n' "${GREEN}✓ Created $DECRYPTED_FILE with empty sections shared, taro, worker${NC}"
  remind_encrypt
}

cmd_list() {
  ensure_decrypted
  echo ""
  printf '%b\n' "${BLUE}=== Sections ===${NC}"
  jq -r 'keys[]' "$DECRYPTED_FILE"
  echo ""
  printf '%b\n' "${BLUE}=== Keys per section ===${NC}"
  local section
  for section in $(jq -r 'keys[]' "$DECRYPTED_FILE"); do
    printf '%b\n' "${YELLOW}$section:${NC}"
    jq -r --arg s "$section" '.[$s] | keys[] | "  - " + .' "$DECRYPTED_FILE"
  done
}

cmd_get() {
  local section=${1:-} key=${2:-}
  [ -n "$section" ] && [ -n "$key" ] || die "Usage: $0 get <section> <key>"
  ensure_decrypted
  local value
  value=$(jq -r --arg s "$section" --arg k "$key" '.[$s][$k] // empty' "$DECRYPTED_FILE")
  [ -n "$value" ] || die "key '$key' not found in section '$section'"
  printf '%s\n' "$value"
}

cmd_set() {
  local section=${1:-} key=${2:-} value=${3:-}
  [ -n "$section" ] && [ -n "$key" ] && [ -n "$value" ] || die "Usage: $0 set <section> <key> <value>"
  ensure_decrypted
  require_section "$section"
  write_json --arg s "$section" --arg k "$key" --arg v "$value" '.[$s][$k] = $v'
  printf '%b\n' "${GREEN}✓ Set $section.$key${NC}"
  remind_encrypt
}

cmd_set_file() {
  local section=${1:-} key=${2:-} file=${3:-}
  [ -n "$section" ] && [ -n "$key" ] && [ -n "$file" ] || die "Usage: $0 set-file <section> <key> <file>"
  [ -f "$file" ] || die "file not found: $file"
  ensure_decrypted
  require_section "$section"
  local value
  value=$(base64 < "$file" | tr -d '\n')
  write_json --arg s "$section" --arg k "$key" --arg v "$value" '.[$s][$k] = $v'
  printf '%b\n' "${GREEN}✓ Set $section.$key from $file (base64)${NC}"
  remind_encrypt
}

cmd_delete() {
  local section=${1:-} key=${2:-}
  [ -n "$section" ] && [ -n "$key" ] || die "Usage: $0 delete <section> <key>"
  ensure_decrypted
  jq -e --arg s "$section" --arg k "$key" '.[$s] | has($k)' "$DECRYPTED_FILE" >/dev/null 2>&1 \
    || die "key '$key' not found in section '$section'"
  write_json --arg s "$section" --arg k "$key" 'del(.[$s][$k])'
  printf '%b\n' "${GREEN}✓ Deleted $section.$key${NC}"
  remind_encrypt
}

cmd_add_section() {
  local section=${1:-}
  [ -n "$section" ] || die "Usage: $0 add-section <section>"
  ensure_decrypted
  if jq -e --arg s "$section" 'has($s)' "$DECRYPTED_FILE" >/dev/null; then
    die "section '$section' already exists"
  fi
  write_json --arg s "$section" '.[$s] = {}'
  printf '%b\n' "${GREEN}✓ Added section '$section'${NC}"
  remind_encrypt
}

cmd_delete_section() {
  local section=${1:-}
  [ -n "$section" ] || die "Usage: $0 delete-section <section>"
  [ "$section" != "shared" ] || die "cannot delete 'shared' (global credentials)"
  ensure_decrypted
  require_section "$section"
  printf '%b\n' "${YELLOW}Delete section '$section' and every key in it? [y/N]${NC}"
  local confirm
  read -r confirm
  if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
    echo "Cancelled"
    exit 0
  fi
  write_json --arg s "$section" 'del(.[$s])'
  printf '%b\n' "${GREEN}✓ Deleted section '$section'${NC}"
  remind_encrypt
}

check_keys() {
  # $1: section, $2: space-separated keys; prints status, returns gap count.
  local section=$1 keys=$2 key value gaps=0
  printf '%b\n' "${YELLOW}$section:${NC}"
  for key in $keys; do
    value=$(jq -r --arg s "$section" --arg k "$key" '.[$s][$k] // empty' "$DECRYPTED_FILE")
    if [ -n "$value" ]; then
      printf '%b\n' "  ${GREEN}✓${NC} $key"
    else
      printf '%b\n' "  ${RED}✗${NC} $key (empty or missing)"
      gaps=$((gaps + 1))
    fi
  done
  return "$gaps"
}

cmd_validate() {
  ensure_decrypted
  printf '%b\n' "${BLUE}Validating $DECRYPTED_FILE...${NC}"
  if [ "$DECRYPTED_FILE" -nt "$ENCRYPTED_FILE" ]; then
    printf '%b\n' "${YELLOW}! secrets.json is newer than the bundle; run '$0 encrypt'.${NC}"
  fi
  jq empty "$DECRYPTED_FILE" 2>/dev/null || die "invalid JSON"
  printf '%b\n' "${GREEN}✓ Valid JSON${NC}"
  echo ""
  local total=0 gaps
  gaps=0; check_keys shared "$SHARED_KEYS" || gaps=$?; total=$((total + gaps))
  gaps=0; check_keys taro "$TARO_KEYS" || gaps=$?; total=$((total + gaps))
  gaps=0; check_keys worker "$WORKER_KEYS" || gaps=$?; total=$((total + gaps))
  echo ""
  echo "$total expected keys are still empty (filled phase by phase; not an error)."
}

main() {
  local cmd=${1:-}
  [ $# -gt 0 ] && shift
  case "$cmd" in
    init) cmd_init ;;
    list) cmd_list ;;
    get) cmd_get "$@" ;;
    set) cmd_set "$@" ;;
    set-file) cmd_set_file "$@" ;;
    delete) cmd_delete "$@" ;;
    add-section) cmd_add_section "$@" ;;
    delete-section) cmd_delete_section "$@" ;;
    decrypt) decrypt_secrets ;;
    decrypt-to) decrypt_to "$@" ;;
    encrypt) encrypt_secrets ;;
    clean) remove_plaintext "$DECRYPTED_FILE"; echo "Removed $DECRYPTED_FILE (if it existed)" ;;
    validate) cmd_validate ;;
    -h|--help|help) print_usage ;;
    *) print_usage; exit 1 ;;
  esac
}

main "$@"
