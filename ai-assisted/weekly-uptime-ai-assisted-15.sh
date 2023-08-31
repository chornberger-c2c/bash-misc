#!/bin/bash

# Initialize variables to hold total uptime
total_hours=0
total_minutes=0

# Define an array of abbreviated day names, starting with Mon
days=("Mon" "Tue" "Wed" "Thu" "Fri" "Sat" "Sun")

# Get the current day of the week (1 for Monday, 7 for Sunday)
current_day=$(date +%u)

# Calculate the day offset to start from last Monday
offset=$((current_day - 1))

# Calculate the index for last Monday in the array
last_monday_index=$(( (current_day - 1 + 7 - offset) % 7 ))
last_monday_name=${days[$last_monday_index]}

# Loop through each day of the week starting from last Monday (day 1)
for day in {0..4}; do
    # Calculate the index for the day name in the array
    day_index=$(( (last_monday_index + day) % 7 ))
    target_day_name=${days[$day_index]}

    # If the day is in the future or today, use "uptime -p" for uptime
    if [ "$day" -ge "$offset" ]; then
        today_uptime=$(uptime -p)
        if [[ "$today_uptime" =~ up\ ([0-9]+)\ hours,\ ([0-9]+)\ minutes ]]; then
            today_uptime_hours="${BASH_REMATCH[1]}"
            today_uptime_minutes="${BASH_REMATCH[2]}"
        else
            today_uptime_hours="0"
            today_uptime_minutes="0"
        fi
    else
        today_uptime_hours="0"
        today_uptime_minutes="0"
    fi

    # Calculate uptime for the current day using the last command
    if [ "$day" -eq 0 ]; then
        uptime_output=$(uptime -p)
    else
        uptime_output=$(last -xF | grep "^reboot.*$target_day_name" | awk '{gsub("[()]", "", $16); print $16}')
    fi

    if [[ "$uptime_output" =~ ([0-9]+):([0-9]+) ]]; then
        uptime_hours="${BASH_REMATCH[1]}"
        uptime_minutes="${BASH_REMATCH[2]}"
    else
        uptime_hours="0"
        uptime_minutes="0"
    fi

    # Remove leading zeros from hours and minutes for calculations
    uptime_hours=$(echo "$uptime_hours" | sed 's/^0//')
    uptime_minutes=$(echo "$uptime_minutes" | sed 's/^0//')
    today_uptime_hours=$(echo "$today_uptime_hours" | sed 's/^0//')
    today_uptime_minutes=$(echo "$today_uptime_minutes" | sed 's/^0//')

    # Calculate total uptime for the week (excluding future and today)
    if [ "$day" -ge "$offset" ]; then
        total_hours=$((total_hours + uptime_hours + today_uptime_hours))
        total_minutes=$((total_minutes + uptime_minutes + today_uptime_minutes))
    fi

    # Print the uptime for the current day
    printf "Day %s Uptime: %02d:%02d\n" "$target_day_name" "$uptime_hours" "$uptime_minutes"
done

# Calculate extra hours from excess minutes
extra_hours=$((total_minutes / 60))
total_hours=$((total_hours + extra_hours))
total_minutes=$((total_minutes % 60))

# Print the total uptime for the week so far
printf "Total Week Uptime: %02d:%02d\n" "$total_hours" "$total_minutes"

