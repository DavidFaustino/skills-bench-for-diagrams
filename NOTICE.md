# Provenance and third-party licenses

This repository is MIT — see `LICENSE`. Everything that came from elsewhere is listed here.

## Redistributed inside this repository

### `skills-architecture-diagrams/architecture-drawio/scripts/`

`shapesearch.py`, `validate.py` and `edgeports.py` are unmodified copies from
[drawio-skill](https://github.com/Agents365-ai/drawio-skill) by Agents365-ai, MIT licensed.
License text in `licenses/MIT-drawio-skill.txt`.

### `skills-architecture-diagrams/architecture-drawio/data/shape-index.json.gz`

A shape search index originating from
[jgraph/drawio-mcp](https://github.com/jgraph/drawio-mcp) (`shape-search/search-index.json`),
generated from the official draw.io / diagrams.net client shape libraries. Both upstream
sources are licensed under the **Apache License 2.0** — text in `licenses/Apache-2.0.txt`.

**Modification applied:** the file was compressed with `gzip -9`. The contents are unchanged.

It holds 10,446 entries shaped `{style, w, h, title, tags, type}`, read-only, used to resolve
the exact style string for a shape instead of guessing it.

## Referenced, not redistributed

The compared tools are **not** in this repository. `benchmark-diagrams/install.sh` clones each
one from source, at the commit it was tested on.

| Tool | License | Source |
| --- | --- | --- |
| drawio-skill | MIT | https://github.com/Agents365-ai/drawio-skill |
| infrastructure-diagram-mcp-server | Apache-2.0 | https://github.com/andrewmoshu/diagram-mcp-server |
| sample-architecture-diagram-mcp-server | MIT-0 | https://github.com/aws-samples/sample-architecture-diagram-mcp-server |
| eraser-diagrams | MIT | https://github.com/eraserlabs/eraser-diagrams |
| diagrams (mingrammer) | MIT | https://github.com/mingrammer/diagrams |
| architecture-diagram-generator | MIT | https://github.com/Cocoon-AI/architecture-diagram-generator |
| excalidraw-diagram-skill | **no license** | https://github.com/coleam00/excalidraw-diagram-skill |

The last one ships no license file. With no license declared, the work is under full
copyright: you may read it, you may not redistribute it. That is why it is only mentioned in
the comparison, with no copy and no equivalent skill here.

## Official cloud icon packs

No icon pack is redistributed.

AWS distributes its icons in the Asset Package under its own terms, which allow using the
icons in architecture diagrams but not redistributing the collection. To get them into the AWS
MCP server, download them from https://aws.amazon.com/architecture/icons/ and run that
project's `fetch-icons.sh`.

The result images under `benchmark-diagrams/results/` contain icons rendered inside diagrams,
which is the intended use, not a redistribution of the collection.

This is a good-faith description of provenance, not legal advice.
