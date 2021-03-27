set -e

main(){
    if [ -d '/dev/shm' ]; then
        ws="$(mktemp -d -p '/dev/shm')"
    else
        ws="$(mktemp -d)"
    fi

    trap 'rm -rf "$ws"' EXIT

    export dst="$ws/dst"
    export tmp="$ws/tmp"
    mkdir -p "$dst" "$tmp"

    export base="$(realpath "$(dirname "$0")")"
    export assets="$base/assets"
    export source="$base/source"
    export public="$base/public"

    source "$base/info.sh"

    export sort_list="$tmp/sort_list"

    check
    build
    clean
    copy
}

clean(){
    rm -rf "$public"
}

copy(){
    cp -rf "$dst/" "$public"
}

build(){
    export based_keywords="$(cat $assets/keywords)"

    build_sort_list
    build_song_data
    build_page_home
    build_page_song
}

build_page_song(){
    local index=0

    cat "$sort_list" |
    while read song; do
        index=$(($index+1))

        build_page "$(cat "$tmp/songs/$song/inf/title")" "../../" $index "$dst/page/$song" "autoplay" \
            "Dresmor Alakazard's music creations." \
            "music.song" \
            "https://muwage.mdox.xyz/page/$song" \
            "https://muwage.mdox.xyz/songs/$song/cover.jpg"
    done
}

build_page_home(){
    build_page "Music Home" "." 1 "$dst/" ""
}

build_page(){
    local title="$1"
    local url_prefix="$2"
    local song_index="$3"
    local page_dst="$4"
    local autoplay="$5"
    
    local og_description="${6:-"Dresmor Alakazard's music creations."}"
    local og_type="${7:-"website"}"
    local og_path="${8:-"https://muwage.mdox.xyz/"}"
    local og_image="${9:-"https://mdox.xyz/image.png"}"

    ju(){
        echo "$url_prefix/$1" | sed s,//*,/,g
    }

    local selection="$tmp/selection"
    local items="$tmp/items"

    echo "" > "$selection"
    echo "" > "$items"

    local index=0

    cat "$sort_list" |
    while read song; do
        index=$(($index+1))

        if [ "$index" -eq "$song_index" ]; then
            echo "$song" > "$selection"
        fi

        sed \
            -e "s,\$\$item_index,$index,g" \
            -e "s,\$\$item_url,$(ju "page/$song"),g" \
            -e "s,\$\$item_title,$(cat "$tmp/songs/$song/inf/title"),g" \
            -e "s,\$\$item_time,$(cat "$tmp/songs/$song/inf/time"),g" \
            "$source/item.html" >> "$items"
    done

    mkdir -p "$page_dst"

    local song="$(cat $selection)"

    local title_words="$(sed -e 's/\ /,\ /g' "$tmp/songs/$song/inf/title" | tr '[:upper:]' '[:lower:]')"
    local keywords="$based_keywords, $title_words"
    
    sed \
        -e "s#\$\$keywords#$keywords#g" \
        -e "s,\$\$description,$og_description,g" \
        -e "s,\$\$type,$og_type,g" \
        -e "s,\$\$path,$og_path,g" \
        -e "s,\$\$image,$og_image,g" \
        -e "s,\$\$artist,$(cat "$tmp/songs/$song/inf/artist"),g" \
        -e "s,\$\$index,$song_index,g" \
        -e "s,\$\$page_title,$title,g" \
        -e "s,\$\$thumbnail_url,$(ju "songs/$song/thumbnail_384.jpg"),g" \
        -e "s,\$\$cover_url,$(ju "songs/$song/cover.jpg"),g" \
        -e "s,\$\$title,$(cat "$tmp/songs/$song/inf/title"),g" \
        -e "s,\$\$date,$(cat "$tmp/songs/$song/inf/date"),g" \
        -e "s,\$\$track_url,$(ju "songs/$song/track.mp3"),g" \
        -e "s,\$\$autoplay,$autoplay,g" \
        -e "s,\$\$items,$(sed -e 's/,/\\,/g' "$items" | tr '\n' ' '),g" \
        "$source/page.html" >> "$page_dst/index.html"
}

build_song_data(){
    fd=11
    exec 11<"$sort_list"

    while read -u $fd song; do
        export song_src="$assets/songs/$song"
        export song_dst="$dst/songs/$song"
        export song_tmp="$tmp/songs/$song"
        export song_inf="$song_tmp/inf"

        mkdir -p "$song_dst" "$song_tmp" "$song_inf"

        build_song_track
        build_song_cover
        build_song_thumbnails
        build_song_metadata_and_export_info
    done
}

build_song_metadata_and_export_info(){
    local imf="$song_tmp/imf"
    local ama="$song_tmp/ama"

    add_imf(){
        echo "set Xmp.dc.$1 \"$2\"" >> "$imf"
    }

    add_ama(){
        echo "--$1='$2'" >> "$ama"
    }

    echo "$(ffmpeg -i "$song_dst/track.mp3" 2>&1 | grep "Duration" | cut -d ' ' -f 4 | sed s/,// | tr '.' ':' | cut -d ':' -f 2-3)" >> "$song_inf/time"

    read_info "$song_src/info" |
    while read -r info; do
        local name="$(info_name "$info")"
        local value="$(info_value "$info")"

        echo "$value" >> "$song_inf/$name"

        case "$name" in
            title)
                add_imf title "$value"
                add_ama song "$value"
            ;;
            creator)
                add_imf creator "$value"
            ;;
            artist)
                add_ama artist "$value"
            ;;
            year)
                add_ama year "$value"
            ;;
            date)
                add_imf date "$value"
                add_ama date "$value"
            ;;
            source)
                add_imf source "$value"
            ;;
            publisher)
                add_imf publisher "$value"
            ;;
            genre)
                add_ama genre "$value"
            ;;
        esac
    done

    add_ama picture "$song_dst/cover.jpg"
    echo "$song_dst/track.mp3" >> "$ama"
    cat "$ama" | xargs mid3v2

    for image in $(find "$song_dst" -name "*.jpg"); do
        exiv2 -m "$imf" "$image"
    done
}

build_song_thumbnails(){
    local sample="$song_dst/cover.jpg"

    # 512 384 256 192 128 96
    for size in 384; do
        thumbnail="$song_dst/thumbnail_$size.jpg"
        ffmpeg -loglevel error -hide_banner -nostats \
                -i "$sample" -vf scale="$size":-1 -q:v 2 "$thumbnail"
        sample="$thumbnail"
    done
}

build_song_cover(){
    ffmpeg -loglevel error -hide_banner -nostats \
        -i "$song_src/image.jpg" -map_metadata -1 -vf crop=in_w -q:v 2 "$song_dst/cover.jpg"
}

build_song_track(){
    ffmpeg -loglevel error -hide_banner -nostats \
        -i "$song_src/audio.mp3" -map_metadata -1 -c:v copy -c:a copy "$song_dst/track.mp3"
}

build_sort_list(){
    local list="$tmp/list"

    for song in $assets/songs/*; do
        if [ -d "$song" ]; then
            local song_name="$(basename "$song")"
            read_info "$song/info" |
            while read -r info; do
                local name="$(info_name "$info")"
                if [ "$name" == "date" ]; then
                    local value="$(info_value "$info")"
                    echo "$value=$song_name" >> "$list"
                fi
            done
        fi
    done

    sort -r "$list" | grep "$info_pattern" |
    while read -r info; do
        echo "$(info_value "$info")" >> "$sort_list"
    done
}

check(){
    local fail=0

    em(){
        fail=$(($fail+1))
        test -n "$1" && echo "$1" > "/dev/tty"
    }

    for song in $assets/songs/*; do
        if [ -d "$song" ]; then
            test -f "$song/image.jpg" || em "No image file for: $song"
            test -f "$song/audio.mp3" || em "No audio file for: $song"

            if [ -f "$song/info" ]; then
                read_info "$assets/info" |
                while read -r info; do
                    name=$(info_name $info)
                    grep -q "^$name=[[:print:]][[:print:]]*$" "$song/info" || em "Missing info '$name' for: $song"
                done
            else
                em "No info file for: $song"
            fi
        fi
    done

    test -d "$song" || no_song
    test "$fail" -eq 0 || exit 2
}

no_song(){
    echo "No song to use for build."
    exit 1
}

main "$@"