---
name: diagram-mcp-infra
description: Generates infrastructure diagrams in PNG and draw.io from Python code, Kubernetes manifests, Helm charts or Terraform configurations, through the infrastructure-diagram-mcp-server MCP server. Use when the source of the diagram is infrastructure already declared in a file.
license: Apache-2.0
allowed-tools: [Bash, Read, Write]
---

# Infrastructure diagram through the MCP server

Replicates test 02 of the package. Underneath it is the same `diagrams` library as the
`../diagram-graphviz/` skill, so the layout has the same limitations. Two things justify using
the server: it returns an editable `.drawio` along with the PNG, and it reads infrastructure already declared.

## When not to use it

When you have a terminal. The server does nothing that `python3 -c` cannot do, and it adds an
installation layer. It pays off when the agent only speaks MCP.

## Setup, once

```bash
git clone https://github.com/andrewmoshu/diagram-mcp-server.git
```

`pygraphviz` does not compile without pointing at the Graphviz headers:

```bash
CFLAGS="-I$(brew --prefix graphviz)/include" LDFLAGS="-L$(brew --prefix graphviz)/lib" uv sync
```

## Tools

| Tool | What it is for |
| --- | --- |
| `generate_diagram` | Takes `code` in Python from the `diagrams` library and returns a PNG plus a `.drawio` |
| `get_diagram_examples` | Ready-made examples by diagram type |
| `list_icons` | Lists the available icons, with a filter |
| `parse_k8s_manifest` | Extracts resources and relationships from Kubernetes YAML |
| `parse_helm_chart` | The same, rendering the chart |
| `parse_terraform` | The same, from HCL |

## Workflow

1. Call `generate_diagram` passing the Python code in `code` and the project directory in
   `workspace_dir` — without it, the files go to a random temporary directory.
2. The runtime already imports everything: start straight at `with Diagram(`, without the `import`s.
3. Check the image proportion and, if you are going to use the `.drawio`, open it to check whether the
   clusters actually became containers.

To draw from existing infrastructure, start with `parse_terraform` or
`parse_k8s_manifest` and use the result as the base of the code, instead of describing it by hand.
