import json
import pandas as pd
from pathlib import Path
import logging
import os
from dotenv import load_dotenv

# Get the script's directory
SCRIPT_DIR = Path(__file__).parent.resolve()

# Load environment variables from .env file in the scripts directory
load_dotenv(SCRIPT_DIR / ".env")

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

# ====CONFIG====
SHEET_ID = os.getenv("GOOGLE_SHEET_ID")
if not SHEET_ID:
    raise ValueError("GOOGLE_SHEET_ID environment variable is missing")

SHEET_NAME = "Sheet1"

# Resolve the path to the JSON file relative to the script's location
JSON_PATH = (SCRIPT_DIR.parent / "assets" / "icd10_chronic.json").resolve()

sheet_csv_url = f"https://docs.google.com/spreadsheets/d/{SHEET_ID}/gviz/tq?tqx=out:csv&sheet={SHEET_NAME}"

try:
    df = pd.read_csv(sheet_csv_url)
except Exception as e:
    logging.error(f"Failed to load Google Sheet data: {e}")
    raise

if not {"code", "name", "category", "commonName", "description"}.issubset(df.columns):
    raise ValueError(
        "Your Google Sheet must have columns: code, name, category, commonName, and description"
    )

if JSON_PATH.exists():
    with open(JSON_PATH, "r") as f:
        existing_data = json.load(f)

else:
    existing_data = []

# Create a lookup dictionary for existing data by code
existing_by_code = {item["code"]: item for item in existing_data}

new_entries = []
updated_entries = []
fields_to_compare = ["name", "category", "commonName", "description"]

for _, row in df.iterrows():
    code = str(row["code"]).strip()
    name = str(row["name"]).strip()
    category = str(row["category"]).strip()
    commonName = str(row["commonName"]).strip()
    description = str(row["description"]).strip()

    if not code:
        continue

    sheet_entry = {
        "code": code,
        "name": name,
        "category": category,
        "commonName": commonName,
        "description": description,
    }

    if code not in existing_by_code:
        # New entry
        new_entries.append(sheet_entry)
        existing_by_code[code] = sheet_entry
    else:
        # Check for changes in existing entry
        existing_entry = existing_by_code[code]
        changes = []

        for field in fields_to_compare:
            old_value = existing_entry.get(field, "")
            new_value = sheet_entry[field]

            if old_value != new_value:
                changes.append(f"{field}: '{old_value}' → '{new_value}'")

        if changes:
            # Update the existing entry
            for field in fields_to_compare:
                existing_entry[field] = sheet_entry[field]

            updated_entries.append({
                "code": code,
                "changes": changes
            })

# Rebuild the data list from the lookup dictionary
combined = list(existing_by_code.values())

# Check if there were any changes
has_changes = bool(new_entries) or bool(updated_entries)

if has_changes:
    with open(JSON_PATH, "w") as f:
        json.dump(combined, f, indent=2, ensure_ascii=False)

    if new_entries:
        logging.info(f"✅ Added {len(new_entries)} new conditions")
        for entry in new_entries:
            logging.info(f"   + {entry['code']}: {entry['name']}")

    if updated_entries:
        logging.info(f"✅ Updated {len(updated_entries)} existing conditions")
        for update in updated_entries:
            logging.info(f"   ~ {update['code']}:")
            for change in update['changes']:
                logging.info(f"      {change}")

    logging.info(f"💾 Saved changes to {JSON_PATH}")
else:
    logging.info("No new conditions to add and no changes detected in existing entries.")
