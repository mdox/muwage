export song_name=$(basename "$song_source")
export song_dest=$dest/songs/$song_name
export song_source_image=$(find "$song_source" -maxdepth 1 -type f -name 'image.jpg' -o -name 'image.jpeg' -o -name 'image.png')

mkdir -p "$song_dest"

echo Srart Song: "$song_name"

sh ./build_song_cover.sh
sh ./build_song_thumbnails.sh
sh ./build_song_track.sh
sh ./build_song_metadata.sh

echo Ended Song: "$song_name"