#!/bin/bash

# This script must be SOURCED, not executed directly.
# Usage: source scripts/start-py-venv.sh

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [ -f "$PROJECT_ROOT/.venv/bin/activate" ]; then
    source "$PROJECT_ROOT/.venv/bin/activate"
    echo "Virtual environment activated: $(python --version)"
else
    echo "Error: Virtual environment not found. Run 'bash scripts/create-py-venv.sh' first."
fi