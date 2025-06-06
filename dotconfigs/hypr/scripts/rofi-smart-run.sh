#!/bin/bash

input="$1"
browser="brave"  # or brave, chromium, etc.

if [[ "$input" =~ ^https?:// ]]; then
    $browser "$input" &
elif [[ "$input" =~ \.[a-zA-Z]{2,}(/|$) ]]; then 
    # if search params contains .com or .in or any extension to it, it'll directly open as link instead of searching it as word
    $browser "https://$input" &
elif [[ "$input" =~ ^localhost:[0-9]+(/.*)?$ ]]; then
    # if search params contains localhost,  it'll directly open as link instead of searching it as word
    $browser "http://$input" &
elif command -v "$input" &> /dev/null; then
    "$input" &
else
    query=$(echo "$input" | sed 's/ /+/g')
    $browser "https://www.google.com/search?q=$query" &
fi
