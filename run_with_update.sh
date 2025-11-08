#!/bin/bash

python3 frontend/scripts/update_conditions_from_sheets.py

if [ $? -eq 0 ]; then
    flutter run "$@"
else
    echo "Failed to update conditions. Aborting."
    exit 1
fi
