---
name: github-branch-policy
description: Audit GitHub repository branch governance and workflow hygiene. Use when asked to review rulesets, required status checks, update restrictions, delete-on-merge settings, auto-merge workflow reliability, stale branches, ghost workflow registrations, or branch-policy drift.
---

# GitHub Branch Policy

## Overview

Run a repeatable audit for GitHub branch policy safety and Actions workflow hygiene. Validate ruleset enforcement, required checks, workflow registration integrity, and branch cleanup behavior that commonly break CI and auto-merge.

## Use This Skill When

Apply this skill for requests like:
- "Audit branch protection/rulesets on this repo."
- "Check whether auto-merge and branch cleanup are configured correctly."
- "Find ghost workflows or stale branches causing Actions failures."
- "Why are we getting `Cannot update this protected ref`?"
- "Make sure branch policy matches solo-developer expectations."

## Prerequisites

- `gh` authenticated for the target repo (`repo` + `workflow` scopes).
- `jq` available.
- Target repository known as `OWNER/REPO`, or current directory is a checked-out repo with a GitHub remote.

## Quick Setup

```bash
OWNER_REPO="${OWNER_REPO:-$(gh repo view --json nameWithOwner -q .nameWithOwner)}"
OWNER="${OWNER_REPO%/*}"
REPO="${OWNER_REPO#*/}"
DEFAULT_BRANCH="$(gh repo view "$OWNER_REPO" --json defaultBranchRef -q .defaultBranchRef.name)"
echo "Auditing $OWNER_REPO (default: $DEFAULT_BRANCH)"
```

## Audit Checklist

### 1. Repository merge settings are compatible with policy

Verification:
```bash
gh api "repos/$OWNER/$REPO" \
  --jq '{allow_auto_merge,allow_squash_merge,allow_merge_commit,allow_rebase_merge,delete_branch_on_merge,default_branch}'
```

Pass criteria:
- `allow_auto_merge: true` when auto-merge is expected.
- Merge methods match branch rules (for example, squash-only policy -> squash enabled).
- `delete_branch_on_merge: true` unless intentionally disabled.

Remediation:
- Enable auto-merge at repo level.
- Align repo merge methods with ruleset `allowed_merge_methods`.
- Enable delete-on-merge, or document why not.

---

### 2. Active ruleset applies to default branch and enforces PR + required checks

Verification:
```bash
gh api "repos/$OWNER/$REPO/rulesets" \
  --jq '.[] | {id,name,enforcement,target,include:(.conditions.ref_name.include // []),rules:[.rules[].type]}'
gh api "repos/$OWNER/$REPO/rulesets" \
  --jq '.[] | select(.enforcement=="active") | .rules[] | select(.type=="pull_request" or .type=="required_status_checks")'
```

Pass criteria:
- At least one active branch ruleset applies to `~DEFAULT_BRANCH` (or equivalent explicit default branch include).
- Ruleset includes `pull_request` and `required_status_checks`.
- Optional hardening like `required_linear_history`, `non_fast_forward`, `deletion` is intentional.

Remediation:
- Enable or create a default-branch ruleset.
- Add missing `pull_request` and `required_status_checks` rules.

---

### 3. Required check contexts match real check names

Verification:
```bash
gh api "repos/$OWNER/$REPO/rulesets" \
  --jq '.[] | .rules[] | select(.type=="required_status_checks") | .parameters.required_status_checks[].context'
gh pr list --state all --limit 20 --json number \
  --jq '.[0].number' | xargs -I{} gh pr view {} --json statusCheckRollup
```

Pass criteria:
- Required contexts exactly match real checks reported on PRs (case-sensitive), e.g. `ci`, `Vercel`, `Vercel Preview Comments`.

Remediation:
- Update required check contexts in the ruleset to match actual check names.

---

### 4. Solo-dev compatibility: CODEOWNERS review not forced (if desired)

Verification:
```bash
gh api "repos/$OWNER/$REPO/rulesets" \
  --jq '.[] | {name, pull_request_rules:[.rules[] | select(.type=="pull_request") | .parameters.require_code_owner_review]}'
```

Pass criteria:
- For solo-maintainer repos, `require_code_owner_review` is `false` unless intentionally required.

Remediation:
- Set `require_code_owner_review: false` where solo-dev flow is desired.

---

### 5. Actions policy allows the workflow dependencies you actually use

Verification:
```bash
gh api "repos/$OWNER/$REPO/actions/permissions" \
  --jq '{enabled,allowed_actions,sha_pinning_required}'
gh api "repos/$OWNER/$REPO/actions/permissions/selected-actions" \
  --jq '{github_owned_allowed,verified_allowed,patterns_allowed}'
```

Pass criteria:
- If `allowed_actions: selected`, all actions used by workflows are explicitly allowed (or covered by allowed classes).
- If SHA pinning is required, actions are pinned.

Remediation:
- Add missing action patterns to selected-actions policy.
- Pin unpinned actions.
- Prefer minimal/no third-party actions for sensitive auto-merge workflows.

---

### 6. Auto-merge workflow registration is clean (no ghost duplicates)

Verification:
```bash
gh api "repos/$OWNER/$REPO/actions/workflows" \
  --jq '.workflows[] | [.id,.name,.path,.state] | @tsv' | sort
gh workflow list --all
```

Pass criteria:
- Exactly one active registration for the canonical auto-merge workflow path.
- Legacy/stale registrations are disabled or removed.

Remediation:
- Disable stale workflow IDs:
```bash
gh workflow disable <workflow_id>
```
- Keep a single canonical filename on default branch.

---

### 7. Auto-merge workflow trigger and runtime behavior are reliable

Verification:
```bash
AUTO_WF="Enable PR Auto-Merge"  # adjust if needed
gh workflow view "$AUTO_WF" --yaml | sed -n '1,220p'
gh run list --workflow "$AUTO_WF" --limit 20 \
  --json databaseId,event,status,conclusion,headBranch,createdAt
```

Deep check for suspicious runs:
```bash
RUN_ID="<id>"
gh run view "$RUN_ID" --json event,conclusion,jobs
```

Pass criteria:
- Trigger is intentionally chosen (`pull_request_target` is preferred for base-branch controlled auto-merge orchestration; `pull_request` can be valid if branch consistency is guaranteed).
- Recent PR-event runs execute real jobs.
- No repeating failures with `push` event + zero jobs + missing logs (ghost workflow symptom).

Remediation:
- Move to a stable default-branch workflow file.
- Prefer `pull_request_target` for auto-merge orchestration logic that should not depend on PR-branch workflow file presence.
- Disable stale workflow registrations.

---

### 8. `Cannot update this protected ref` diagnostics for branch-update workflows

Verification:
```bash
gh workflow list --all
gh run list --workflow "Auto Update PR Branches" --limit 20
```

Pass criteria:
- Workflow either:
  - updates eligible PR branches successfully, and
  - handles protected/fork branches gracefully without failing the whole run.

Remediation:
- In update-branch loops, continue on protected/fork failures.
- Skip PR heads that are protected or not writable.
- Treat this error as per-PR conditional failure, not a global workflow failure.

---

### 9. Branch cleanup strategy is in place

Verification:
```bash
gh api "repos/$OWNER/$REPO" --jq '{delete_branch_on_merge}'
gh api "repos/$OWNER/$REPO/actions/workflows" \
  --jq '.workflows[] | {name,path,state}'
```

Pass criteria:
- `delete_branch_on_merge: true`, or equivalent cleanup workflow exists and is active.

Remediation:
- Enable delete-on-merge.
- Add/repair cleanup workflow if additional cleanup behavior is required.

---

### 10. No stale branches from merged/closed PRs

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

---

### 11. Rulesets are primary policy; legacy protection is not conflicting

Verification:
```bash
gh api "repos/$OWNER/$REPO/rulesets" --jq 'length'
gh api "repos/$OWNER/$REPO/branches/$DEFAULT_BRANCH/protection" 2>/dev/null | jq '.'
```

Pass criteria:
- Rulesets are primary mechanism.
- Legacy branch protection is absent or intentionally non-overlapping.
- If branch protection endpoint returns 404 while rulesets exist, that is expected.

Remediation:
- Consolidate policy into rulesets.
- Remove redundant legacy branch protection after parity validation.

## Optional Smoke Test (recommended for auto-merge incidents)

1. Create a temporary PR from a throwaway branch.
2. Confirm auto-merge was enabled:
```bash
gh pr view <pr_number> --json autoMergeRequest
```
3. Confirm auto-merge workflow run event/job execution:
```bash
gh run list --workflow "Enable PR Auto-Merge" --limit 5
```
4. Close PR and delete branch.

## Report Format

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

- Do not delete branches until confirmed stale and unprotected.
- Do not disable workflows blindly; verify canonical registration first.
- Treat `push + 0 jobs + no logs` on workflow runs as likely ghost/stale registration evidence.
- Prefer deterministic `gh api` evidence over assumptions.
- If permissions are insufficient, report missing scope/permission and continue with remaining checks.
