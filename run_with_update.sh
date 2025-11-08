#!/bin/bash
set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="$SCRIPT_DIR/frontend/scripts/venv"
REQUIREMENTS_FILE="$SCRIPT_DIR/frontend/scripts/requirements.txt"
UPDATE_SCRIPT="$SCRIPT_DIR/frontend/scripts/update_conditions_from_sheets.py"

echo -e "${BLUE}=== MedSync Pre-Run Update ===${NC}"

# Check if virtual environment exists
if [ ! -d "$VENV_DIR" ]; then
    echo -e "${YELLOW}Virtual environment not found. Creating...${NC}"
    python3 -m venv "$VENV_DIR"

    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to create virtual environment${NC}"
        exit 1
    fi

    echo -e "${GREEN}Virtual environment created successfully${NC}"

    # Install dependencies
    echo -e "${YELLOW}Installing dependencies...${NC}"
    source "$VENV_DIR/bin/activate"
    pip install --upgrade pip > /dev/null 2>&1
    pip install -r "$REQUIREMENTS_FILE"

    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to install dependencies${NC}"
        deactivate
        exit 1
    fi

    echo -e "${GREEN}Dependencies installed successfully${NC}"
else
    # Activate existing virtual environment
    source "$VENV_DIR/bin/activate"
fi

# Check if .env file exists
if [ ! -f "$SCRIPT_DIR/frontend/scripts/.env" ]; then
    echo -e "${YELLOW}Warning: .env file not found at frontend/scripts/.env${NC}"
    echo -e "${YELLOW}Make sure GOOGLE_SHEET_ID is configured${NC}"
fi

# Run the update script
echo -e "${BLUE}Updating conditions from Google Sheets...${NC}"
python "$UPDATE_SCRIPT"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Conditions updated successfully${NC}"
    deactivate

    # Run Flutter
    echo -e "${BLUE}Starting Flutter app...${NC}"
    cd "$SCRIPT_DIR/frontend"
    flutter run "$@"
else
    echo -e "${RED}✗ Failed to update conditions. Aborting.${NC}"
    deactivate
    exit 1
fi
