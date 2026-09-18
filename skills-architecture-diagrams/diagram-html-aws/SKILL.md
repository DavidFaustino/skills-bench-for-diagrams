---
name: diagram-html-aws
description: Generates an AWS architecture diagram as a self-contained interactive HTML page, with draggable nodes, collapsible containers and a guided walkthrough, through the sample-architecture-diagram-mcp-server MCP server. Use when the deliverable is a page that the person opens in the browser or receives by email.
license: MIT
allowed-tools: [Bash, Read, Write]
---

# Interactive AWS diagram in HTML

Replicates test 03 of the package. The server computes the layout with ELK; you describe services,
connections and groups.

## When not to use it

When the drawing has components that are not from AWS. The vocabulary is closed around AWS
services, and anything else becomes a node with its initial inside a square.

## Setup, once

```bash
git clone https://github.com/aws-samples/sample-architecture-diagram-mcp-server.git
```

```bash
npm install --prefix sample-architecture-diagram-mcp-server
```

The official icons are **not** included in the package, because of the AWS terms of use. Without them the
diagram renders with the initial of each service. To have them, download the Asset Package at
https://aws.amazon.com/architecture/icons/ and run `scripts/fetch-icons.sh <Asset-Package.zip>`.

## Workflow

1. Register the server in your runtime, or talk to it over stdio using
   `../../benchmark-diagrams/results/mcpcall.mjs`.

2. Before assembling the call, read the schema — the required fields are not obvious:

   ```bash
   SCHEMA=generate_html_diagram node ../../benchmark-diagrams/results/mcpcall.mjs "node|<path>/mcp-server.js"
   ```

3. Assemble the JSON of the call. Use `../../benchmark-diagrams/results/03-mcp-aws-samples/mcp-call.json` as a
   template. Three rules that the schema does not make clear:

   - **`shape` and `category` are required on every service.** Find the `shape` values
     with the `list_shapes` tool; `category` is one of the ten fixed values of the enum.
   - **Nesting between groups uses `parent`, not `parentId`.** `parentId` is the key of the
     service to its group. Swapping the two flattens the whole hierarchy **without raising an error** —
     the result comes out plausible and wrong.
   - `service` has to be the canonical name of the AWS service, because that is what resolves the icon.
     The friendly name goes in `label`, and the explanation in `role`.

4. Call `generate_html_diagram` and **open the HTML to check the nesting**. If account, VPC and
   subnets appear side by side instead of one inside the other, the `parent` key is wrong.

## Other outputs

`auto_generate_diagram` produces a `.drawio` instead of HTML. `export_diagram_json` and
`export_iac_json` extract the elements as neutral JSON, for another tool to consume.
