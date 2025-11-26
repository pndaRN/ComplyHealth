import json
import pandas as pd
from pathlib import Path
import logging
import os
from dotenv import load_dotenv
from collections import defaultdict

# Get the script's directory
SCRIPT_DIR = Path(__file__).parent.resolve()

# Load environment variables from .env file in the scripts directory
load_dotenv(SCRIPT_DIR / ".env")

# Configure logging
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s"
)

# ====CONFIG====
SHEET_ID = os.getenv("GOOGLE_SHEET_ID")
if not SHEET_ID:
    raise ValueError("GOOGLE_SHEET_ID environment variable is missing")

# Resolve the paths to the JSON files relative to the script's location
CONDITIONS_JSON_PATH = (SCRIPT_DIR.parent / "assets" / "icd10_chronic.json").resolve()
EDUCATION_JSON_PATH = (SCRIPT_DIR.parent / "assets" / "education_content.json").resolve()

# ====PROCESS CONDITIONS====
logging.info("Processing Conditions sheet...")
SHEET_NAME = "Conditions"
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

if CONDITIONS_JSON_PATH.exists():
    with open(CONDITIONS_JSON_PATH, "r") as f:
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

            updated_entries.append({"code": code, "changes": changes})

# Rebuild the data list from the lookup dictionary
combined = list(existing_by_code.values())

# Check if there were any changes
has_changes = bool(new_entries) or bool(updated_entries)

if has_changes:
    with open(CONDITIONS_JSON_PATH, "w") as f:
        json.dump(combined, f, indent=2, ensure_ascii=False)

    if new_entries:
        logging.info(f"✅ Added {len(new_entries)} new conditions")
        for entry in new_entries:
            logging.info(f"   + {entry['code']}: {entry['name']}")

    if updated_entries:
        logging.info(f"✅ Updated {len(updated_entries)} existing conditions")
        for update in updated_entries:
            logging.info(f"   ~ {update['code']}:")
            for change in update["changes"]:
                logging.info(f"      {change}")

    logging.info(f"💾 Saved changes to {CONDITIONS_JSON_PATH}")
else:
    logging.info(
        "No new conditions to add and no changes detected in existing entries."
    )

# ====PROCESS EDUCATION DATA====
logging.info("\nProcessing Education sheets...")

# Load existing education data
if EDUCATION_JSON_PATH.exists():
    with open(EDUCATION_JSON_PATH, "r") as f:
        existing_education = json.load(f)
else:
    existing_education = []

# Create a lookup dictionary by conditionCode
existing_education_by_code = {item["conditionCode"]: item for item in existing_education}

# Process education_videos sheet
logging.info("Loading education_videos sheet...")
videos_url = f"https://docs.google.com/spreadsheets/d/{SHEET_ID}/gviz/tq?tqx=out:csv&sheet=education_videos"
try:
    videos_df = pd.read_csv(videos_url)
    if not {"conditionCode", "title", "url", "thumbnail", "duration"}.issubset(videos_df.columns):
        raise ValueError("education_videos sheet must have columns: conditionCode, title, url, thumbnail, duration")
except Exception as e:
    logging.error(f"Failed to load education_videos sheet: {e}")
    videos_df = pd.DataFrame()

# Process education_lifestyle_tips sheet
logging.info("Loading education_lifestyle_tips sheet...")
tips_url = f"https://docs.google.com/spreadsheets/d/{SHEET_ID}/gviz/tq?tqx=out:csv&sheet=education_lifestyle_tips"
try:
    tips_df = pd.read_csv(tips_url)
    if not {"conditionCode", "tip"}.issubset(tips_df.columns):
        raise ValueError("education_lifestyle_tips sheet must have columns: conditionCode, tip")
except Exception as e:
    logging.error(f"Failed to load education_lifestyle_tips sheet: {e}")
    tips_df = pd.DataFrame()

# Process education_articles sheet
logging.info("Loading education_articles sheet...")
articles_url = f"https://docs.google.com/spreadsheets/d/{SHEET_ID}/gviz/tq?tqx=out:csv&sheet=education_articles"
try:
    articles_df = pd.read_csv(articles_url)
    if not {"conditionCode", "title", "url", "source", "description"}.issubset(articles_df.columns):
        raise ValueError("education_articles sheet must have columns: conditionCode, title, url, source, description")
except Exception as e:
    logging.error(f"Failed to load education_articles sheet: {e}")
    articles_df = pd.DataFrame()

# Group education data by conditionCode
education_by_code = defaultdict(lambda: {"videos": [], "lifestyleTips": [], "articles": []})

# Process videos
for _, row in videos_df.iterrows():
    code = str(row["conditionCode"]).strip()
    if not code or pd.isna(row["conditionCode"]):
        continue

    video = {
        "title": str(row["title"]).strip(),
        "url": str(row["url"]).strip(),
        "thumbnail": None if pd.isna(row["thumbnail"]) else str(row["thumbnail"]).strip(),
        "duration": str(row["duration"]).strip()
    }
    education_by_code[code]["videos"].append(video)

# Process lifestyle tips
for _, row in tips_df.iterrows():
    code = str(row["conditionCode"]).strip()
    if not code or pd.isna(row["conditionCode"]):
        continue

    tip = str(row["tip"]).strip()
    if tip:
        education_by_code[code]["lifestyleTips"].append(tip)

# Process articles
for _, row in articles_df.iterrows():
    code = str(row["conditionCode"]).strip()
    if not code or pd.isna(row["conditionCode"]):
        continue

    article = {
        "title": str(row["title"]).strip(),
        "url": str(row["url"]).strip(),
        "source": str(row["source"]).strip(),
        "description": str(row["description"]).strip()
    }
    education_by_code[code]["articles"].append(article)

# Merge with existing education data
education_new_entries = []
education_updated_entries = []

for code, content in education_by_code.items():
    entry = {
        "conditionCode": code,
        "articles": content["articles"],
        "lifestyleTips": content["lifestyleTips"],
        "videos": content["videos"]
    }

    if code not in existing_education_by_code:
        # New condition
        education_new_entries.append(code)
        existing_education_by_code[code] = entry
    else:
        # Check for changes
        existing_entry = existing_education_by_code[code]
        changes = []

        # Compare videos
        if existing_entry.get("videos", []) != entry["videos"]:
            changes.append("videos")

        # Compare lifestyleTips
        if existing_entry.get("lifestyleTips", []) != entry["lifestyleTips"]:
            changes.append("lifestyleTips")

        # Compare articles
        if existing_entry.get("articles", []) != entry["articles"]:
            changes.append("articles")

        if changes:
            existing_entry["videos"] = entry["videos"]
            existing_entry["lifestyleTips"] = entry["lifestyleTips"]
            existing_entry["articles"] = entry["articles"]
            education_updated_entries.append({"code": code, "sections": changes})

# Rebuild the education data list
education_combined = list(existing_education_by_code.values())

# Check if there were any changes
education_has_changes = bool(education_new_entries) or bool(education_updated_entries)

if education_has_changes:
    with open(EDUCATION_JSON_PATH, "w") as f:
        json.dump(education_combined, f, indent=2, ensure_ascii=False)

    if education_new_entries:
        logging.info(f"✅ Added {len(education_new_entries)} new education entries")
        for code in education_new_entries:
            logging.info(f"   + {code}")

    if education_updated_entries:
        logging.info(f"✅ Updated {len(education_updated_entries)} existing education entries")
        for update in education_updated_entries:
            logging.info(f"   ~ {update['code']}: {', '.join(update['sections'])}")

    logging.info(f"💾 Saved changes to {EDUCATION_JSON_PATH}")
else:
    logging.info("No new education entries to add and no changes detected in existing entries.")

logging.info("\n✨ Script completed successfully!")
