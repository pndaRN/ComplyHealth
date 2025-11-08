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

existing_codes = {item["code"] for item in existing_data}

new_entries = []
for _, row in df.iterrows():
    code = str(row["code"]).strip()
    name = str(row["name"]).strip()
    category = str(row["category"]).strip()
    commonName = str(row["commonName"]).strip()
    description = str(row["description"]).strip()

    if code and code not in existing_codes:
        new_entries.append(
            {
                "code": code,
                "name": name,
                "category": category,
                "commonName": commonName,
                "description": description,
            }
        )
        existing_codes.add(code)

if new_entries:
    combined = existing_data + new_entries
    with open(JSON_PATH, "w") as f:
        json.dump(combined, f, indent=2, ensure_ascii=False)
    logging.info(f"✅ Added {len(new_entries)} new conditions to {JSON_PATH}")
else:
    logging.info("No new conditions to add.")
