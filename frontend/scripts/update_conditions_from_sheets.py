import json
import pandas as pd
from pathlib import Path

# ====CONFIG====
SHEET_ID = "1O1Bn2D-ksH5CETZhQ0IL54alOCdB-eOCK-rlOu56uyU"

SHEET_NAME = "Sheet1"

JSON_PATH = Path("../assets/icd10_chronic.json")

sheet_csv_url = f"https://docs.google.com/spreadsheets/d/{SHEET_ID}/gviz/tq?tqx=out:csv&sheet={SHEET_NAME}"
df = pd.read_csv(sheet_csv_url)

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
    print(f"✅ Added {len(new_entries)} new conditions to {JSON_PATH}")
else:
    print("No new conditions to add.")
