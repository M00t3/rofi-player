#!/usr/bin/env bash
SCRIPT_PATH=$(readlink -f "$0")
SCRIPT_DIR=$(dirname "$SCRIPT_PATH")
cd "$SCRIPT_DIR" || exit 2

# load config file
source ./config.conf

selected_playlist=$(sed '/#.*/d;/^$/d' ./playlists_and_musics.csv |
	awk -F',' '{print $1}' |
	rofi -dmenu -i -lines 10 -width 30 -p "Select Music or Playlist: ")

link=$(sed '/#.*/d;/^$/d' ./playlists_and_musics.csv |
	grep "^$selected_playlist," |
	awk -F',' '{print $2}')

is_url_link=$(sed '/#.*/d;/^$/d' ./playlists_and_musics.csv |
	grep "$selected_playlist" |
	awk -F',' '{print $3}')

# Isn't enter in rofi
if [[ ! "$selected_playlist" ]]; then
	exit 2
fi

# play online videos links
if [[ ! "$link" ]]; then
	$terminal -e youtube-viewer -n --no-video-info --player=mpv "${selected_playlist}"
	exit 0
fi

# play saved online yt videos
if [[ "$is_url_link" == 'y' ]]; then
	if [[ "$link" ]]; then
		echo "$link"
		$terminal -e youtube-viewer -n --no-video-info --player=mpv "$link"
		exit 0
	else
		exit 2
	fi

# play with custom bash scritp
elif [[ $selected_playlist == "radios" ]]; then
	script_path=$link
	bash -c "$script_path"
else
	# find music file in selected directory
	files=$(find "$link" -maxdepth 1 -type f -regex '.*mp3\|.*opus')
	echo "this is path"
	echo -e "files : \n$files"
	echo "$files" >/tmp/mpv_playlist.txt

	# play local file in infinite loop
	$terminal -e bash -c "while [[ 1 ]] ;  do  clear;  mpvm --playlist=/tmp/mpv_playlist.txt ;done"
fi
