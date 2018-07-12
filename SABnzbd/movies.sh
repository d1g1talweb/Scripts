#!/bin/sh

# SABnzbd output parameters
DIR=$1
NZB_FILE=$2
NAME=$3
NZB_ID=$4
CATEGORY=$5
GROUP=$6
STATUS=$7

# Folder parameters
VIDEOS="/mnt/videos"

    cd "$DIR" 
    
	if [ -f *CD1.avi ]
		then
		cd /home/sicksab/Downloads/temp
		for i in *CD1.avi; do
		MOVIE="`echo $i | sed 's/ CD1//'`"
                mencoder -forceidx -ovc copy -oac copy *CD1.avi *CD2.avi -o "$MOVIE"
		cp "$MOVIE" "$VIDEOS" && rm "$MOVIE"
		rm -R *
		done
	else
		cd /home/sicksab/Downloads/temp
		for movie in *.*; do
		MOVIE="${movie##*/}"
		cp "$MOVIE" "$VIDEOS" && rm "$MOVIE"
		rm -R *
		done
	fi
		clear
		echo
		echo Movie Added to Library! - "$MOVIE"

