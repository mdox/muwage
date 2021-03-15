# Metadata for Image
exif_file=`mktemp -p "$song_dest"`

grep = "$song_source/image.properties" | while read pair; do
    key=`echo $pair | cut -d '=' -f1`
    value=`echo $pair | cut -d '=' -f2`
    echo "set Xmp.dc.$key $value" >> "$exif_file"
done

if [ -s "$exif_file" ]; then
    for image in $(find "$song_dest" -name "*.jpg"); do
        if [ -f "$image" ]; then
            exiv2 -m "$exif_file" "$image"
        fi
    done
fi

rm -f "$exif_file"

# Metadata for Audio ('track')
track=$song_dest/track.mp3

# id3v2 -D "$track" >/dev/null

grep = "$song_source/audio.properties" | while read pair; do
    key=`echo $pair | cut -d '=' -f1`
    value=`echo $pair | cut -d '=' -f2`
    id3v2 --$key "$value" "$track"
done