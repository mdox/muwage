sample=$song_dest/cover.jpg

for size in 512 384 256 192 128 96; do
    thumbnail=$song_dest/thumbnail_$size.jpg
    ffmpeg -loglevel error -hide_banner -nostats \
            -i "$sample" -vf scale=$size:-1 -q:v 2 "$thumbnail"
    sample=$thumbnail
done