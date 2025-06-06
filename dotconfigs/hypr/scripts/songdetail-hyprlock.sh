#!/bin/bash

if command -v playerctl >/dev/null 2>&1 && playerctl status >/dev/null 2>&1; then
    song_info=$(playerctl metadata --format '🎧 {{title}} - {{artist}}' 2>/dev/null)
    
    if [[ -n "$song_info" && "$song_info" != "🎧  - " ]]; then
        echo "$song_info"
    fi
fi
