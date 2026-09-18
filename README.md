# skills-bench-for-diagrams

Five tools drew the same architecture diagram. Here is what came out, what it cost to write,
and one command that regenerates all of it.

![The same diagram, drawn by four of the tools](docs/images/outputs-side-by-side.png)

The two on top decided the layout themselves. The two below took the positions from the author
and handled routing, icons and validation. Same content, same fixture, four results.

[Leia em português](README.pt-BR.md)

## Results

| Tool | Who decides layout | Output | Editable | Works offline | License |
| --- | --- | --- | --- | --- | --- |
| [`diagrams`](https://github.com/mingrammer/diagrams) + Graphviz | the tool | PNG, SVG | no | yes | MIT |
| [MCP infra-diagram](https://github.com/andrewmoshu/diagram-mcp-server) | the tool | PNG, `.drawio` | yes | yes | Apache-2.0 |
| [MCP aws-samples](https://github.com/aws-samples/sample-architecture-diagram-mcp-server) | the tool (ELK) | interactive HTML, `.drawio` | yes | yes | MIT-0 |
| [Eraser CLI](https://github.com/eraserlabs/eraser-diagrams) | you, with auto edge routing | PNG, HTML | no | **no** — fetches icons | MIT |
| **[drawio-skill](https://github.com/Agents365-ai/drawio-skill)** | **you, with validation** | **`.drawio`, PNG, SVG, HTML, PPTX** | **yes** | **yes** | **MIT** |

![Lines of input each tool needed for the same diagram](docs/images/input-size.svg)

`drawio-skill` wins on both axes at once: a third of Eraser's input, and the only tool that
ships a validator — overlaps, crossings and edges routed through boxes, counted. The committed
diagram scores 0. Its `.drawio` is also 11 KB against the 292 KB of the one converted from
Graphviz, because it references shapes by name instead of embedding every icon as base64.

Method, per-tool findings, measurements and platform differences:
**[benchmark-diagrams/](benchmark-diagrams/)**

## The fixture

A fictional version-inventory system: a central AWS account with a private VPC across two
availability zones, a web portal and a collector worker in application subnets, database,
evidence storage and a secrets vault in data subnets, controlled egress, and outside the
account the network of each environment — Staging, Homologation and Production — with ArgoCD
and Kubernetes clusters.

**It is a test fixture, not a reference architecture.** It exercises what separates these
tools: nested containers, vendor icons, edge labels, and elements that are deliberately
undecided. The "route to confirm" node is there to show how to mark what nobody has decided
yet.

## Reproducing it

In a container, which needs nothing installed:

```bash
docker build -t skills-bench-for-diagrams . && docker run --rm -t \
  -v "$PWD/benchmark-diagrams/results:/app/benchmark-diagrams/results" skills-bench-for-diagrams
```

On your own machine:

```bash
./benchmark-diagrams/install.sh && ./benchmark-diagrams/bench.sh
```

`install.sh` clones each tool at the commit it was tested on and pins every package version.
`bench.sh` runs the five, times them, and prints the measured dimensions of every artifact. CI
runs the same container weekly, so a tool that changes shows up as a diff in the artifacts.

## The skills

Six skills ship with the benchmark: one per tool, one optimized build on the winner, and a
twenty-line skill for smoke-testing a new runtime. They are plain `SKILL.md` directories and
work with any model and any agent runtime — with a sixty-line reference loader to prove it.

**[skills-architecture-diagrams/](skills-architecture-diagrams/)**

## Maintainer

Built and maintained by David Faustino, a computer engineer working across application and
cloud security, artificial intelligence and software architecture.

My work connects security engineering and governance: turning risks and requirements into
architecture decisions, automated controls and evidence that supports the decisions teams
have to make. In doing so, I combine experience in development and platforms with building
and evaluating AI solutions.

I work across four complementary fronts:

- AI applied to security — integrating models into security testing and into the analysis of
  findings from code, dependencies, applications and runtime, supporting investigation,
  prioritization and remediation, with validation of the results and human oversight.
- Security architecture and governance — secure development (SSDLC), vulnerability management
  and controls across applications and cloud, connecting technical decisions, risk-based
  prioritization and evidence for compliance and audit.
- AI engineering and evaluation — infrastructure and orchestration for agents, skills, MCP
  servers and the evaluation of open-weight models, on top of earlier machine learning work.
  Quality, reliability, cost and usage limits drive adoption decisions.
- Security capability engineering and DevSecOps — building operators, libraries, integrations
  and automation for applications and cloud environments, including certificate lifecycle
  management. Integrating analysis, testing and protection — SAST, SCA, DAST, IAST, RASP and
  runtime sensors — from development through operations. Using CI/CD, GitOps, Kubernetes and
  AWS to turn security requirements into capabilities other teams can reuse.

This project is part of that practice: sharing implementations, methods and results so that
technical decisions can be examined, reproduced and improved by the community.

Questions, corrections and results from other tools are welcome. Open an issue on this
repository or get in touch at
[davidfaustinoeng@gmail.com](mailto:davidfaustinoeng@gmail.com).

## Licensing

This repository is MIT. The compared tools are **not** vendored — they are cloned from source
at the tested commit. The one exception is the optimized skill, which carries three MIT
scripts and an Apache-2.0 shape index so it runs without installing the upstream skill. Full
provenance, including the modification applied, is in [NOTICE.md](NOTICE.md).

No icon pack is redistributed. AWS's terms allow using their icons in architecture diagrams —
which is what the committed PNGs do — but not redistributing the asset package itself. One
tool in the comparison, a popular Excalidraw skill, ships no license file, so it is referenced
and not copied.
