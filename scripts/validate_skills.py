#!/usr/bin/env python3
"""Validate local skill structure and guard against template regressions."""

from __future__ import annotations

import re
import sys
from pathlib import Path

import yaml


def parse_frontmatter(content: str) -> dict | None:
    match = re.match(r"^---\n(.*?)\n---", content, re.DOTALL)
    if not match:
        return None
    try:
        data = yaml.safe_load(match.group(1))
    except yaml.YAMLError:
        return None
    return data if isinstance(data, dict) else None


def validate_skill_dir(skill_dir: Path) -> list[str]:
    errors: list[str] = []
    skill_name = skill_dir.name
    skill_md = skill_dir / "SKILL.md"
    openai_yaml = skill_dir / "agents" / "openai.yaml"

    if not skill_md.exists():
        return [f"{skill_name}: missing SKILL.md"]

    content = skill_md.read_text()
    if "[TODO:" in content:
        errors.append(f"{skill_name}: SKILL.md contains unresolved template TODOs")

    frontmatter = parse_frontmatter(content)
    if frontmatter is None:
        errors.append(f"{skill_name}: invalid or missing YAML frontmatter")
    else:
        fm_name = str(frontmatter.get("name", "")).strip()
        fm_description = str(frontmatter.get("description", "")).strip()
        if not fm_name:
            errors.append(f"{skill_name}: frontmatter.name is empty")
        if fm_name != skill_name:
            errors.append(
                f"{skill_name}: frontmatter.name '{fm_name}' does not match directory '{skill_name}'"
            )
        if not fm_description:
            errors.append(f"{skill_name}: frontmatter.description is empty")
        if "<" in fm_description or ">" in fm_description:
            errors.append(f"{skill_name}: frontmatter.description contains angle brackets")

    if not openai_yaml.exists():
        errors.append(f"{skill_name}: missing agents/openai.yaml")
    else:
        try:
            ui = yaml.safe_load(openai_yaml.read_text()) or {}
        except yaml.YAMLError as exc:
            errors.append(f"{skill_name}: invalid openai.yaml ({exc})")
        else:
            interface = ui.get("interface")
            if not isinstance(interface, dict):
                errors.append(f"{skill_name}: openai.yaml missing interface object")
            else:
                display_name = str(interface.get("display_name", "")).strip()
                short_description = str(interface.get("short_description", "")).strip()
                if not display_name:
                    errors.append(f"{skill_name}: interface.display_name is empty")
                if not short_description:
                    errors.append(f"{skill_name}: interface.short_description is empty")
                if short_description and not (25 <= len(short_description) <= 64):
                    errors.append(
                        f"{skill_name}: interface.short_description length {len(short_description)} is outside 25-64"
                    )

    return errors


def main() -> int:
    root = Path(__file__).resolve().parents[1]
    skills_dir = root / "skills"

    if not skills_dir.exists():
        print("ERROR: skills/ directory not found")
        return 1

    skill_dirs = sorted(path for path in skills_dir.iterdir() if path.is_dir())
    if not skill_dirs:
        print("ERROR: no skill directories found under skills/")
        return 1

    errors: list[str] = []
    for skill_dir in skill_dirs:
        errors.extend(validate_skill_dir(skill_dir))

    if errors:
        print("Skill validation failed:")
        for err in errors:
            print(f"- {err}")
        return 1

    print(f"Skill validation passed for {len(skill_dirs)} skill(s).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
