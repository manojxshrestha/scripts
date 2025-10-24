#!/bin/bash
# Navigate to the ghauri directory
cd ghauri || { echo "Error: 'ghauri' directory not found."; exit 1; }

# Activate virtual environment
if [[ -f "venv/bin/activate" ]]; then
    source venv/bin/activate
else
    echo "Error: Virtual environment not found. Make sure 'venv' exists inside 'ghauri'."
    exit 1
fi

# Default URL and file
URL=""
FILE=""

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -url=*)
            URL="${1#*=}"
            shift
            ;;
        *)
            echo "Usage: ./gh.sh [-url=<target_url>]"
            echo "If no -url is provided, you will be prompted for single URL or a file of URLs."
            exit 1
            ;;
    esac
done

# Function to prompt for choice
prompt_choice() {
    echo "Choose an option:"
    echo "1) Test a single URL"
    echo "2) Test multiple URLs from a .txt file"
    read -p "Enter 1 or 2: " choice

    case $choice in
        1)
            MODE="single"
            ;;
        2)
            MODE="multiple"
            ;;
        *)
            echo "Invalid choice. Please enter 1 or 2."
            exit 1
            ;;
    esac
}

# If URL provided via arg, use single mode
if [[ -n "$URL" ]]; then
    MODE="single"
else
    prompt_choice
fi

# Handle single URL mode
if [[ "$MODE" == "single" ]]; then
    if [[ -z "$URL" ]]; then
        read -p "Enter the target URL: " URL
        if [[ -z "$URL" ]]; then
            echo "Error: No URL provided."
            exit 1
        fi
    fi
    echo "Running Ghauri on single URL: $URL"
    ghauri -u "$URL" --dbs --level=3 --batch
fi

# Handle multiple URLs mode
if [[ "$MODE" == "multiple" ]]; then
    read -p "Enter the path to the .txt file containing URLs (one per line): " FILE
    if [[ -z "$FILE" ]] || [[ ! -f "$FILE" ]]; then
        echo "Error: File not found or no file provided."
        exit 1
    fi
    if [[ ! "$FILE" =~ \.txt$ ]]; then
        echo "Warning: File does not end with .txt. Proceeding anyway."
    fi
    echo "Running Ghauri on multiple URLs from: $FILE"
    ghauri -m "$FILE" --dbs --level=3 --batch
fi
