# VSL Scriptwriting Skill Design

## Summary

Add a `vsl-scriptwriting` skill that guides Claude through a four-phase process to produce high-converting Video Sales Letter scripts for service businesses, agencies, coaches, and B2B companies.

## Directory Structure

```
skills/vsl-scriptwriting/
├── SKILL.md
└── agents/
    └── openai.yaml
```

## SKILL.md Layout

Monolithic Markdown file converted from the original XML-structured VSL Master Prompt v2.

### Frontmatter

- `name: vsl-scriptwriting`
- `description:` concise summary, no angle brackets

### Sections

1. **Overview** — Role definition
2. **Philosophy** — 7 governing principles (Clear Over Clever, Feel First Define Second, Specificity Is Credibility, Pain Has Diminishing Returns, Belief Chain Is The Architecture, One Asset Multiple Metrics, Three-Second Principle)
3. **Writing Rules** — Voice, structure, perspective, transitions, tone calibration, format, banned language, integrity
4. **Mental Models** — 4 frameworks (Conversion Gap, Revenue Tier Calibration, Logistics Trap, Hook Is A Promise)
5. **Phase A: Information Collection** — 15 required questions, clarifying questions, quality gate A
6. **Phase B: Psychographic Profile** — 6 profile sections with word targets, quality gate B
7. **Phase C: Iterative Script Writing** — 17-beat framework, 3-iteration review cycle, failure modes, quality gate C
8. **Phase D: Output Delivery** — 3 deliverables (Final Script, Visual Cue Notes, Psychographic Profile)

### Conversion Rules

- XML tags become Markdown headers (`<beat number="1">` → `### Beat 1: Immediate Promise Hook`)
- XML attributes (`timing`, `target`, `min_count`) become inline bold metadata
- Quality gates become Markdown checklists
- Banned phrases become bullet lists
- Usage notes section is stripped entirely
- Instructional content is preserved verbatim

## openai.yaml

```yaml
interface:
  display_name: "VSL Scriptwriting"
  short_description: "Write high-converting video sales letter scripts"
```

## Other Files Updated

- `AGENTS.md` — add skill entry
- `README.md` — add to listing and structure tree
