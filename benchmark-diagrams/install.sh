#!/usr/bin/env bash
# Installs the compared tools at the exact commits and versions the benchmark ran on.
# Nothing is vendored in this repository: everything is cloned from source.
set -euo pipefail

AQUI="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RAIZ="$(cd "$AQUI/.." && pwd)"
VENDOR="${VENDOR_DIR:-$RAIZ/.vendor}"

# Commits tested on 2026-09-18.
SHA_INFRA_MCP=544a4c5b051d863beaba3cb98d8db4d0cd9a1f5c   # andrewmoshu/diagram-mcp-server
SHA_AWS_MCP=7ddc00aab8a2c1c5514b6fa444b819a074ca8d97     # aws-samples/sample-architecture-diagram-mcp-server
SHA_PUML_MCP=155f1f0f4c7fceeb2bcf590bf84761b6726f6865    # mohammad-emad-dev/diagrams-mcp-server
SHA_DRAWIO_SKILL=7aa92f73819766eb914fffac66762cf2adb5d828 # Agents365-ai/drawio-skill

VER_DIAGRAMS=0.25.1        # Python library
VER_ERASER=0.1.1           # @eraserlabs/diagrams-cli

info()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[!]\033[0m %s\n' "$*"; }

clone_at() { # <url> <destination> <sha>
  local url=$1 dest=$2 sha=$3
  if [ -d "$dest/.git" ]; then
    info "already cloned: $(basename "$dest")"
  else
    info "cloning $(basename "$dest") at $sha"
    git clone -q "$url" "$dest"
  fi
  git -C "$dest" fetch -q --depth 1 origin "$sha" 2>/dev/null || true
  git -C "$dest" checkout -q "$sha"
}

missing() {
  local absent=0
  for bin in "$@"; do
    command -v "$bin" >/dev/null 2>&1 || { warn "missing: $bin"; absent=1; }
  done
  return $absent
}

mkdir -p "$VENDOR"

info "checking prerequisites"
missing git python3 node npm || warn "install what is missing before continuing"
command -v dot    >/dev/null 2>&1 || warn "graphviz missing — tests 01 and 02 will not run (brew install graphviz)"
command -v drawio >/dev/null 2>&1 || warn "draw.io missing — test 05 validates but cannot export an image (brew install --cask drawio)"
command -v uv     >/dev/null 2>&1 || warn "uv missing — used for the Python environments (https://docs.astral.sh/uv/)"

# 01 — diagrams library + Graphviz
info "01: diagrams library $VER_DIAGRAMS"
uv venv --quiet "$VENDOR/venv-diagrams"
uv pip install --quiet --python "$VENDOR/venv-diagrams/bin/python" "diagrams==$VER_DIAGRAMS"

# 02 — infrastructure MCP server
info "02: infrastructure MCP server"
clone_at https://github.com/andrewmoshu/diagram-mcp-server.git "$VENDOR/diagram-mcp-server" "$SHA_INFRA_MCP"
if command -v dot >/dev/null 2>&1; then
  # pygraphviz will not build without the Graphviz headers
  GV_PREFIX="$(brew --prefix graphviz 2>/dev/null || echo /usr)"
  ( cd "$VENDOR/diagram-mcp-server" \
    && CFLAGS="-I$GV_PREFIX/include" LDFLAGS="-L$GV_PREFIX/lib" uv sync --quiet )
fi

# 03 — AWS MCP server
info "03: AWS MCP server"
clone_at https://github.com/aws-samples/sample-architecture-diagram-mcp-server.git "$VENDOR/aws-diagram-mcp" "$SHA_AWS_MCP"
npm install --silent --prefix "$VENDOR/aws-diagram-mcp"
warn "the official AWS icons are not bundled (AWS Terms of Use)."
warn "to get them: download the Asset Package from https://aws.amazon.com/architecture/icons/"
warn "then run scripts/fetch-icons.sh <Asset-Package.zip> inside $VENDOR/aws-diagram-mcp"

# 04 — Eraser CLI
info "04: Eraser CLI $VER_ERASER"
mkdir -p "$VENDOR/eraser"
( cd "$VENDOR/eraser" \
  && [ -f package.json ] || npm init -y >/dev/null )
npm install --silent --prefix "$VENDOR/eraser" "@eraserlabs/diagrams-cli@$VER_ERASER"
warn "Eraser needs a Chromium to render and fetches icons over the network on every render"

# 05 — drawio-skill, the upstream one
info "05: drawio-skill"
clone_at https://github.com/Agents365-ai/drawio-skill.git "$VENDOR/drawio-skill-repo" "$SHA_DRAWIO_SKILL"
warn "the SKILL.md you want lives in $VENDOR/drawio-skill-repo/skills/drawio-skill — not at the repo root"

# extra — PlantUML and Mermaid MCP server, mentioned in the comparison
info "extra: PlantUML and Mermaid MCP server"
clone_at https://github.com/mohammad-emad-dev/diagrams-mcp-server.git "$VENDOR/plantuml-mermaid-mcp" "$SHA_PUML_MCP"
npm install --silent --prefix "$VENDOR/plantuml-mermaid-mcp"
npm run --silent --prefix "$VENDOR/plantuml-mermaid-mcp" build

info "done. the tools are in $VENDOR"
info "to regenerate the five results: benchmark-diagrams/bench.sh"
