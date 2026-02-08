#!/usr/bin/env bash
set -euo pipefail

REPO_INPUT="${1:-${GITHUB_REPOSITORY:-}}"
EXPECTED_RULESET_NAME="main-branch-policy"
EXPECTED_STATUS_CONTEXT="required-checks"
STRICT_ADMIN_SETTINGS="${AUDIT_STRICT_ADMIN_SETTINGS:-0}"

if [[ -z "$REPO_INPUT" ]]; then
  REPO_INPUT="$(gh repo view --json nameWithOwner -q .nameWithOwner)"
fi

OWNER="${REPO_INPUT%/*}"
REPO="${REPO_INPUT#*/}"
FAIL=0

fail() {
  echo "ERROR: $1" >&2
  FAIL=1
}

pass() {
  echo "OK: $1"
}

warn() {
  echo "WARN: $1"
}

check_admin_bool() {
  local field="$1"
  local expected="$2"
  local label="$3"
  local value
  value="$(jq -r ".$field" <<<"$REPO_JSON")"

  if [[ "$STRICT_ADMIN_SETTINGS" == "1" ]]; then
    if [[ "$value" == "$expected" ]]; then
      pass "$label"
    else
      fail "$label (expected $expected, got $value)"
    fi
    return
  fi

  if [[ "$value" == "$expected" ]]; then
    pass "$label"
  else
    warn "$label could not be strictly verified in non-admin mode (got $value)"
  fi
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "ERROR: missing required command '$1'" >&2
    exit 1
  fi
}

require_cmd gh
require_cmd jq

REPO_JSON="$(gh api "repos/$OWNER/$REPO")"
RULESET_LIST_JSON="$(gh api "repos/$OWNER/$REPO/rulesets")"
WORKFLOW_JSON="$(gh api "repos/$OWNER/$REPO/actions/workflows")"
INTERACTION_JSON="$(gh api "repos/$OWNER/$REPO/interaction-limits" 2>/dev/null || true)"

check_admin_bool "delete_branch_on_merge" "true" "delete_branch_on_merge is enabled"
check_admin_bool "allow_auto_merge" "true" "auto-merge is enabled at repository level"

if [[ "$(jq -r '.has_issues' <<<"$REPO_JSON")" == "false" ]]; then
  pass "issues are disabled"
else
  fail "issues are enabled (expected disabled)"
fi

if [[ "$(jq -r '.has_projects' <<<"$REPO_JSON")" == "false" ]]; then
  pass "projects are disabled"
else
  fail "projects are enabled (expected disabled)"
fi

if [[ "$(jq -r '.has_wiki' <<<"$REPO_JSON")" == "false" ]]; then
  pass "wiki is disabled"
else
  fail "wiki is enabled (expected disabled)"
fi

if [[ "$(jq -r '.has_discussions // false' <<<"$REPO_JSON")" == "false" ]]; then
  pass "discussions are disabled"
else
  fail "discussions are enabled (expected disabled)"
fi

if [[ "$(jq -r '.private' <<<"$REPO_JSON")" == "false" ]]; then
  pass "repository visibility is public"
else
  fail "repository is not public"
fi

if [[ -n "$INTERACTION_JSON" ]]; then
  limit_value="$(jq -r '.limit // "none"' <<<"$INTERACTION_JSON")"
  if [[ "$limit_value" == "collaborators_only" ]]; then
    pass "interaction limits are restricted to collaborators_only"
  else
    if [[ "$STRICT_ADMIN_SETTINGS" == "1" ]]; then
      fail "interaction limits are not collaborators_only (got $limit_value)"
    else
      warn "interaction limits could not be strictly verified in non-admin mode (got $limit_value)"
    fi
  fi
else
  if [[ "$STRICT_ADMIN_SETTINGS" == "1" ]]; then
    fail "interaction limits are not configured"
  else
    warn "interaction limits could not be read in non-admin mode"
  fi
fi

RULESET_ID="$(jq -r --arg n "$EXPECTED_RULESET_NAME" '.[] | select(.name==$n and .target=="branch" and .enforcement=="active") | .id' <<<"$RULESET_LIST_JSON" | head -n 1)"
if [[ -z "$RULESET_ID" ]]; then
  fail "active branch ruleset '$EXPECTED_RULESET_NAME' not found"
else
  pass "found active ruleset '$EXPECTED_RULESET_NAME' (id=$RULESET_ID)"
fi

if [[ -n "$RULESET_ID" ]]; then
  RULESET_JSON="$(gh api "repos/$OWNER/$REPO/rulesets/$RULESET_ID")"

  for rule_type in required_status_checks pull_request; do
    if jq -e --arg t "$rule_type" '.rules[] | select(.type==$t)' <<<"$RULESET_JSON" >/dev/null; then
      pass "ruleset contains rule '$rule_type'"
    else
      fail "ruleset missing '$rule_type' rule"
    fi
  done

  if jq -e '.rules[] | select(.type=="update")' <<<"$RULESET_JSON" >/dev/null; then
    pass "ruleset includes optional 'update' rule"
  else
    warn "ruleset does not include 'update' rule (optional for PR-only flow)"
  fi

  if jq -e '.conditions.ref_name.include[] | select(. == "~DEFAULT_BRANCH")' <<<"$RULESET_JSON" >/dev/null; then
    pass "ruleset targets default branch"
  else
    fail "ruleset does not explicitly target default branch"
  fi

  if [[ "$(jq -r '[.rules[] | select(.type=="pull_request") | .parameters.require_code_owner_review][0]' <<<"$RULESET_JSON")" == "false" ]]; then
    pass "require_code_owner_review is false"
  else
    fail "require_code_owner_review is not false"
  fi

  if jq -e --arg c "$EXPECTED_STATUS_CONTEXT" '.rules[] | select(.type=="required_status_checks") | .parameters.required_status_checks[] | select(.context==$c)' <<<"$RULESET_JSON" >/dev/null; then
    pass "required status check context is configured ($EXPECTED_STATUS_CONTEXT)"
  else
    fail "required status check context '$EXPECTED_STATUS_CONTEXT' is missing"
  fi
fi

for workflow_name in "Required Checks" "Auto Merge" "Closed Branch Cleanup"; do
  count="$(jq -r --arg n "$workflow_name" '[.workflows[] | select(.name==$n)] | length' <<<"$WORKFLOW_JSON")"
  if [[ "$count" -ge 1 ]]; then
    pass "workflow '$workflow_name' exists"
  else
    fail "workflow '$workflow_name' is missing"
  fi
done

dup_count="$(jq -r '[.workflows[].name] | group_by(.) | map(select(length > 1)) | length' <<<"$WORKFLOW_JSON")"
if [[ "$dup_count" == "0" ]]; then
  pass "no duplicate workflow registrations detected"
else
  fail "duplicate workflow registrations detected ($dup_count duplicate name groups)"
fi

if [[ "$FAIL" -ne 0 ]]; then
  exit 1
fi

echo "Policy audit passed for $OWNER/$REPO"
