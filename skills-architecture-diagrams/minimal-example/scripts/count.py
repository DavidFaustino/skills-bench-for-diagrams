#!/usr/bin/env python3
"""Counts lines, words and characters of a text file."""
import sys
from pathlib import Path


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: count.py <file>", file=sys.stderr)
        return 2

    caminho = Path(sys.argv[1])
    if not caminho.is_file():
        print(f"file not found: {caminho}", file=sys.stderr)
        return 1

    texto = caminho.read_text(encoding="utf-8", errors="replace")
    linhas = texto.splitlines()
    maior = max(linhas, key=len, default="")

    print(f"lines:      {len(linhas)}")
    print(f"words:      {len(texto.split())}")
    print(f"characters: {len(texto)}")
    print(f"longest line ({len(maior)} characters): {maior[:80]}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
