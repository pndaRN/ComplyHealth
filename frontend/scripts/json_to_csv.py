#!/usr/bin/env python3
"""
Convert education_content.json to CSV files.

This script reads the education_content.json file and creates three separate CSV files:
- education_articles.csv: Articles for each condition
- education_lifestyle_tips.csv: Lifestyle tips for each condition
- education_videos.csv: Videos for each condition
"""

import json
import csv
import os
from pathlib import Path


def load_json(file_path: str) -> list:
    """Load JSON data from file."""
    with open(file_path, 'r', encoding='utf-8') as f:
        return json.load(f)


def write_articles_csv(data: list, output_path: str) -> None:
    """Write articles to CSV file."""
    with open(output_path, 'w', newline='', encoding='utf-8') as f:
        writer = csv.writer(f)
        writer.writerow(['conditionCode', 'title', 'url', 'source', 'description'])

        for item in data:
            condition_code = item['conditionCode']
            for article in item.get('articles', []):
                writer.writerow([
                    condition_code,
                    article.get('title', ''),
                    article.get('url', ''),
                    article.get('source', ''),
                    article.get('description', '')
                ])


def write_lifestyle_tips_csv(data: list, output_path: str) -> None:
    """Write lifestyle tips to CSV file."""
    with open(output_path, 'w', newline='', encoding='utf-8') as f:
        writer = csv.writer(f)
        writer.writerow(['conditionCode', 'tip'])

        for item in data:
            condition_code = item['conditionCode']
            for tip in item.get('lifestyleTips', []):
                writer.writerow([condition_code, tip])


def write_videos_csv(data: list, output_path: str) -> None:
    """Write videos to CSV file."""
    with open(output_path, 'w', newline='', encoding='utf-8') as f:
        writer = csv.writer(f)
        writer.writerow(['conditionCode', 'title', 'url', 'thumbnail', 'duration'])

        for item in data:
            condition_code = item['conditionCode']
            for video in item.get('videos', []):
                writer.writerow([
                    condition_code,
                    video.get('title', ''),
                    video.get('url', ''),
                    video.get('thumbnail', ''),
                    video.get('duration', '')
                ])


def main():
    """Main function to convert JSON to CSV files."""
    # Determine paths
    script_dir = Path(__file__).parent
    assets_dir = script_dir.parent / 'assets'
    json_file = assets_dir / 'education_content.json'

    # Check if JSON file exists
    if not json_file.exists():
        print(f"Error: {json_file} not found!")
        return

    # Load JSON data
    print(f"Loading data from {json_file}...")
    data = load_json(str(json_file))
    print(f"Loaded {len(data)} condition records")

    # Create output directory if it doesn't exist
    output_dir = script_dir / 'output'
    output_dir.mkdir(exist_ok=True)

    # Write CSV files
    articles_csv = output_dir / 'education_articles.csv'
    lifestyle_csv = output_dir / 'education_lifestyle_tips.csv'
    videos_csv = output_dir / 'education_videos.csv'

    print(f"\nWriting CSV files to {output_dir}...")

    write_articles_csv(data, str(articles_csv))
    print(f"✓ Created {articles_csv}")

    write_lifestyle_tips_csv(data, str(lifestyle_csv))
    print(f"✓ Created {lifestyle_csv}")

    write_videos_csv(data, str(videos_csv))
    print(f"✓ Created {videos_csv}")

    print("\nConversion complete!")


if __name__ == '__main__':
    main()
