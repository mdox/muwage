# Data
Song Directory:
- assets/songs/&lt;song-id&gt;

Song Files:
- audio.mp3
- audio.properties
- image.jpg (or *.png)
- image.properties
- keywords (optional)

Song "*.properties"
- key-value pairs
- related to files metadata
- for image: [Xmp.dc](https://exiftool.org/TagNames/XMP.html#dc)
- for audio: [ID3](https://en.wikipedia.org/wiki/ID3)
    - 'song' instead of title
    - supporting only: song (title), artist, year, genre

# Dependencies
- ffmpeg
- exiv2
- id3v2