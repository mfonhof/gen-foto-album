#!/usr/bin/env bash
shopt -s nullglob
shopt -s nocaseglob

ROOT="."

sanitize_file() {
    local file="$1"
    local dir=$(dirname "$file")
    local base=$(basename "$file")
    chmod -x "$file"
    local newbase="${base// /.}"
    if [ "$base" != "$newbase" ]; then
        mv -i "$file" "$dir/$newbase"
        file="$dir/$newbase"
    fi
    echo "$file"
}

first_image_in_dir() {
    local DIR="$1"
    if [ -f "$DIR/cover.jpg" ]; then
        echo "cover.jpg"
        return
    fi
    for img in "$DIR"/*.{jpg,jpeg,png,webp}; do
        [ -f "$img" ] || continue
        echo "$(basename "$img")"
        return
    done
    echo ""
}

generate_html() {
    local DIR="$1"

    if [ "$DIR" = "$ROOT" ]; then
        HTML="$DIR/fotos.html"
        TITLE="Foto's"
        BREADCRUMB=""
    else
        HTML="$DIR/index.html"
        TITLE="$(basename "$DIR")"
        PARENT="$(dirname "$DIR")"
        REL_PARENT="$(realpath --relative-to="$DIR" "$PARENT")"
        if [ "$PARENT" = "$ROOT" ]; then
            BREADCRUMB="<div><a href='$REL_PARENT/fotos.html'>&larr; Terug</a></div>"
        else
            BREADCRUMB="<div><a href='$REL_PARENT/index.html'>&larr; Terug</a></div>"
        fi
    fi

    echo "GENERATE: $DIR"
    [ -f "$HTML" ] && rm -f "$HTML"

    cat > "$HTML" <<EOF
<!doctype html>
<html lang="nl">
<head>
<meta charset="utf-8">
<title>$TITLE</title>
<style>
body { font-family: sans-serif; background:#111; color:#eee; padding:20px; margin:0; }
a { color:#8cf; text-decoration:none; }
h1 { margin-bottom:20px; text-align:center; }
.gallery { display:flex; flex-wrap:wrap; gap:12px; justify-content:center; }
.gallery img, .gallery video, .gallery audio { border-radius:8px; box-shadow:0 0 8px rgba(0,0,0,0.5); object-fit:cover; transition: transform 0.2s; cursor:pointer; }
.gallery img:hover, .gallery video:hover, .gallery audio:hover { transform: scale(1.05); }
.folder-block { display:flex; flex-direction:column; align-items:center; width:20vw; margin:8px; text-align:center; }
.folder-block img, .folder-block video, .folder-block audio { width:20vw; height:20vh; object-fit:cover; border-radius:8px; box-shadow:0 0 6px rgba(0,0,0,0.5); }
.folder-block div { margin-top:6px; color:#8cf; font-weight:bold; }
.breadcrumb { margin-bottom:16px; text-align:center; }
#slideshow-container { margin:0 auto 20px auto; display:flex; flex-direction:column; justify-content:center; align-items:center; max-width:90vw; min-height:75vh; }
#slideshow-img, #slideshow-video, #slideshow-audio { max-width:100%; border-radius:8px; box-shadow:0 0 8px rgba(0,0,0,0.5); display:none; margin-bottom:8px; }
#slideshow-img { height:65vh; }
#slideshow-video { height:75vh; }
#prev-btn, #next-btn { padding:8px 12px; margin:6px; background:#8cf; border:none; border-radius:4px; cursor:pointer; color:#111; font-weight:bold; }
#prev-btn:hover, #next-btn:hover { background:#6ab; }
</style>
</head>
<body>
<h1>$TITLE</h1>
<div class="breadcrumb">$BREADCRUMB</div>
EOF

    subdirs_exist=false
    for subd in "$DIR"/*/; do
        [ -d "$subd" ] || continue
        subdirs_exist=true
    done

    if [ "$subdirs_exist" = true ]; then
        echo "<div class='gallery'>" >> "$HTML"
        for subd in "$DIR"/*/; do
            [ -d "$subd" ] || continue
            NAME="$(basename "$subd")"
            FIRST_IMG=$(first_image_in_dir "$subd")
            if [ -n "$FIRST_IMG" ]; then
                FIRST_IMG=$(sanitize_file "$subd/$FIRST_IMG")
                IMG_URL=$(basename "$FIRST_IMG")
                echo "<div class='folder-block'>
                        <a href='./$NAME/'><img src='./$NAME/$IMG_URL'></a>
                        <div><a href='./$NAME/'>$NAME</a></div>
                      </div>" >> "$HTML"
            else
                echo "<div class='folder-block'>
                        <a href='./$NAME/' style='display:block; width:20vw; height:20vh; background:#333; line-height:20vh; text-align:center;'>📁</a>
                        <div><a href='./$NAME/'>$NAME</a></div>
                      </div>" >> "$HTML"
            fi
        done
        echo "</div>" >> "$HTML"
    fi

    media_exist=false
    for f in "$DIR"/*.{jpg,jpeg,png,webp,mp3,wav,ogg,mp4,webm,mov}; do
        [ -f "$f" ] || continue
        media_exist=true
    done

    if [ "$media_exist" = true ]; then
        echo "<div id='slideshow-container'>
              <img id='slideshow-img' src='' alt='Slideshow'>
              <video id='slideshow-video' controls></video>
              <audio id='slideshow-audio' controls></audio>
              <div>
                <button id='prev-btn'>⬅ Vorige</button>
                <button id='next-btn'>Volgende ➡</button>
              </div>
              </div>" >> "$HTML"

        echo "<div class='gallery'>" >> "$HTML"
        for f in "$DIR"/*.{jpg,jpeg,png,webp,mp3,wav,ogg,mp4,webm,mov}; do
            [ -f "$f" ] || continue
            SAN=$(sanitize_file "$f")
            FILE=$(basename "$SAN")
            ext="${FILE##*.}"
            case "$ext" in
                jpg|jpeg|png|webp)
                    echo "<img src='$FILE' style='height:10vh; width:auto;' class='thumb'>" >> "$HTML"
                    ;;
                mp3|wav|ogg)
                    echo "<audio src='$FILE' style='height:3vh;' class='thumb' controls></audio>" >> "$HTML"
                    ;;
                mp4|webm|mov)
                    # Thumbnail video autoplay loop muted
                    echo "<video src='$FILE' style='height:10vh;' class='thumb' autoplay muted loop></video>" >> "$HTML"
                    ;;
            esac
        done
        echo "</div>" >> "$HTML"

        # Slideshow arrays
        echo "<script>
const images = [" >> "$HTML"
        for f in "$DIR"/*.{jpg,jpeg,png,webp,mp3,wav,ogg,mp4,webm,mov}; do
            [ -f "$f" ] || continue
            SAN=$(basename "$(sanitize_file "$f")")
            echo "'$SAN'," >> "$HTML"
        done
        echo "];

let current = 0;
const imgElem = document.getElementById('slideshow-img');
const videoElem = document.getElementById('slideshow-video');
const audioElem = document.getElementById('slideshow-audio');
const nextBtn = document.getElementById('next-btn');
const prevBtn = document.getElementById('prev-btn');
const thumbs = document.querySelectorAll('.thumb');

function showMedia(idx){
    const f = images[idx];
    const ext = f.split('.').pop().toLowerCase();

    // Stop alle lopende media
    audioElem.pause(); audioElem.currentTime = 0;
    videoElem.pause(); videoElem.currentTime = 0;

    imgElem.style.display='none'; 
    videoElem.style.display='none'; 
    audioElem.style.display='none';

    if(ext==='mp3'||ext==='wav'||ext==='ogg'){ 
        audioElem.src=f; 
        audioElem.style.display='block'; 
        audioElem.play(); 
    }
    else if(ext==='mp4'||ext==='webm'||ext==='mov'){ 
        videoElem.src=f; 
        videoElem.style.display='block'; 
        videoElem.style.height='75vh';
        videoElem.style.width='auto';
        videoElem.load(); 
        videoElem.play(); 
    }
    else { 
        imgElem.src=f; 
        imgElem.style.display='block'; 
    }
}

if(images.length>0) showMedia(0);

// Knoppen
nextBtn.addEventListener('click', ()=>{ current=(current+1)%images.length; showMedia(current); });
prevBtn.addEventListener('click', ()=>{ current=(current-1+images.length)%images.length; showMedia(current); });

// Klik thumbnails
thumbs.forEach((thumb, idx)=>{
    thumb.addEventListener('click', ()=>{
        current=idx;
        showMedia(current);
    });
});

// Pijltjestoetsen
document.addEventListener('keydown',(e)=>{
    if(e.key==='ArrowRight'){ current=(current+1)%images.length; showMedia(current); }
    if(e.key==='ArrowLeft'){ current=(current-1+images.length)%images.length; showMedia(current); }
});
</script>" >> "$HTML"
    fi

    echo "</body></html>" >> "$HTML"

    for subd in "$DIR"/*/; do
        [ -d "$subd" ] || continue
        generate_html "$subd"
    done
}

generate_html "$ROOT"

