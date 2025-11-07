#!/bin/bash
patterns=("debug_logic" "img-traversal" "interestingparams" "jsvar" "rce" "sqli" "ssti" "idor" "interestingEXT" "interestingsubs" "lfi" "redirect" "ssrf" "xss")
for pat in "${patterns[@]}"; do
    output="${pat//_/-}-urls.txt"
    gf "$pat" crawledurls.txt > "$output"
    echo "Extracted $pat to $output ($(wc -l < "$output") hits)"
done
