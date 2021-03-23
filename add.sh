base="$(realpath "$(dirname "$0")")"
assets="$base/assets"

source "$base/info.sh"

src="$(readlink -f "${1:-"$PWD"}")"
dst="$(readlink -f "${2:-"$assets/songs"}")"

default_name="$(basename "$src")"

while [ -z "$name_id" ]; do
    read -e -p "name-id (default: '$default_name'): " in_name_id
    name_id="${in_name_id:-"$default_name"}"
done

default_image="$(find "$src" -maxdepth 1 -type f -name 'image.jpg' -o -name 'cover.jpg' -o -name 'cover.png' | head -n 1)"

if [ ! -f "$default_image" ]; then
    default_image="$(find "$src" -maxdepth 1 -type f -name '*.jpg' -o -name '*.png' | head -n 1)"
fi

while [ -z "$image" ]; do
    if test -f "$default_image"
    then read -e -p "image (default: $(basename "$default_image")): " in_image
    else read -e -p "image: " in_image
    fi
    test -z "$in_image" && in_image="$default_image"
    test -f "$in_image" && image="$in_image"
done

default_audio="$(find "$src" -maxdepth 1 -type f -name 'audio.mp3' -o -name 'cover.mp3' -o -name '*.mp3' | head -n 1)"

while [ -z "$audio" ]; do
    if test -f "$default_audio"
    then read -e -p "audio (default: $(basename "$default_audio")): " in_audio
    else read -e -p "audio: " in_audio
    fi
    test -z "$in_audio" && in_audio="$default_audio"
    test -f "$in_audio" && audio="$in_audio"
done

info_feed=""

capitalizeFirstChar(){
    local string="$1"
    local prefix="$2"
 
    first_char=${string:0:1}
        first_char=$(echo "${first_char}" | tr '[:lower:]' '[:upper:]')
        
    right_side=${string:1}
 
    echo -n "$prefix${first_char}${right_side}"
}

capitalizeArgs(){
    local prefix=""
    for arg in "${@}"; do
        capitalizeFirstChar "${arg}" "$prefix"
        prefix=" "
    done
}

while read -r info; do
    name="$(info_name "$info")"

    if [ "$name" == "year" ]; then
        continue
    fi

    default_value="$(info_value "$info")"

    unset in_value

    if [ -z "$default_value" ]; then
        if [ "$name" == "date" ]; then
            default_value="$(mid3v2 -l "$audio" | grep -o '^TDRC=[[:digit:]-]*$' | cut -d= -f2-)"
        elif [ "$name" == "title" ]; then
            parts="$(capitalizeArgs $(echo "$name_id" | tr '-' ' '))"
            default_value=""

            for part in $parts; do
                for r in and or om to with the a an of NOPE; do
                    if [ "$(echo "$part" | tr '[:upper:]' '[:lower:]')" == "$r" ]; then
                        break
                    fi
                done

                if [ "$r" != "NOPE" ] && [ -n "$default_value" ]; then
                    part="$r"
                fi

                if [ -z "$default_value" ]; then
                    default_value="$part"
                else
                    default_value="$default_value $part"
                fi
            done
        fi
    fi

    while [ -z "$in_value" ]; do
        if [ -n "$default_value" ]; then
            text="$name (default: $default_value): "
        elif [ "$name" == "date" ]; then
            text="$name (format: YYYY-MM-DD): "
        else
            text="$name: "
        fi

        read -e -p "$text" in_value < "/dev/tty"

        in_value=${in_value:-"$default_value"}

        if [ "$name" == "date" ]; then
            date "+%Y-%m-%d" -d "$in_value" > /dev/null 2>&1

            if [ "$?" -eq 0 ]; then
                date="$in_value"
                year="$(echo "$in_value" | cut -d- -f-1)"
                info_feed="$info_feed"$'\n'"year=$year"
            fi
        fi
    done

    if [ -z "$info_feed" ]; then
        info_feed="$name=$in_value"
    else
        info_feed="$info_feed"$'\n'"$name=$in_value"
    fi
done < "$assets/info"

song_dst="$dst/$name_id"

if [ -d "$song_dst" ]; then
    while [ "$override" != "y" ]; do
        read -r -p "Override already existing song? [Y/n]: " in_override

        override="$(echo "${in_override:-y}" | tr '[:upper:]' '[:lower:]')"

        if [ "$override" == "n" ]; then
            exit
        fi
    done
else
    mkdir -p "$song_dst"
fi

cp "$audio" "$song_dst/audio.mp3"
cp "$image" "$song_dst/image.jpg"
echo "$info_feed" > "$song_dst/info"