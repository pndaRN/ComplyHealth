# Scripts

Python scripts for managing condition data.

## Setup

Create and activate virtual environment:

```bash
# Create venv (one time)
python3 -m venv venv

# Activate venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt
```

## Scripts

### update_conditions_from_sheets.py

Pulls condition data from Google Sheets and updates the ICD-10 JSON file.

**Usage:**
```bash
source venv/bin/activate
python update_conditions_from_sheets.py
```

**Configuration:**
Edit the `SHEET_ID` and `SHEET_NAME` variables in the script to point to your Google Sheet.

**Requirements:**
Your Google Sheet must have these columns:
- `code` - ICD-10 code
- `name` - Full condition name
- `category` - Condition category
- `commonName` - Common name for the condition
- `description` - Condition description

## Deactivating venv

```bash
deactivate
```
