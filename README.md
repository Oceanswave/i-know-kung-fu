# i-know-kung-fu

A personal collection of agent skills for practical workflows and interesting ideas worth reusing.

## Purpose

This repo is where I keep skills that are useful in my day-to-day work and skills I want to experiment with because the approach is interesting. It is intentionally a living collection, not a single-purpose package.

## What This Repo Contains

- Root agent index in `AGENTS.md`
- Skill folders in `skills/`
- Current skills:
  - `skills/github-branch-policy/`
  - `skills/creative-writing/`
- GitHub workflows for required checks, auto-merge, closed-branch cleanup, and policy drift audits

## Repository Structure

```text
.
├── AGENTS.md
├── README.md
├── skills/
│   ├── github-branch-policy/
│   │   ├── SKILL.md
│   │   └── agents/openai.yaml
│   └── creative-writing/
│       ├── SKILL.md
│       └── agents/openai.yaml
└── .github/workflows/
```

## CI and Policy Gates

- `Required Checks` validates skill structure and audits repository policy drift on every push to `main` and every pull request.
- `Policy Drift Audit` runs daily and on-demand to verify critical repository settings and ruleset integrity.
- Optional: set repo secret `REPO_ADMIN_TOKEN` to enable strict admin-setting verification in drift audits.

## Skill Usage

The `github-branch-policy` skill is designed to audit and enforce GitHub branch governance and workflow hygiene.

- Skill definition: `skills/github-branch-policy/SKILL.md`
- UI metadata: `skills/github-branch-policy/agents/openai.yaml`

The `creative-writing` skill is designed to produce constrained literary prose with strict language and structure rules.

- Skill definition: `skills/creative-writing/SKILL.md`
- UI metadata: `skills/creative-writing/agents/openai.yaml`
