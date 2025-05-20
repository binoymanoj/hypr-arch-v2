#!/bin/bash

# Set battery path - you may need to adjust this path
BATTERY_PATH="/sys/class/power_supply/BAT1"
SOUND="/usr/share/sounds/freedesktop/stereo/message.oga"

# Track when we've shown notifications to avoid repeats
LAST_NOTIFY_LEVEL_LOW=100
LAST_NOTIFY_LEVEL_HIGH=0

# Function to play sound and show notification
notify_with_sound() {
    local urgency=$1
    local title=$2
    local message=$3
    local icon=$4
    local sound_file=$5
    
    # Show notification
    notify-send -u "$urgency" "$title" "$message" -i "$icon"
    
    # Play sound if file exists
    if [ -f "$sound_file" ]; then
        paplay "$sound_file"
    fi
}

while true; do
    # Check if battery exists
    if [ ! -d "$BATTERY_PATH" ]; then
        echo "Battery not found at $BATTERY_PATH"
        exit 1
    fi
    
    # Get battery level and charging status
    BATTERY_LEVEL=$(cat "$BATTERY_PATH/capacity")
    CHARGING_STATUS=$(cat "$BATTERY_PATH/status")
    
    # Handle low battery notifications when discharging
    if [ "$CHARGING_STATUS" = "Discharging" ]; then
        # Check different battery levels and notify accordingly
        if [ "$BATTERY_LEVEL" -le 5 ] && [ "$LAST_NOTIFY_LEVEL_LOW" -gt 5 ]; then
            notify_with_sound "critical" "Battery Critical!" "Battery level is ${BATTERY_LEVEL}% - Connect charger immediately" "battery-empty" "$SOUND"
            LAST_NOTIFY_LEVEL_LOW=5
        elif [ "$BATTERY_LEVEL" -le 15 ] && [ "$LAST_NOTIFY_LEVEL_LOW" -gt 15 ]; then
            notify_with_sound "critical" "Battery Very Low!" "Battery level is ${BATTERY_LEVEL}% - Connect charger soon" "battery-caution" "$SOUND"
            LAST_NOTIFY_LEVEL_LOW=15
        elif [ "$BATTERY_LEVEL" -le 20 ] && [ "$LAST_NOTIFY_LEVEL_LOW" -gt 20 ]; then
            notify_with_sound "normal" "Battery Low" "Battery level is ${BATTERY_LEVEL}%" "battery-low" "$SOUND"
            LAST_NOTIFY_LEVEL_LOW=20
        fi
        
        # Reset high level notification tracker when discharging
        LAST_NOTIFY_LEVEL_HIGH=0
    
    # Handle high battery notifications when charging
    elif [ "$CHARGING_STATUS" = "Charging" ]; then
        # Check for high battery levels while charging
        if [ "$BATTERY_LEVEL" -ge 100 ] && [ "$LAST_NOTIFY_LEVEL_HIGH" -lt 100 ]; then
            notify_with_sound "normal" "Battery Fully Charged" "Battery level is 100% - You can unplug the charger" "battery-full-charged" "$SOUND"
            LAST_NOTIFY_LEVEL_HIGH=100
        elif [ "$BATTERY_LEVEL" -ge 95 ] && [ "$LAST_NOTIFY_LEVEL_HIGH" -lt 95 ]; then
            notify_with_sound "normal" "Battery Almost Charged" "Battery level is ${BATTERY_LEVEL}%" "battery-full-charging" "$SOUND"
            LAST_NOTIFY_LEVEL_HIGH=95
        elif [ "$BATTERY_LEVEL" -ge 90 ] && [ "$LAST_NOTIFY_LEVEL_HIGH" -lt 90 ]; then
            notify_with_sound "low" "Battery Charging" "Battery level is ${BATTERY_LEVEL}%" "battery-good-charging" "$SOUND"
            LAST_NOTIFY_LEVEL_HIGH=90
        fi
        
        # Reset low level notification tracker when charging
        LAST_NOTIFY_LEVEL_LOW=100
    
    # Handle full battery status
    elif [ "$CHARGING_STATUS" = "Full" ]; then
        if [ "$LAST_NOTIFY_LEVEL_HIGH" -lt 101 ]; then
            notify_with_sound "normal" "Battery Fully Charged" "Battery is fully charged and connected to power" "battery-full-charged" "$SOUND"
            LAST_NOTIFY_LEVEL_HIGH=101  # Special value to track full notification
        fi
    fi
    
    # Sleep for 60 seconds before checking again
    sleep 60
done
