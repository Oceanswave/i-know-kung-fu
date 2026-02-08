# i-know-kung-fu

Local skill repository scaffold for coding agents.

## What This Repo Contains

- Root agent index in `AGENTS.md`
- Skill folders in `skills/`
- Initial skill: `skills/github-branch-policy/`
- GitHub workflows for required checks, auto-merge, and closed-branch cleanup

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

## Skill Usage

The `github-branch-policy` skill is designed to audit and enforce GitHub branch governance and workflow hygiene.

- Skill definition: `skills/github-branch-policy/SKILL.md`
- UI metadata: `skills/github-branch-policy/agents/openai.yaml`
