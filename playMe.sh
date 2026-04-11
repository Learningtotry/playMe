#!/bin/bash

# 1. Load config and set defaults BEFORE getopts
# This allows the user's flags to OVERRIDE the config file.
if [ -f config.cfg ]; then
    source config.cfg # Should define SONG_FILE
fi


song_time="$DEFAULT_SONG_TIME" # set to default, overriden later
: ${SONG_FILE:="songURLs.txt"}

usage () {
    cat << EOF
Usage: playMe [-h] [-t TIME] [-n COUNT]

A song player that opens random URLs from a list.

Options:
    -h      Display this help message and exit
    -t      Time per song (e.g., 30s, 5m, 1h)
    -n      Number of songs to play before stopping

Examples:
    playMe -t 4m -n 10
EOF
    exit 0
}

# 2. Argument Parsing
while getopts "ht:n:" opt; do
    case $opt in
        h) usage ;;
        t)
            regex="^[0-9]{1,3}[smh]$"
            if [[ $OPTARG =~ $regex ]]; then
                song_time="$OPTARG"
            else
                echo "ERROR: $OPTARG is an invalid time format."
                exit 1
            fi
            ;;
        n)
            if [[ $OPTARG =~ ^[0-9]+$ ]] && [ "$OPTARG" -gt 0 ]; then
                numSongs=$OPTARG
            else
                echo "Error: -n must be a positive integer."
                exit 1
            fi
            ;;
    esac
done

: ${counter:=-1}
shift $((OPTIND -1))

# 3. Setup
if [ ! -s "$SONG_FILE" ]; then
	echo "It seems that $SONG_FILE is empty, please paste some URLs"
	echo "separated by newlines (when you press enter) to add those"
	echo "to your playlist"
	echo "example https://www.youtube.com/watch?v=dQw4w9WgXcQ&list=RDdQw4w9WgXcQ&start_radio=1&pp=ygUIcmlja3JvbGygBwE%3D"
fi
numSongsInList=$(wc -l < "$SONG_FILE")

if [ "$numSongsInList" -eq 0 ]; then
    echo "Error: Your song list ($SONG_FILE) is empty!"
    exit 1
fi

counter=0

mkdir -p /tmp/ff_profile



while true; do
    # Calculate random line number
    randomNum=$(( ($RANDOM % numSongsInList) + 1 ))

    # Get the URL
    URL=$(awk "NR==$randomNum" "$SONG_FILE")

    echo "[$((counter+1))] Playing: $URL"

    # Open Firefox in background
    firefox --new-window "$URL" &
    BROWSER_PID=$!
    # Wait and then kill
    sleep "$song_time"
    kill $BROWSER_PID 2>/dev/null

    ((counter++))

    # Check if we've played enough songs
    if [ "$counter" -eq "$numSongs" ]; then
        echo "Finished playing $numSongs songs."
        exit 0
    fi
done
