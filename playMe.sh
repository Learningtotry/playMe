#!/bin/bash


usage () {
	cat << EOF
Usage: playMe [-h] [-t TIMEVAR]

A song player that will randomly play songs with URLs you list in a list specified in another file.

Options:
	-h		Display this help message and exit
	-t 		Specify the amount of time to play each song
	-n		Specify number of songs to play before closing

Examples:
	playMe
	playMe -t 4m
EOF
	exit 0
}


while getopts "ht:n:" opt; do
	case $opt in
	h) usage ;;
	t)
	regex="^[0-9]{1,3}[smh]$"
	if [[ $OPTARG =~ $regex ]]; then
		timePerSong="$OPTARG"
	else
		echo 'ERROR: "$opt" is an invalid argument for -t parameter'
		echo 'Example: playMe -t 5h'
	fi
	;;
	n)
		if [[ $OPTARG =~ ^[0-9]+$ ]] && [ "$INPUT" -gt 0 ]; then
			numSongs=$OPTARG
		else
			echo "Error, argument to -n must be a positive integer"
			exit 1
		fi
	;;
	esac

: ${numSongs:=-1}
source config.cfg # holds SONG_FILE

counter=0
: ${timePerSong:=5m} # number of minutes to continue playing one song
touch $SONG_FILE
numSongsInList=$(wc -l $SONG_FILE | awk '{print $1}' -)



while true
do
	randomNum=$(( $RANDOM % $numSongsInList + 1 ))
	URL=$(awk -v randomNum="$randomNum" 'NR==randomNum { print $0 }' $SONG_FILE)
	firefox --new-window "$URL" &
	BROWSER_PID=$!
	sleep $timePerSong
	kill $BROWSER_PID
	((counter++))
	if [[ $counter -eq $numSongs ]]; then
		echo "Done"
		exit 0
	fi
done


