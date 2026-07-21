#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
LOCK_FILE="$ROOT_DIR/upstream-sources.lock.json"

fail() {
  echo "error: $*" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || fail "required command not found: $1"
}

stable_hash() {
  local root=$1
  local excluded=${2:-}

  find "$root" -type f ${excluded:+! -path "$root/$excluded/*"} -print \
    | sed "s|^$root/||" \
    | LC_ALL=C sort \
    | while IFS= read -r relative_path; do
        printf '%s  %s\n' \
          "$(shasum -a 256 "$root/$relative_path" | awk '{print $1}')" \
          "$relative_path"
      done \
    | shasum -a 256 \
    | awk '{print $1}'
}

assert_inventory() {
  local import_id=$1
  local destination=$2
  local excluded expected actual

  excluded=$(jq -r --arg id "$import_id" '.imports[] | select(.id == $id) | .exclude[0] // empty' "$LOCK_FILE")
  expected=$(jq -r --arg id "$import_id" '.imports[] | select(.id == $id) | .inventory[]' "$LOCK_FILE")
  actual=$(find "$destination" -mindepth 1 -maxdepth 1 -type d ${excluded:+! -name "$excluded"} -exec basename {} \; | LC_ALL=C sort)
  [[ "$actual" == "$expected" ]] || fail "$import_id inventory differs from the lock file"
}

assert_hash() {
  local import_id=$1
  local destination=$2
  local excluded expected actual

  excluded=$(jq -r --arg id "$import_id" '.imports[] | select(.id == $id) | .exclude[0] // empty' "$LOCK_FILE")
  expected=$(jq -r --arg id "$import_id" '.imports[] | select(.id == $id) | .aggregateSha256' "$LOCK_FILE")
  actual=$(stable_hash "$destination" "$excluded")
  [[ "$actual" == "$expected" ]] || fail "$import_id content differs from the lock file (expected $expected, got $actual)"
}

assert_prompt_inventory() {
  local destination=$1
  local expected actual

  expected=$(jq -r '.imports[] | select(.id == "dynatrace-for-ai-prompts") | .files[].destination' "$LOCK_FILE")
  actual=$(find "$destination" -maxdepth 1 -type f -name '*.prompt.md' -exec basename {} \; | LC_ALL=C sort)
  [[ "$actual" == "$expected" ]] || fail "prompt inventory differs from the lock file"
}

assert_link() {
  local link=$1
  local expected_target=$2

  [[ -L "$link" ]] || fail "missing compatibility symlink: ${link#$ROOT_DIR/}"
  [[ $(readlink "$link") == "$expected_target" ]] \
    || fail "incorrect target for ${link#$ROOT_DIR/}: $(readlink "$link")"
  [[ -e "$link" ]] || fail "broken compatibility symlink: ${link#$ROOT_DIR/}"
}

assert_prompt_contracts() {
  local contracts expected_count actual_count field prompt prompt_name
  contracts="$ROOT_DIR/$(jq -r '.promptContracts' "$LOCK_FILE")"
  [[ -f "$contracts" ]] || fail "prompt contract registry is missing: ${contracts#$ROOT_DIR/}"

  expected_count=$(jq '[.imports[] | select(.id == "dynatrace-for-ai-prompts") | .files[]] | length' "$LOCK_FILE")
  actual_count=$(grep -c '^## /' "$contracts")
  [[ $actual_count -eq $expected_count ]] || fail "prompt contract registry contains missing or orphan entries"

  while IFS= read -r prompt; do
    prompt_name=${prompt%.prompt.md}
    [[ $(grep -c -F "## /$prompt_name" "$contracts") -eq 1 ]] \
      || fail "expected exactly one contract for /$prompt_name"
  done < <(jq -r '.imports[] | select(.id == "dynatrace-for-ai-prompts") | .files[].destination' "$LOCK_FILE")

  for field in Input Start Skills Capabilities Scope Stop Output; do
    [[ $(grep -c "^\\*\\*$field:\*\\*" "$contracts") -eq $expected_count ]] \
      || fail "prompt contracts must define $field for every prompt"
  done

  if grep -Eq 'Data Analysis Agent|Root Cause Agent|root_cause_agent|#tool:' "$contracts"; then
    fail "prompt contracts contain a client-specific agent or tool alias"
  fi
}

import_value() {
  local import_id=$1
  local field=$2

  jq -er --arg id "$import_id" --arg field "$field" \
    '.imports[] | select(.id == $id) | .[$field]' "$LOCK_FILE"
}

fetch_import() {
  local import_id=$1
  local checkout=$2
  local repository commit

  repository=$(import_value "$import_id" repository)
  commit=$(import_value "$import_id" commit)
  [[ $commit =~ ^[0-9a-f]{40}$ ]] || fail "$import_id must be pinned to a full commit SHA"

  git init -q "$checkout"
  git -C "$checkout" remote add origin "$repository"
  git -C "$checkout" fetch -q --depth 1 origin "$commit"
  git -C "$checkout" checkout -q --detach FETCH_HEAD
  [[ $(git -C "$checkout" rev-parse HEAD) == "$commit" ]] \
    || fail "$import_id fetched a different commit than requested"
}

sync_locked() {
  local refresh_lock=${1:-false}
  local original_lock=$LOCK_FILE
  local work_dir candidate backup candidate_lock skills_checkout prompts_checkout dtctl_checkout
  local prompt_source prompt_destination expected actual
  work_dir=$(mktemp -d)
  candidate="$work_dir/candidate"
  backup="$work_dir/backup"
  skills_checkout="$work_dir/dynatrace-skills"
  prompts_checkout="$work_dir/dynatrace-prompts"
  dtctl_checkout="$work_dir/dtctl"
  trap 'rm -rf "$work_dir"' RETURN

  candidate_lock="$work_dir/upstream-sources.lock.json"
  mkdir -p "$candidate/.agents/skills" "$candidate/.github/prompts" \
    "$candidate/.claude/skills" "$candidate/.claude/commands"
  fetch_import "dynatrace-for-ai-skills" "$skills_checkout"
  fetch_import "dynatrace-for-ai-prompts" "$prompts_checkout"
  fetch_import "dtctl-skill" "$dtctl_checkout"

  cp -R "$skills_checkout/$(import_value "dynatrace-for-ai-skills" source)/." \
    "$candidate/.agents/skills/"

  while IFS=$'\t' read -r prompt_source prompt_destination; do
    cp "$prompts_checkout/$(import_value "dynatrace-for-ai-prompts" source)/$prompt_source" \
      "$candidate/.github/prompts/$prompt_destination"
  done < <(jq -r '.imports[] | select(.id == "dynatrace-for-ai-prompts") | .files[] | [.source, .destination] | @tsv' "$LOCK_FILE")

  cp -R "$dtctl_checkout/$(import_value "dtctl-skill" source)" "$candidate/.agents/skills/dtctl"
  patch -d "$candidate/.agents/skills" -p1 --forward --batch \
    < "$ROOT_DIR/$(import_value "dtctl-skill" patch)" >/dev/null

  actual=$(stable_hash "$candidate/.agents/skills" "dtctl")
  if [[ $refresh_lock == true ]]; then
    jq --arg skills_hash "$actual" \
      '(.imports[] | select(.id == "dynatrace-for-ai-skills") | .aggregateSha256) = $skills_hash' \
      "$original_lock" > "$candidate_lock"
    jq --argjson inventory "$(find "$candidate/.agents/skills" -mindepth 1 -maxdepth 1 -type d ! -name dtctl -exec basename {} \; | LC_ALL=C sort | jq -R . | jq -s .)" \
      '(.imports[] | select(.id == "dynatrace-for-ai-skills") | .inventory) = $inventory' \
      "$candidate_lock" > "$candidate_lock.tmp"
    mv "$candidate_lock.tmp" "$candidate_lock"
  else
    expected=$(import_value "dynatrace-for-ai-skills" aggregateSha256)
    [[ "$actual" == "$expected" ]] || fail "fetched skills do not match the locked hash"
    cp "$original_lock" "$candidate_lock"
  fi

  actual=$(stable_hash "$candidate/.github/prompts")
  if [[ $refresh_lock == true ]]; then
    jq --arg prompts_hash "$actual" \
      '(.imports[] | select(.id == "dynatrace-for-ai-prompts") | .aggregateSha256) = $prompts_hash' \
      "$candidate_lock" > "$candidate_lock.tmp"
    mv "$candidate_lock.tmp" "$candidate_lock"
  else
    expected=$(import_value "dynatrace-for-ai-prompts" aggregateSha256)
    [[ "$actual" == "$expected" ]] || fail "fetched prompts do not match the locked hash"
  fi

  actual=$(stable_hash "$candidate/.agents/skills/dtctl")
  if [[ $refresh_lock == true ]]; then
    jq --arg dtctl_hash "$actual" \
      '(.imports[] | select(.id == "dtctl-skill") | .aggregateSha256) = $dtctl_hash' \
      "$candidate_lock" > "$candidate_lock.tmp"
    mv "$candidate_lock.tmp" "$candidate_lock"
  else
    expected=$(import_value "dtctl-skill" aggregateSha256)
    [[ "$actual" == "$expected" ]] || fail "patched dtctl skill does not match the locked hash"
  fi

  LOCK_FILE=$candidate_lock
  while IFS= read -r skill; do
    ln -s "../../.agents/skills/$skill" "$candidate/.claude/skills/$skill"
  done < <(jq -r '.imports[] | select(.id == "dynatrace-for-ai-skills") | .inventory[]' "$LOCK_FILE")
  ln -s "../../.agents/skills/dtctl" "$candidate/.claude/skills/dtctl"
  while IFS= read -r prompt_destination; do
    ln -s "../../.github/prompts/$prompt_destination" \
      "$candidate/.claude/commands/${prompt_destination%.prompt.md}.md"
  done < <(jq -r '.imports[] | select(.id == "dynatrace-for-ai-prompts") | .files[].destination' "$LOCK_FILE")

  if diff -qr "$candidate/.agents/skills" "$ROOT_DIR/.agents/skills" >/dev/null \
    && diff -qr "$candidate/.github/prompts" "$ROOT_DIR/.github/prompts" >/dev/null \
    && diff -qr "$candidate/.claude/skills" "$ROOT_DIR/.claude/skills" >/dev/null \
    && diff -qr "$candidate/.claude/commands" "$ROOT_DIR/.claude/commands" >/dev/null \
    && cmp -s "$candidate_lock" "$original_lock"; then
    LOCK_FILE=$original_lock
    echo "Upstream imports already match the locked revisions"
    return
  fi

  echo "Import changes to be synchronized:"
  diff -qr "$ROOT_DIR/.agents/skills" "$candidate/.agents/skills" || true
  diff -qr "$ROOT_DIR/.github/prompts" "$candidate/.github/prompts" || true
  diff -qr "$ROOT_DIR/.claude/skills" "$candidate/.claude/skills" || true
  diff -qr "$ROOT_DIR/.claude/commands" "$candidate/.claude/commands" || true

  mkdir -p "$backup/.agents" "$backup/.github" "$backup/.claude"
  cp -R "$ROOT_DIR/.agents/skills" "$backup/.agents/skills"
  cp -R "$ROOT_DIR/.github/prompts" "$backup/.github/prompts"
  cp -RP "$ROOT_DIR/.claude/skills" "$backup/.claude/skills"
  cp -RP "$ROOT_DIR/.claude/commands" "$backup/.claude/commands"
  cp "$original_lock" "$backup/upstream-sources.lock.json"

  if ! {
    rm -rf "$ROOT_DIR/.agents/skills" "$ROOT_DIR/.github/prompts" \
      "$ROOT_DIR/.claude/skills" "$ROOT_DIR/.claude/commands"
    cp -R "$candidate/.agents/skills" "$ROOT_DIR/.agents/skills"
    cp -R "$candidate/.github/prompts" "$ROOT_DIR/.github/prompts"
    cp -RP "$candidate/.claude/skills" "$ROOT_DIR/.claude/skills"
    cp -RP "$candidate/.claude/commands" "$ROOT_DIR/.claude/commands"
    cp "$candidate_lock" "$original_lock"
    LOCK_FILE=$original_lock
    verify
  }; then
    rm -rf "$ROOT_DIR/.agents/skills" "$ROOT_DIR/.github/prompts" \
      "$ROOT_DIR/.claude/skills" "$ROOT_DIR/.claude/commands"
    cp -R "$backup/.agents/skills" "$ROOT_DIR/.agents/skills"
    cp -R "$backup/.github/prompts" "$ROOT_DIR/.github/prompts"
    cp -RP "$backup/.claude/skills" "$ROOT_DIR/.claude/skills"
    cp -RP "$backup/.claude/commands" "$ROOT_DIR/.claude/commands"
    cp "$backup/upstream-sources.lock.json" "$original_lock"
    LOCK_FILE=$original_lock
    fail "synchronization failed verification; original imports restored"
  fi

  echo "Synchronized imports to the immutable revisions in $LOCK_FILE"
}

verify() {
  local skills_destination="$ROOT_DIR/.agents/skills"
  local prompts_destination="$ROOT_DIR/.github/prompts"
  local skill prompt prompt_name

  assert_inventory "dynatrace-for-ai-skills" "$skills_destination"
  assert_hash "dynatrace-for-ai-skills" "$skills_destination"
  assert_prompt_inventory "$prompts_destination"
  assert_hash "dynatrace-for-ai-prompts" "$prompts_destination"
  [[ -f "$ROOT_DIR/$(jq -r '.imports[] | select(.id == "dtctl-skill") | .patch' "$LOCK_FILE")" ]] \
    || fail "dtctl-skill patch declared by the lock file is missing"
  assert_hash "dtctl-skill" "$ROOT_DIR/.agents/skills/dtctl"

  while IFS= read -r skill; do
    assert_link "$ROOT_DIR/.claude/skills/$skill" "../../.agents/skills/$skill"
  done < <(jq -r '.imports[] | select(.id == "dynatrace-for-ai-skills") | .inventory[]' "$LOCK_FILE")

  while IFS= read -r prompt; do
    prompt_name=${prompt%.prompt.md}
    assert_link "$ROOT_DIR/.claude/commands/$prompt_name.md" "../../.github/prompts/$prompt"
  done < <(jq -r '.imports[] | select(.id == "dynatrace-for-ai-prompts") | .files[].destination' "$LOCK_FILE")

  assert_link "$ROOT_DIR/.claude/skills/dtctl" "../../.agents/skills/dtctl"
  assert_prompt_contracts

  echo "Upstream imports and compatibility links match $LOCK_FILE"
}

require_command jq
require_command shasum

case ${1:-verify} in
  verify)
    verify
    ;;
  sync)
    require_command git
    require_command patch
    case ${2:-} in
      "") sync_locked false ;;
      --refresh-lock) sync_locked true ;;
      *) fail "usage: scripts/sync-upstream.sh sync [--refresh-lock]" ;;
    esac
    ;;
  *)
    fail "usage: scripts/sync-upstream.sh [verify|sync [--refresh-lock]]"
    ;;
esac