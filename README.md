# i-know-kung-fu

Local skill repository scaffold for coding agents.

## What This Repo Contains

- Root agent index in `AGENTS.md`
- Skill folders in `skills/`
- Initial skill: `skills/github-branch-policy/`
- GitHub workflows for required checks, auto-merge, closed-branch cleanup, and policy drift audits

## Repository Structure

```text
.
├── AGENTS.md
├── README.md
├── skills/
│   └── github-branch-policy/
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
