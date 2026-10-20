# VSL Scriptwriting Skill Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a `vsl-scriptwriting` skill that converts the VSL Master Prompt v2 from XML to Markdown and integrates it into the skill repo.

**Architecture:** Single monolithic SKILL.md containing the full four-phase VSL framework (information collection, psychographic profiling, iterative script writing, output delivery) with a companion openai.yaml for UI metadata.

**Tech Stack:** Markdown, YAML, Python (existing validation script)

---

### Task 1: Create SKILL.md

**Files:**
- Create: `skills/vsl-scriptwriting/SKILL.md`

**Step 1: Create directory**

```bash
mkdir -p skills/vsl-scriptwriting/agents
```

**Step 2: Write SKILL.md**

Write the full SKILL.md with these sections, converting XML to Markdown per the design doc:

- YAML frontmatter (`name: vsl-scriptwriting`, `description:` without angle brackets)
- `# VSL Scriptwriting` header
- `## Overview` — role definition from `<role>`
- `## Philosophy` — numbered list from `<philosophy>` (7 principles)
- `## Writing Rules` — subsections from `<writing_rules>` (Voice, Structure, Perspective, Transitions, Tone Calibration, Confidence, Format, Language, Integrity)
- `## Mental Models` — subsections from `<mental_models>` (4 frameworks)
- `## Phase A: Information Collection` — from `<phase_a>`: numbered required questions, clarifying questions, Quality Gate A checklist
- `## Phase B: Psychographic Profile` — from `<phase_b>`: 6 subsections (The Concrete Person, Layered Desires, Fear Architecture, Current Beliefs and Required Shifts, Belief Chain, Emotional Arc), Quality Gate B checklist
- `## Phase C: Iterative Script Writing` — from `<phase_c>`: beat framework intro, 15 beats as `### Beat N: Name` subsections each with Job/Rules/Timing metadata, iteration process (3 iterations with Copy Chief Review 8-point checklist), failure modes as a checklist, Quality Gate C checklist
- `## Phase D: Output Delivery` — from `<phase_d>`: 3 deliverables as subsections

Content conversion rules:
- `<beat number="N" name="X" timing="Y">` → `### Beat N: X` with `**Timing:** Y` on first line
- `<profile_section name="X" target="Y">` → `### X` with `**Target:** Y` on first line
- `<quality_gate id="X">` → `#### Quality Gate X` with `- [ ]` checklist items
- `<iteration number="N">` → `#### Iteration N`
- Strip all XML tags, preserve all instructional text verbatim
- Strip the `<usage_notes>` section entirely

**Step 3: Commit**

```bash
git add skills/vsl-scriptwriting/SKILL.md
git commit -m "feat: add vsl-scriptwriting SKILL.md"
```

---

### Task 2: Create openai.yaml

**Files:**
- Create: `skills/vsl-scriptwriting/agents/openai.yaml`

**Step 1: Write openai.yaml**

```yaml
interface:
  display_name: "VSL Scriptwriting"
  short_description: "Write high-converting video sales letter scripts"
  default_prompt: "Write a high-converting VSL script using the four-phase process: collect business info, build psychographic profile, write iterative script drafts, deliver final assets."
```

**Step 2: Commit**

```bash
git add skills/vsl-scriptwriting/agents/openai.yaml
git commit -m "feat: add vsl-scriptwriting openai.yaml"
```

---

### Task 3: Update AGENTS.md

**Files:**
- Modify: `AGENTS.md:11` (add after last skill entry)

**Step 1: Add skill entry**

Add this line after the `book-manuscript-development` entry:

```markdown
- `vsl-scriptwriting`: Write high-converting Video Sales Letter scripts through a four-phase process: information collection, psychographic profiling, iterative script writing, and output delivery. File: `skills/vsl-scriptwriting/SKILL.md`
```

**Step 2: Commit**

```bash
git add AGENTS.md
git commit -m "docs: add vsl-scriptwriting to AGENTS.md"
```

---

### Task 4: Update README.md

**Files:**
- Modify: `README.md`

**Step 1: Add to skill listing (line 17)**

Add after the `book-manuscript-development` entry:

```markdown
  - `skills/vsl-scriptwriting/`
```

**Step 2: Add to structure tree (around line 38)**

Add inside the skills tree:

```markdown
│   ├── vsl-scriptwriting/
│   │   ├── SKILL.md
│   │   └── agents/openai.yaml
```

**Step 3: Add usage section (after line 68)**

```markdown
The `vsl-scriptwriting` skill writes high-converting Video Sales Letter scripts through a four-phase process.

- Skill definition: `skills/vsl-scriptwriting/SKILL.md`
- UI metadata: `skills/vsl-scriptwriting/agents/openai.yaml`
```

**Step 4: Commit**

```bash
git add README.md
git commit -m "docs: add vsl-scriptwriting to README.md"
```

---

### Task 5: Run validation and verify

**Step 1: Run skill validation**

```bash
python3 scripts/validate_skills.py
```

Expected: `Skill validation passed for 6 skill(s).`

**Step 2: Verify frontmatter name matches directory**

```bash
head -5 skills/vsl-scriptwriting/SKILL.md
```

Expected: frontmatter `name: vsl-scriptwriting`

**Step 3: Verify no angle brackets in description**

```bash
grep -c '[<>]' skills/vsl-scriptwriting/SKILL.md | head -1
```

Expected: 0 (no angle brackets in frontmatter description — body content is fine)

**Step 4: Verify no TODO placeholders**

```bash
grep -c '\[TODO:' skills/vsl-scriptwriting/SKILL.md
```

Expected: 0

**Step 5: Verify openai.yaml short_description length**

```bash
python3 -c "s='Write high-converting video sales letter scripts'; print(len(s), '(must be 25-64)')"
```

Expected: 48 (within 25-64 range)
