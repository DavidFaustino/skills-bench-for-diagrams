# The five runs

Every run draws the same diagram: a corporate user, a central AWS account with a private VPC
across two availability zones, application and data subnets, controlled egress, a route still
to be confirmed, and the network of each environment with ArgoCD and Kubernetes.

Run them all with `./install.sh && ./bench.sh`. Each input below is committed next to the
output it produced.

## 01 — `diagrams` library + Graphviz, called from the shell

- `results/01-diagrams-graphviz/generate-diagram.py` — the input. Declarative Python with
  nested `Cluster` blocks.
- `results/01-diagrams-graphviz/inventory-graphviz.png` — the output.

Install: `brew install graphviz`, then `uv pip install diagrams` in a venv.

The first attempt came out as a 1073×1343 portrait, unusable on a 16:9 slide. Switching to
`direction="LR"` fixed the ratio and still leaves about a third of the canvas empty. Accented
characters work.

Exporting to SVG, the icons end up referenced by absolute paths inside the venv: the file
breaks the moment you move it, and you have to inline the images as base64 to make it
portable. PNG does not have this problem.

## 02 — andrewmoshu MCP server (infrastructure-diagram-mcp-server)

- `results/02-mcp-andrewmoshu/mcp-call.json` — the input, generated from run 01's script by
  `scripts/build-infra-call.py`.
- `results/02-mcp-andrewmoshu/inventory-mcp.png` and `.drawio` — both outputs of a single call.

Underneath it is the same library as run 01, wrapped in an MCP server. The tool is
`generate_diagram` and its argument is the same Python code. The editable `.drawio` is the real
gain over run 01.

Two things cost time here. `pygraphviz` will not build without pointing at the Graphviz
headers:

```bash
CFLAGS="-I$(brew --prefix graphviz)/include" LDFLAGS="-L$(brew --prefix graphviz)/lib" uv sync
```

And passing `outformat` explicitly makes the server return only the PNG. Leave it out and you
also get the `.drawio` — which is the whole reason to use this server.

## 03 — aws-samples MCP server (sample-architecture-diagram-mcp-server)

- `results/03-mcp-aws-samples/mcp-call.json` — the input, in the shape `generate_html_diagram`
  expects.
- `results/03-mcp-aws-samples/inventory-aws.html` — a self-contained interactive page.
- `results/03-mcp-aws-samples/inventory-aws.json` — the same elements as neutral JSON, for
  another tool to consume.

Two gotchas. `shape` and `category` are required on every node, and neither is obvious from
the schema. And group nesting uses the key `parent`, not `parentId` — `parentId` is what a
*service* uses to point at its group. Use the wrong one and the whole hierarchy flattens
**with no error at all**: the diagram comes out plausible and wrong.

The official AWS icons are not bundled, because of the AWS Terms of Use. Without downloading
the Asset Package, every node renders as a category-colored initial.

## 04 — Eraser CLI

- `results/04-eraser/inventory-eraser.json` — the input. Every entity carries `x` and `y`;
  connections are just `{"from": ..., "to": ...}`.
- `results/04-eraser/inventory-eraser.png` — the output, rendered in about 1.2 seconds.

Install: `npm i -D @eraserlabs/diagrams-cli`. Needs Node 22.12+ and a Chromium — an installed
Google Chrome will do.

Icon names are not guessable. `aws-ecs`, `aws-sqs`, `aws-s3`, `argocd` and `aws-eks` do not
exist; the right ones are `aws-elastic-container-service`, `aws-simple-queue-service`,
`aws-simple-storage-service`, `argo` and `aws-ec2`. An unknown name does not fail the render —
it becomes a placeholder glyph plus a warning that suggests a close match.

Icons are fetched from Eraser's public bucket on every render. Your JSON never leaves the
machine, but the render needs network access.

## 05 — drawio-skill

- `results/05-drawio-skill/inventory-drawio.drawio` — both the input and the deliverable.
- `results/05-drawio-skill/inventory-drawio.png` — the export.

The workflow that produced it is distilled in
`../skills-architecture-diagrams/architecture-drawio/`.

## `results/mcpcall.mjs`

A minimal MCP client in plain Node, used to talk to the servers in runs 02 and 03 without
restarting an agent. It performs `initialize`, `tools/list` and `tools/call` over stdio.

```bash
node mcpcall.mjs "node|/path/to/mcp-server.js"                     # list the tools
SCHEMA=generate_html_diagram node mcpcall.mjs "node|/path/to/server.js"  # print one schema
node mcpcall.mjs "node|/path/to/server.js" "@call.json"             # execute a call
```

The command separator is `|`, because the whole command is passed as a single argument.
