ffmpeg -loglevel error -hide_banner -nostats -i "$song_source/audio.mp3" -map_metadata -1 -c:v copy -c:a copy "$song_dest/track.mp3"
# cp "$song_source/audio.mp3" "$song_dest/track.mp3"