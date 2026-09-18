---
name: diagram-graphviz
description: Generates infrastructure diagrams with official AWS, Azure, GCP and Kubernetes icons using the Python diagrams library and Graphviz, with automatic layout. Use when someone asks for a quick infrastructure diagram, with cloud icons, and exact positioning does not matter.
license: MIT
allowed-tools: [Bash, Read, Write]
---

# Infrastructure diagram with the `diagrams` library

Replicates test 01 of the package. The layout is decided by Graphviz: you declare nodes and edges,
not positions.

## When not to use it

When the drawing has to fit on a 16:9 slide, or when visual grouping matters. Graphviz
stacks in portrait and there is no parameter that fixes it. For that, use
`../architecture-drawio/`.

## Setup, once

```bash
brew install graphviz
```

```bash
uv venv .venv && uv pip install --python .venv/bin/python diagrams
```

## Workflow

1. Write a Python script declaring the diagram. Group with nested `Cluster` and prefer
   `direction="LR"` — `TB` produces disproportionate portraits:

   ```python
   from diagrams import Diagram, Cluster, Edge
   from diagrams.aws.compute import ECS
   from diagrams.aws.database import RDS
   from diagrams.onprem.gitops import ArgoCD

   graph_attr = {"fontname": "Helvetica", "splines": "ortho", "bgcolor": "transparent"}

   with Diagram("Title", show=False, direction="LR", outformat="png", graph_attr=graph_attr):
       with Cluster("Central account"):
           app = ECS("Application")
           db = RDS("PostgreSQL")
       argo = ArgoCD("ArgoCD")
       app >> db
       app >> Edge(label="HTTPS read-only") >> argo
   ```

2. Confirm the class names before importing — making up a node name is the most common error:

   ```bash
   .venv/bin/python -c "import diagrams.aws.compute as m; print([a for a in dir(m) if a[0].isupper()])"
   ```

3. Generate it and check the image proportion. If the height goes past one and a half times the width,
   change the direction or redistribute the clusters.

## The SVG pitfall

With `outformat="svg"`, the icons end up referenced by the venv's absolute path and disappear
when the file is moved. For a portable SVG, convert the images to base64 after
generating — see `../../benchmark-diagrams/results/01-diagrams-graphviz/`. In PNG the problem does not exist.
