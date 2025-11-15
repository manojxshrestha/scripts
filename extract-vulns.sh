#!/bin/bash
# Find all .json files in ~/.gf/ and extract basenames as patterns
patterns=($(ls ~/.gf/*.json | xargs -n1 basename | sed 's/\.json$//'))
for pat in "${patterns[@]}"; do
    output="${pat//_/-}-urls.txt"
    gf "$pat" crawledurls.txt > "$output"
    echo "Extracted $pat to $output ($(wc -l < "$output") hits)"
done
