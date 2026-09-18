# The optimized skill

`architecture-drawio/` is the skill built on top of the tool that won the test.

## What it adds to the original skill

The original [drawio-skill](https://github.com/Agents365-ai/drawio-skill) is excellent and much
larger: 147 lines of `SKILL.md` that are almost entirely a routing table for twenty
reference files, covering ERD, UML, BPMN, metro maps, Terraform import,
diff in CI and more. For a large agent, that is richness. For a smaller model, it is where it
gets lost: it skips the step of consulting the shape index and makes up a style name.

This version makes three different choices:

1. **A single path.** Enterprise architecture diagram with account, VPC and subnet containers.
   No routing table, no choosing between six routes.
2. **Mandatory steps instead of suggested ones.** Search for the shape before writing, and validate
   with a number before declaring it done. These are the two points where the model fails on its own.
3. **Content conventions.** Label in sentence case, subtitle that states the function, and the rule of marking
   as "to be confirmed" whatever has not been decided yet instead of drawing it as if it had.

## What it brings along

It is self-contained: it brings the three scripts that matter and the shape index, so it works without
installing the original skill.

| Path | What it is |
| --- | --- |
| `scripts/shapesearch.py` | Searches the official index of 10 thousand shapes |
| `scripts/validate.py` | Measures errors, overlaps and arrows crossing boxes |
| `scripts/edgeports.py` | Redistributes the arrow endpoints when labels collide |
| `data/shape-index.json.gz` | The shape index, 428 KB |
| `references/aws-styles.md` | The styles already collected, ready to paste |
| `examples/complete-example.drawio` | Complete diagram, to copy as a starting point |
| `licenses/MIT-drawio-skill.txt` | The MIT license of the origin of the scripts and the index |

The scripts and the index are by Agents365-ai, under MIT. The workflow, the conventions and the style
reference belong to this package.

## Installation

```bash
cp -R architecture-drawio <your-agent>/skills/
```

In another runtime, see `../skills-architecture-diagrams/RUN-IN-YOUR-OWN-AGENT.md`. The skill declares in `allowed-tools` that it needs
shell, file read and file write — nothing beyond that.
