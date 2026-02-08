---
name: github-branch-policy
description: Audit GitHub repository branch governance and workflow hygiene. Use when asked to review rulesets, required status checks, update restrictions, delete-on-merge settings, auto-merge workflow reliability, stale branches, ghost workflow registrations, or branch-policy drift.
---

# GitHub Branch Policy

## Overview

Run a repeatable audit for GitHub branch-policy safety and Actions workflow hygiene. Check enforcement rules, workflow registration integrity, and branch cleanup risks that commonly break CI and auto-merge.

## Use This Skill When

Apply this skill for requests like:
- "Audit branch protection/rulesets on this repo."
- "Check whether auto-merge and branch cleanup are configured correctly."
- "Find ghost workflows or stale branches causing Action failures."
- "Make sure branch policy matches solo-developer expectations."

## Prerequisites

- `gh` authenticated with admin-level access to the repository.
- `jq` available for JSON filtering.
- Target repository known as `OWNER/REPO`, or current directory is a checked-out repo with a GitHub remote.

## Quick Setup

Set reusable shell variables before running checks:

```bash
OWNER_REPO="${OWNER_REPO:-$(gh repo view --json nameWithOwner -q .nameWithOwner)}"
OWNER="${OWNER_REPO%/*}"
REPO="${OWNER_REPO#*/}"
DEFAULT_BRANCH="$(gh repo view "$OWNER_REPO" --json defaultBranchRef -q .defaultBranchRef.name)"
echo "Auditing $OWNER_REPO (default: $DEFAULT_BRANCH)"
```

## Audit Checklist

### 1. Active ruleset on default branch with `update` + `required_status_checks`

Verification:
```bash
gh api "repos/$OWNER/$REPO/rulesets" \
  --jq '.[] | {id,name,enforcement,target,include:(.conditions.ref_name.include // []),rules:[.rules[].type]}'
```

Pass criteria:
- At least one active branch ruleset applies to the default branch.
- That ruleset includes both `update` and `required_status_checks`.

Remediation:
- Create or enable a repository ruleset for the default branch.
- Add missing `update` and `required_status_checks` rules.

### 2. Solo-dev setting: `require_code_owner_review` is `false`

Verification:
```bash
gh api "repos/$OWNER/$REPO/rulesets" \
  --jq '.[] | {name, pull_request_rules:[.rules[] | select(.type=="pull_request") | .parameters.require_code_owner_review]}'
```

Pass criteria:
- For solo-maintainer repos, pull-request rules do not enforce CODEOWNERS review.

Remediation:
- Set `require_code_owner_review: false` in the pull-request rule where solo-dev flow is required.

### 3. `delete_branch_on_merge` is enabled

Verification:
```bash
gh api "repos/$OWNER/$REPO" --jq '{delete_branch_on_merge}'
```

Pass criteria:
- `delete_branch_on_merge` is `true`.

Remediation:
- Enable delete-on-merge in repository settings.

### 4. Closed-branch cleanup workflow exists

Verification:
```bash
gh api "repos/$OWNER/$REPO/actions/workflows" \
  --jq '.workflows[] | {id,name,path,state}'
```

Pass criteria:
- A workflow exists for post-PR cleanup of closed/merged branches.
- Workflow is active (not disabled).

Remediation:
- Add a cleanup workflow in `.github/workflows/` and ensure it runs on appropriate PR/branch events.

### 5. Auto-merge workflow exists and triggers on `pull_request`

Verification:
```bash
gh api "repos/$OWNER/$REPO/actions/workflows" \
  --jq '.workflows[] | {id,name,path,state}'
```

Inspect workflow YAML (replace filename):
```bash
AUTO_MERGE_FILE="auto-merge.yml"
gh api "repos/$OWNER/$REPO/contents/.github/workflows/$AUTO_MERGE_FILE?ref=$DEFAULT_BRANCH" \
  --jq '.content' | base64 --decode | sed -n '1,220p'
```

Check recent runs:
```bash
gh run list --workflow "$AUTO_MERGE_FILE" --limit 20 \
  --json databaseId,status,conclusion,event,headBranch,createdAt
```

Pass criteria:
- Auto-merge workflow exists on default branch.
- Trigger includes `pull_request` (or intentionally documented alternative).
- Recent runs show `pull_request` events and actual jobs executed.

Remediation:
- Add/fix `on: pull_request` trigger.
- Ensure workflow file path and name are stable across active branches.

### 6. No stale branches from merged/closed PRs

Verification:
```bash
gh api "repos/$OWNER/$REPO/branches" --paginate --jq '.[].name' | sort -u > /tmp/live-branches.txt
gh pr list --state merged --limit 500 --json headRefName --jq '.[].headRefName' | sort -u > /tmp/merged-pr-branches.txt
gh pr list --state closed --limit 500 --json headRefName,mergedAt \
  --jq '.[] | select(.mergedAt==null) | .headRefName' | sort -u > /tmp/closed-pr-branches.txt
cat /tmp/merged-pr-branches.txt /tmp/closed-pr-branches.txt | sort -u > /tmp/candidate-stale-branches.txt
comm -12 /tmp/live-branches.txt /tmp/candidate-stale-branches.txt
```

Pass criteria:
- Intersection output is empty, excluding intentional long-lived branches.

Remediation:
- Delete confirmed stale branches:
```bash
git push origin --delete "<branch>"
```

### 7. No ghost workflow registrations

Verification:
```bash
gh api "repos/$OWNER/$REPO/actions/workflows" \
  --jq '.workflows[] | [.id,.name,.path,.state] | @tsv' | sort
gh api "repos/$OWNER/$REPO/actions/workflows" --jq '.workflows[].name' | sort | uniq -cd
```

Pass criteria:
- Exactly one workflow registration exists per logical workflow.

Remediation:
- Disable duplicate registrations:
```bash
gh api -X PUT "repos/$OWNER/$REPO/actions/workflows/<workflow_id>/disable"
```
- Remove stale branches with legacy workflow filenames that keep duplicate registrations alive.

### 8. Auto-merge workflow filename is consistent across active branches

Verification:
```bash
for BRANCH in $(gh api "repos/$OWNER/$REPO/branches" --paginate --jq '.[].name'); do
  echo "## $BRANCH"
  gh api "repos/$OWNER/$REPO/contents/.github/workflows?ref=$BRANCH" --jq '.[].name' 2>/dev/null | sort
done
```

Pass criteria:
- Active branches use the same filename for the auto-merge workflow.

Remediation:
- Standardize filename on default branch and port change to long-lived branches.
- Delete stale branches that still carry deprecated workflow filenames.

### 9. Prefer rulesets over redundant legacy branch protection

Verification:
```bash
gh api "repos/$OWNER/$REPO/rulesets" --jq 'length'
gh api "repos/$OWNER/$REPO/branches/$DEFAULT_BRANCH/protection" 2>/dev/null | jq '.'
```

Pass criteria:
- Rulesets are the primary policy mechanism.
- Legacy branch protection is absent or intentionally non-overlapping.

Remediation:
- Consolidate policy into rulesets.
- Remove redundant legacy protection after parity is confirmed.

## Report Format

Return results in this format:

```markdown
## Branch Policy Audit Report
- Repository: OWNER/REPO
- Default branch: <branch>
- Timestamp (UTC): <iso8601>
- Overall status: PASS | NEEDS_ACTION | BLOCKED

### Findings
1. [SEV-<1-3>] <check name> - <pass/fail summary>
   Evidence: <key command output summary>
   Remediation: <next action>

### Actions Taken
1. <action performed or "none">

### Follow-up
1. <required human decision or "none">
```

## Guardrails

- Do not delete branches until they are confirmed stale and unprotected.
- Do not disable workflows blindly; verify which registration is canonical first.
- Prefer deterministic evidence from `gh api` output over assumptions.
- If access is insufficient, report exact missing permissions and continue with remaining checks.
