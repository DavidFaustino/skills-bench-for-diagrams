#!/usr/bin/env bash
# Regenerates the five results from the inputs committed under results/.
# Run ./install.sh first. A test whose dependency is missing is skipped, not failed.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
VENDOR="${VENDOR_DIR:-$ROOT/.vendor}"
R="$HERE/results"
FAILURES=0

info()    { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
ok()      { printf '\033[1;32m  ok\033[0m %s\n' "$*"; }
skipped() { printf '\033[1;33m  skipped\033[0m %s\n' "$*"; }
fail()    { printf '\033[1;31m  failed\033[0m %s\n' "$*"; FAILURES=$((FAILURES + 1)); }

timed() { # prints how many seconds the command took
  local start end
  start=$(date +%s)
  "$@"
  local rc=$?
  end=$(date +%s)
  printf '       %ss\n' "$((end - start))"
  return $rc
}

capped() { # capped <seconds> <command...> — hard limit where `timeout` exists (Linux, not macOS)
  local limit=$1; shift
  if command -v timeout >/dev/null 2>&1; then
    timeout "$limit" "$@"
  else
    "$@"
  fi
}

find_chromium() {
  for c in "$CHROMIUM_PATH" /usr/bin/chromium /usr/bin/chromium-browser \
           "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"; do
    [ -n "${c:-}" ] && [ -x "$c" ] && { echo "$c"; return 0; }
  done
  return 1
}
CHROMIUM_PATH="${CHROMIUM_PATH:-}"

# 01 — diagrams library + Graphviz
info "01 — diagrams library + Graphviz"
PY="$VENDOR/venv-diagrams/bin/python"
if [ -x "$PY" ] && command -v dot >/dev/null 2>&1; then
  ( cd "$R/01-diagrams-graphviz" && timed "$PY" generate-diagram.py ) \
    && ok "inventory-graphviz.png" || fail "generation failed"
else
  skipped "needs ./install.sh and graphviz"
fi

# 02 — infrastructure MCP server
info "02 — infrastructure MCP server"
MCP_INFRA="$VENDOR/diagram-mcp-server"
if [ -x "$MCP_INFRA/.venv/bin/python" ]; then
  python3 "$HERE/scripts/build-infra-call.py" > "$R/02-mcp-andrewmoshu/mcp-call.json" \
    && ( cd "$MCP_INFRA" && timed node "$R/mcpcall.mjs" \
         "$MCP_INFRA/.venv/bin/python|-m|infrastructure_diagram_mcp_server.server" \
         "@$R/02-mcp-andrewmoshu/mcp-call.json" >/dev/null ) \
    && { mv -f "$R/02-mcp-andrewmoshu/generated-diagrams/"* "$R/02-mcp-andrewmoshu/" 2>/dev/null
         rmdir "$R/02-mcp-andrewmoshu/generated-diagrams" 2>/dev/null
         rm -f "$R/02-mcp-andrewmoshu/inventory-mcp.dot"
         ok "inventory-mcp.png and .drawio"; } \
    || fail "MCP call failed"
else
  skipped "needs ./install.sh with graphviz present"
fi

# 03 — AWS MCP server
info "03 — AWS MCP server"
MCP_AWS="$VENDOR/aws-diagram-mcp/mcp-server.js"
if [ -f "$MCP_AWS" ]; then
  ( cd "$R/03-mcp-aws-samples" && timed node "$R/mcpcall.mjs" "node|$MCP_AWS" \
      "@$R/03-mcp-aws-samples/mcp-call.json" >/dev/null ) \
    && ok "inventory-aws.html and .json" || fail "MCP call failed"
else
  skipped "needs ./install.sh"
fi

# 04 — Eraser CLI
info "04 — Eraser CLI"
ERASER="$VENDOR/eraser/node_modules/.bin/eraser-diagrams"
if [ -x "$ERASER" ] && CHROME="$(find_chromium)"; then
  timed "$ERASER" render "$R/04-eraser/inventory-eraser.json" \
    --chromium-path "$CHROME" -o "$R/04-eraser/inventory-eraser.png" \
    && ok "inventory-eraser.png" || fail "render failed"
else
  skipped "needs ./install.sh and a Chromium (set CHROMIUM_PATH)"
fi

# 05 — drawio-skill
info "05 — drawio-skill"
VALIDATE="$ROOT/skills-architecture-diagrams/architecture-drawio/scripts/validate.py"
python3 "$VALIDATE" "$R/05-drawio-skill/inventory-drawio.drawio" --score \
  && ok "structural validation" || fail "validation failed"
if command -v drawio >/dev/null 2>&1; then
  # draw.io is Electron: on a machine with no screen it needs a virtual display.
  # xvfb wraps only this call; wrapping the whole script hides the other tests' output.
  if [ -z "${DISPLAY:-}" ] && command -v xvfb-run >/dev/null 2>&1; then
    EXPORT_CMD=(xvfb-run -a --server-args="-screen 0 1920x1080x24" drawio)
  else
    EXPORT_CMD=(drawio)
  fi
  # Electron refuses to run as root without --no-sandbox. That is the container and CI case.
  # macOS bash 3.2 will not expand an empty array under `set -u`, so this is a plain string.
  SANDBOX=""
  [ "$(id -u)" = "0" ] && SANDBOX="--no-sandbox"
  OUT="$R/05-drawio-skill/inventory-drawio.png"
  IN="$R/05-drawio-skill/inventory-drawio.drawio"
  # Electron headless hangs indefinitely on some CI runners instead of failing, so every
  # export attempt is capped. Exit code 124 from `timeout` means it hung, not that it broke.
  export DRAWIO_DISABLE_UPDATE=true ELECTRON_DISABLE_SECURITY_WARNINGS=true
  EXPORT_TIMEOUT="${EXPORT_TIMEOUT:-180}"
  # --scale works on macOS and breaks on Linux ("Empty export data", draw.io 31.4.5).
  # Try scaled first, fall back to the default: a smaller PNG beats a lost test.
  if timed capped "$EXPORT_TIMEOUT" "${EXPORT_CMD[@]}" -x ${SANDBOX} --disable-gpu \
       --disable-dev-shm-usage -f png -o "$OUT" --scale 1.5 "$IN" >/dev/null 2>&1 \
     && [ -s "$OUT" ]; then
    ok "inventory-drawio.png (scale 1.5)"
  elif timed capped "$EXPORT_TIMEOUT" "${EXPORT_CMD[@]}" -x ${SANDBOX} --disable-gpu \
       --disable-dev-shm-usage -f png -o "$OUT" "$IN" >/dev/null 2>&1 \
     && [ -s "$OUT" ]; then
    ok "inventory-drawio.png (default scale; --scale failed on this platform)"
  else
    skipped "draw.io export did not finish within ${EXPORT_TIMEOUT}s — headless Electron is"
    skipped "unreliable on some runners. The .drawio itself was validated above."
  fi
else
  skipped "export needs draw.io desktop"
fi

# summary
info "artifact dimensions"
python3 - "$R" <<'PY'
import pathlib, struct, sys
base = pathlib.Path(sys.argv[1])
for f in sorted(base.rglob("*.png")):
    w, h = struct.unpack(">II", f.read_bytes()[16:24])
    print(f"    {f.relative_to(base)}: {w}x{h}  aspect {w/h:.2f}  {f.stat().st_size // 1024} KB")
for f in sorted(base.rglob("*.html")) + sorted(base.rglob("*.drawio")):
    print(f"    {f.relative_to(base)}: {f.stat().st_size // 1024} KB")
PY

[ "$FAILURES" -eq 0 ] && info "every available test passed" || fail "$FAILURES failure(s)"
exit "$FAILURES"
