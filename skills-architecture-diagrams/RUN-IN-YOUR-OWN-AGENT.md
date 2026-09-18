# Running these skills in your own agent

**Read this if you are writing the program that loads skills** — your own agent loop, a CLI, a
bot, a service. Any runtime, any model.

**Skip it if you already have a runtime that reads skills.** Copy a skill directory into the
folder it scans and you are done; it already does everything described here.

## What you are actually implementing

A skill is a directory with a `SKILL.md` inside it. The file has a small YAML header and a
Markdown body. That is the whole format — it is published as an open specification, and
several agent runtimes read it, which is why the draw.io skill in this repository carries
header metadata for two runtimes other than the one it was written for.

Running one takes three behaviors. None of them needs a new API, a protocol or a server.

### 1. Advertise — at startup

Scan your skills directory, read each `SKILL.md` header, and put **only** `name` and
`description` in the system prompt.

```
Available skills:
- architecture-drawio: Creates editable enterprise architecture diagrams in draw.io […]
- minimal-example: Test skill that counts lines, words and characters of a text file […]
```

The six skills in this repository cost about 440 tokens advertised this way. That is the
entire budget the model needs in order to know they exist.

The `description` is the only thing the model uses to decide. Write it as *when to use this*,
not as *what this tool is* — a description that says "generates diagrams" gets picked for
every drawing request, including the ones that skill handles badly.

### 2. Load — when a task matches

Read that one `SKILL.md` body into context, in full. Keep bodies under roughly 5,000 tokens;
anything longer goes into a separate file that the body points at by relative path, and gets
read only if the model asks for it.

Three layers, then: names always, one body when relevant, references and scripts only on
demand. That is progressive disclosure, and it is the reason twenty skills do not cost twenty
bodies of context.

### 3. Execute — while the model works

The skills here need two tools you almost certainly already have:

- **read a file**, to open `references/*.md` and inspect what was generated;
- **run a shell command**, to run `scripts/*.py` and binaries like `drawio`, `dot` and `node`.

A third helps: **write a file**, so the model can produce the `.drawio` or the input JSON.
Each skill declares what it expects in its header, under `allowed-tools`. Treat that as a
declaration of intent, not as a sandbox: enforcement is your runtime's job.

## A loader you can run

`examples/minimal_loader.py` implements layers 1 and 2 in about sixty lines of dependency-free
Python:

```bash
python3 examples/minimal_loader.py
```

prints exactly what belongs in your system prompt, and

```bash
python3 examples/minimal_loader.py architecture-drawio
```

prints exactly what to inject when that skill is selected. Layer 3 needs no code from us: it
is your existing file and shell tools, pointed at the paths the body mentions.

Start by wiring `minimal-example` end to end. It counts lines in a file, so the answer is
verifiable, and it isolates which layer is broken: if the model never mentions the skill,
layer 1 failed; if it answers without running the script, layer 3 is not wired.

## What this is not

It is not an orchestration layer. Skills do not call each other, do not declare dependencies
and have no execution order. Each one is a document the model may choose to read. If you need
one task to run after another, that is your agent loop's job, not the skill format's.

## Matching the skill to the model

These skills are plain text and work with any model. How well they work depends less on the
vendor than on the size of the model and on how much multi-step following it can sustain.

| Model class | What to expect | What to change |
| --- | --- | --- |
| Large hosted or large open-weight | Follows a 20-reference routing table, picks the right branch, recovers from its own errors | Nothing. The upstream drawio-skill works as published |
| Mid-size open-weight | Follows one path reliably, starts skipping optional steps | Prefer single-path skills like `architecture-drawio`; keep the validation step mandatory |
| Small open-weight, or heavily quantized | Skips lookups, invents identifiers, loops on repairs | Replace lookups with a table in `references/`, cap repair cycles, verify every run |

Four failure modes worth designing against, in rough order of how often we hit them:

- **Skipping the lookup step.** The typical failure with the draw.io skill is inventing
  `mxgraph.aws4.postgres`, a shape name that does not exist, instead of searching the index.
  The fix is structural: make the search the first mandatory step, with the command ready to
  copy, which is what `architecture-drawio/SKILL.md` does.
- **Being unable to judge its own output.** Give every skill a check that returns a number
  rather than an opinion — `validate.py --score` returns the count of overlaps and of edges
  crossing boxes. Without it, a model declares success by rereading its own XML.
- **Getting lost in long skills.** A routing table with twenty destinations is a feature for a
  large model and a trap for a small one. One path per skill ports much further down.
- **Repairing forever.** Cap the loop at two cycles. Past that, the drawing gets worse.

A cheap way to measure any of this: run the same request five times and count how many come
back with `0 error(s)` and score `0`. That number, not a vibe, tells you whether a model can
carry a given skill.

## Checking the model's license before you ship

Whichever model you pick, its license is a separate question from this repository's. Skills
are MIT text files; the model that reads them is governed by its own terms. What to verify,
before a skill goes anywhere near production:

- **Open weights is not the same as open source.** Some weights ship under a permissive
  license such as Apache-2.0 or MIT. Others ship under a custom community or research license
  with conditions attached — acceptable-use rules, scale thresholds, naming requirements.
  Read the actual file in the model repository rather than the blog post announcing it.
- **Commercial use.** Confirm it explicitly, including for a model you only call through a
  hosted API. Research-only weights exist and are easy to miss.
- **What you may do with the outputs.** Some terms restrict using outputs to train or improve
  another model. If your pipeline collects generated diagrams as training data, that clause
  applies to you.
- **Redistribution and derivatives.** If you fine-tune and ship the result, check whether the
  license follows the derivative, whether attribution is required, and whether the name has to
  carry a prefix.
- **Attribution in the product.** A few licenses require a visible notice wherever the output
  is shown. A diagram embedded in a customer document is a place where that applies.
- **Where the prompt goes.** For a hosted model, check retention and whether prompts are used
  for training. These skills describe infrastructure: accounts, networks, routes. That is the
  kind of prompt worth keeping out of someone else's training set — which is also an argument
  for a local model, independent of the license.

This repository takes no position on which model to use, and does not track vendor terms —
they change. Treat the list above as the questions to ask, and the answers as something you
confirm at the source each time.
