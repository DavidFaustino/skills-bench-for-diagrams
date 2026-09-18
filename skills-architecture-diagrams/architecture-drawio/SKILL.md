---
name: architecture-drawio
description: Creates editable enterprise architecture diagrams in draw.io, with official AWS, Azure, GCP and Kubernetes shapes, account, VPC and subnet containers, and structural validation of the result. Use when someone asks for an architecture, infrastructure or network diagram that needs official notation and that another person will edit later.
license: MIT
allowed-tools: [Bash, Read, Write]
---

# Enterprise architecture in draw.io

Produces an editable `.drawio`, not a picture. The layout is yours: you write the XML with the
positions. The tool takes care of the official shapes, the validation and the export.

The scripts in `scripts/` and the index in `data/` come from Agents365-ai's drawio-skill, MIT — see
`NOTICE.md` and `licenses/`. This workflow is the distillation of what worked in a comparative test
against four other tools.

## Prerequisites

- `python3` for the scripts;
- draw.io desktop version 30 or higher to export (`brew install --cask drawio`). Without it,
  you still generate and validate the `.drawio`, but you do not export an image.

## Mandatory workflow

Steps 1 and 4 are not optional. Skipping 1 leads to making up a shape name, which is the most
common error; skipping 4 leads to declaring a drawing done with arrows crossing boxes.

### 1. Search for the name of every shape. Never write from memory

```bash
python3 scripts/shapesearch.py "aws secrets manager" --limit 3
```

The script returns the complete style, to paste into the `style` attribute. Do one search per
component before writing any XML. Common shapes already collected are in
`references/aws-styles.md` — use the list, but confirm through the search anything that is not in it.

### 2. Plan the hierarchy before the coordinates

Decide what contains what: account, VPC, subnets, external network. Containers are what makes the
diagram answer "where does this run", and that is the question a technical audience always asks.

A child's coordinates are **relative to the container**, not to the page.

### 3. Write the XML

Copy `examples/complete-example.drawio` as a starting point — it already has an account, a VPC, two
subnets, an external network, service icons and orthogonal edges. Rules that avoid rework:

- `id="0"` and `id="1"` are mandatory; your elements start at `2`;
- every child of a container uses `parent="<container id>"`;
- a line break in a label is `&#xa;`, never `\n`;
- every edge carries `edgeStyle=orthogonalEdgeStyle;rounded=1;orthogonalLoop=1;jettySize=auto`;
- leave at least 20 px of straight line before the arrow tip, otherwise the head piles up on the curve;
- do not go past fifteen hand-positioned elements. Above that, split into two diagrams.

### 4. Validate, with a number and not with an opinion

```bash
python3 scripts/validate.py diagram.drawio --score
```

Only move on with `0 error(s)` and score `0`. The score counts arrows crossing boxes, crossings and
overlaps.

### 5. Export and look

```bash
drawio -x -f png -o diagram.png --scale 1.5 diagram.drawio
```

Open the image and look for a label on top of a shape, a label on top of a label and an arrow with no
room for its tip. Two correction cycles are enough; beyond that the drawing starts getting worse.

When two arrow labels collide, do not touch coordinates: redistribute the endpoints.

```bash
python3 scripts/edgeports.py diagram.drawio
```

It picks the side of each shape that points to the destination and spreads the outputs, preserving
what you fixed by hand. Run `validate.py` and export again afterwards.

## Content conventions

These make the difference between a pretty drawing and a drawing that survives the meeting.

- **Label in sentence case, in the audience's language.** No `Title Case` and no all caps.
- **The subtitle states the function, not the technology.** "Collection worker / read-only, sanitizes" is worth
  more than "ECS Fargate task".
- **Mark what has not been decided yet.** If the route between networks, the region or the platform
  still depend on approval, write "to be confirmed" on the element itself. A diagram that
  states a decision that does not exist becomes a commitment in the mind of whoever is watching.
- **Do not draw what you do not know.** No made-up firewall rule, no availability
  zone that nobody defined, no RTO number that nobody approved. Absence, when
  declared, is information; invention is debt.
- **One color per category, three at most.** The official icons already bring their own color; the rest
  of the drawing should be neutral.

## Known pitfalls

- `timeout` does not exist in macOS zsh. Call `drawio` directly.
- In a container or in CI, running as root, `drawio` needs `--no-sandbox`: Electron
  refuses to start without it. And with no display, it needs `xvfb-run` in front, with the `xauth` package
  installed.
- The original skill's intermediate representation (`--from ir`) **has no containers**. For a
  diagram with nested account and VPC, write the XML, which is the path of this workflow.
- On Linux, add `--disable-gpu --disable-dev-shm-usage` to the export. Without them, draw.io
  31.4.5 dies with `Empty export data` the moment you pass `--scale` or `--width` — it reads
  like a scaling bug and it is GPU rasterization. With the flags, scaled exports behave the
  same on macOS and Linux.
- Headless Electron sometimes hangs instead of failing, which turns a broken export into a
  stuck job — it burned 22 minutes of a CI run before we capped it. Wrap the call in
  `timeout` whenever you export unattended.
