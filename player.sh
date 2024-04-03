#!/usr/bin/env bash

SCRIPT_PATH=$(readlink -f "$0")
SCRIPT_DIR=$(dirname "$SCRIPT_PATH")
cd "$SCRIPT_DIR" || exit 2

# load config file
source ./config.conf

add_item() {
	name=$(rofi -dmenu -lines 1 -p 'name: ')
	if [[ ! $name ]]; then
		echo "you must enter name for your item"
		exit 2
	fi

	choises="yes\nno"
	is_url=$(printf "$choises" | rofi -dmenu -i -matching fuzzy -lines 10 -width 50 -p 'is this url?: ')
	if [[ ! $is_url ]]; then
		echo "you must answer to Question"
		exit 3
	fi
	if [[ $is_url == "yes" ]]; then
		url=$(rofi -dmenu -lines 1 -p 'Enter url: ')
		echo "${name},$url,y" >>./playlists_and_musics.csv
	else
		file=$(rofi -dmenu -lines 1 -p 'Enter filename: ')
		echo "${name},$file,n" >>./playlists_and_musics.csv
	fi

}

find_item() {
	item_name=$1
	link=$(sed '/#.*/d;/^$/d' ./playlists_and_musics.csv |
		grep "^$item_name," |
		awk -F',' '{print $2}')

	is_url_link=$(sed '/#.*/d;/^$/d' ./playlists_and_musics.csv |
		grep "$item_name" |
		awk -F',' '{print $3}')
	echo "$link $is_url_link"
}

play_item() {

	selected_playlist=$(sed '/#.*/d;/^$/d' ./playlists_and_musics.csv |
		awk -F',' '{print $1}' |
		rofi -dmenu -i -lines 10 -width 30 -p "Select Music or Playlist: ")

	# Isn't enter in rofi
	if [[ ! "$selected_playlist" ]]; then
		exit 2
	fi

	link=$(find_item "$selected_playlist" | cut -d' ' -f1)
	is_url_link=$(find_item "$selected_playlist" | cut -d' ' -f2)

	# play online videos links
	if [[ ! "$link" ]]; then
		$terminal_cmd youtube-viewer -n --no-video-info --player=mpv "${selected_playlist}"
		exit 0
	fi

	# play saved online yt videos
	if [[ "$is_url_link" == 'y' ]]; then
		if [[ "$link" ]]; then
			echo "$link"
			$terminal_cmd youtube-viewer -n --no-video-info --player=mpv "$link"
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
		files=$(find "$files_dir/$link" -maxdepth 1 -type f -regex '.*mp3\|.*opus')
		if [[ ! $files ]]; then
			echo "can not find files"
			exit
		fi
		echo -e "files : \n$files"
		echo -e "$files" >/tmp/mpv_playlist.txt

		# play local file in infinite loop
		$terminal_cmd bash -c "while [[ 1 ]] ;  do  clear;  mpvm --playlist=/tmp/mpv_playlist.txt ;done"
	fi
}

show_help() {
	file_name=$(realpath "$0" | awk -F '/' '{printf $NF}')
	cat <<EOF

  Usage:

     $file_name {flag}


  Flags:

    -a, --add 
        add item

    -p, --play
        play item

    -h, --help
        help

    -s, --show-config
        show config with editor
EOF
}

if [[ ! $1 ]]; then
	play_item
fi

options=$(getopt -o hadps --long add,delete,play,show-config -- "$@" 2>/dev/null)
[ $? -eq 0 ] || {
	echo "Incorrect options provided"
	exit 1
}
eval set -- "$options"
while true; do
	case "$1" in
	-a | --add)
		add_item
		;;
	-p | --play)
		play_item
		;;
	-h | --help)
		show_help
		;;
	-s | --show-config)
		$read_config_editor ./config.conf
		;;
	--)
		shift
		break
		;;
	esac
	shift
done

# get item
# -a | --add)
# 	shift
# 	echo "$1"
#   ;;
