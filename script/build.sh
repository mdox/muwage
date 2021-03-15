# Fail on error for stability.
set -e

cd $(dirname "$0")

export dest=$(mktemp -d)

sh ./build_songs.sh

rm -rf ../public
cp -rf "$dest/." ../public
rm -rf "$dest"