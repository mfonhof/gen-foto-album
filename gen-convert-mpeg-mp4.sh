for f in *.mpeg *.mpg; do
  ffmpeg -i "$f" -map 0 -c:v libx264 -c:a aac -movflags +faststart "${f%.*}.mp4"
done

