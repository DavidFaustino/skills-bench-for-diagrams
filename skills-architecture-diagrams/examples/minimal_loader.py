#!/usr/bin/env python3
"""A reference skill loader in 60 lines, with no dependencies.

This is the whole contract. Everything a runtime needs in order to run the skills in this
repository is here: find the skills, advertise them cheaply, load one in full when it is
relevant. What you do with the text afterwards belongs to your agent loop, not to this file.

    python3 minimal_loader.py                    # what goes in the system prompt
    python3 minimal_loader.py architecture-drawio  # what to load when that skill matches

The third layer — reading references/ and running scripts/ — needs no code here. It is your
existing file-read and shell tools, pointed at paths the skill body mentions.
"""
import pathlib
import sys

SKILLS_DIR = pathlib.Path(__file__).resolve().parent.parent


def parse_frontmatter(skill_md: pathlib.Path) -> tuple[dict[str, str], str]:
    """Splits a SKILL.md into its YAML-ish header and its body.

    Deliberately not a YAML parser: the header is flat `key: value` pairs, and depending on a
    YAML library is the kind of thing that stops a runtime from being ported.
    """
    text = skill_md.read_text(encoding="utf-8")
    if not text.startswith("---"):
        return {}, text

    _, header, body = text.split("---", 2)
    meta: dict[str, str] = {}
    for line in header.strip().splitlines():
        if ":" in line and not line.startswith((" ", "\t", "#")):
            key, value = line.split(":", 1)
            meta[key.strip()] = value.strip()
    return meta, body.strip()


def discover() -> list[tuple[dict[str, str], pathlib.Path]]:
    """Layer 1: every SKILL.md under this directory, cheapest read possible."""
    found = []
    for skill_md in sorted(SKILLS_DIR.glob("*/SKILL.md")):
        meta, _ = parse_frontmatter(skill_md)
        if meta.get("name") and meta.get("description"):
            found.append((meta, skill_md))
    return found


def advertise() -> str:
    """Layer 1 output: this is what belongs in the system prompt, and nothing more."""
    lines = ["Available skills:"]
    for meta, _ in discover():
        lines.append(f"- {meta['name']}: {meta['description']}")
    return "\n".join(lines)


def load(name: str) -> str:
    """Layer 2: the full body, read only once a task matches the description."""
    for meta, skill_md in discover():
        if meta["name"] == name:
            _, body = parse_frontmatter(skill_md)
            return body
    raise SystemExit(f"no skill named {name!r}; known: {[m['name'] for m, _ in discover()]}")


if __name__ == "__main__":
    if len(sys.argv) == 1:
        prompt = advertise()
        print(prompt)
        print(f"\n[{len(prompt) // 4} tokens, roughly, for {len(discover())} skills]",
              file=sys.stderr)
    else:
        print(load(sys.argv[1]))
