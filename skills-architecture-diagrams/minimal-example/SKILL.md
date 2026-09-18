---
name: minimal-example
description: Test skill that counts lines, words and characters of a text file. Use it to validate that a new agent runtime discovers, loads and runs skills correctly.
license: MIT
allowed-tools: [Bash, Read]
---

# Minimal example

It exists to prove that the runtime implements the three layers: announce, load and execute.

## Usage

1. Run the script on the file the user indicated:

   ```bash
   python3 scripts/count.py <file-path>
   ```

2. Return the three counts to the user and say which is the longest line.

## Runtime check

If the model answered without running the script, the runtime loaded the `SKILL.md` but did not expose the
shell tool. If the model did not even mention the skill, the problem is in the announce layer:
`name` and `description` did not reach the system prompt.
