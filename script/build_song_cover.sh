ffmpeg -loglevel error -hide_banner -nostats \
        -i "$song_source_image" -map_metadata -1 -vf crop=out_w=in_h -q:v 2 "$song_dest/cover.jpg"