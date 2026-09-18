# One skill per tool

Each skill here reproduces one of the tests in the `../benchmark-diagrams/results/` folder. They are deliberately
short: the goal is to replicate the experiment and feel the friction of each tool, not to cover
every one of its features.

| Skill | Test | Tool |
| --- | --- | --- |
| `minimal-example/` | — | None. Use it to validate a new runtime before loading the others |
| `diagram-graphviz/` | 01 | `diagrams` library + Graphviz, from the terminal |
| `diagram-mcp-infra/` | 02 | The same library, through andrewmoshu's MCP server |
| `diagram-html-aws/` | 03 | AWS MCP server, output as interactive HTML |
| `diagram-eraser/` | 04 | Eraser Diagrams CLI |
| draw.io | 05 | Not here — see below |

## Why there is no draw.io skill in this folder

The draw.io skill already exists and is public, under the MIT license:
https://github.com/Agents365-ai/drawio-skill

```bash
npx skills add Agents365-ai/drawio-skill -g
```

If you install it by hand, watch out: the repository keeps the skill in `skills/drawio-skill/`,
so cloning the root straight into `<your-agent>/skills/drawio-skill` leaves `SKILL.md` one level too
deep and the agent does not find it. Clone into a temporary directory and copy only the inner folder.

What this package adds is the layer above: `../skills-architecture-diagrams/` distills the workflow that
worked, so that a smaller model does not get lost in the twenty reference files of the original
skill.

## Installation

Copy the skill folder into whatever directory your agent scans for skills. Runtimes differ:
some read a global folder under your home directory, some a project-scoped one, some take a
path in a config file. The skill itself does not care. For your own runtime, read
`../skills-architecture-diagrams/RUN-IN-YOUR-OWN-AGENT.md`.
