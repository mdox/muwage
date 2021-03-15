for song_source in ../assets/songs/*; do
    if [ -d "$song_source" ]; then
        export song_source
        sh ./build_song.sh
    fi
done