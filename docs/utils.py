from __future__ import annotations

from pathlib import Path


def root_dir() -> Path:
    """Return path to root directory."""
    return Path(__file__).parent.parent
