#!/bin/bash

# Navigate to project root (one level up from scripts)
cd "$(dirname "$0")/.."

echo "Creating virtual environment in $(pwd)/.venv..."

# Check if python3-venv is installed (common Ubuntu issue)
if ! dpkg -l | grep -q "python3.*-venv"; then
    echo "Error: python3-venv is not installed."
    echo "Run: sudo apt update && sudo apt install python3-venv"
    exit 1
fi

# Create the venv
python3 -m venv .venv

# Upgrade pip and install requirements
source .venv/bin/activate
pip install --upgrade pip
if [ -f "requirements.txt" ]; then
    pip install -r requirements.txt
    echo "Dependencies installed successfully."
else
    echo "requirements.txt not found. Installing Django only..."
    pip install django
fi

echo "Setup complete. Use 'source scripts/start-py-venv.sh' to activate."