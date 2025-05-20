#!/bin/bash

input="$1"
browser="brave"  # or brave, chromium, etc.

# Simple URL check
if [[ "$input" =~ ^https?:// ]]; then
    $browser "$input" &
elif command -v "$input" &> /dev/null; then
    "$input" &
else
    query=$(echo "$input" | sed 's/ /+/g')
    $browser "https://www.google.com/search?q=$query" &
fi
