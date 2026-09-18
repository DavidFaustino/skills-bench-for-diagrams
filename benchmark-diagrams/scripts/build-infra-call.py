#!/usr/bin/env python3
"""Builds test 02's MCP call out of test 01's script.

Both tests draw the same diagram; 02 just hands the code to the `generate_diagram` tool
instead of running it directly. Two adaptations are needed:

- the server runtime cannot see variables defined outside `with Diagram(`, so the attribute
  dictionaries have to be inlined into the call;
- passing `outformat` explicitly makes the server return only the PNG. Without it you also
  get the editable `.drawio`, which is the reason to use this server at all.
"""
import json
import pathlib
import sys

BENCH = pathlib.Path(__file__).resolve().parent.parent
SOURCE = BENCH / "results" / "01-diagrams-graphviz" / "generate-diagram.py"
TARGET = BENCH / "results" / "02-mcp-andrewmoshu"

ATTRIBUTES = {
    "graph_attr=graph_attr": (
        'graph_attr={"fontname": "Helvetica", "fontsize": "13", "splines": "ortho", '
        '"nodesep": "0.6", "ranksep": "0.9", "bgcolor": "transparent"}'
    ),
    "node_attr=node_attr": 'node_attr={"fontname": "Helvetica", "fontsize": "11"}',
    "edge_attr=edge_attr": 'edge_attr={"fontname": "Helvetica", "fontsize": "10"}',
}


def main() -> int:
    source = SOURCE.read_text()
    if "with Diagram(" not in source:
        print(f"could not find 'with Diagram(' in {SOURCE}", file=sys.stderr)
        return 1

    code = "with Diagram(" + source.split("with Diagram(", 1)[1]
    for target, replacement in ATTRIBUTES.items():
        code = code.replace(target, replacement)
    code = code.replace(', outformat="png"', "")
    code = code.replace('filename="inventory-graphviz"', 'filename="inventory-mcp"')

    call = {
        "name": "generate_diagram",
        "arguments": {
            "code": code,
            "filename": "inventario-mcp",
            "workspace_dir": str(TARGET),
        },
    }
    print(json.dumps(call, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
