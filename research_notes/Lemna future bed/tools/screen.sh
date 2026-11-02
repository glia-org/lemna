#!/bin/zsh
# screen.sh <fb> <repo> id...: decode each preview in <fb>/dl/<id>/ through the rain's 80 Hz high-pass to 48 kHz stereo
# float (<fb>/work/src), take up to 180 s from 2 s (<fb>/work/screen), measure all with the code bed's analyze.py
# (candidates.md §4).
set -eu
C=$1; R=$2; shift 2; T="$R/research_notes/Lemna code bed/tools"; F=/opt/homebrew/bin/ffmpeg
mkdir -p $C/work/src $C/work/screen; files=()
for id in "$@"; do
  src=$(ls $C/dl/$id/*.ogg | head -1)
  [[ -f $C/work/src/$id.wav ]] || $F -hide_banner -loglevel error -y -i $src -af "highpass=f=80:p=2,aformat=channel_layouts=stereo" -ar 48000 -c:a pcm_f32le $C/work/src/$id.wav
  $F -hide_banner -loglevel error -y -ss 2 -t 180 -i $C/work/src/$id.wav -c:a pcm_f32le $C/work/screen/$id.wav
  files+=($C/work/screen/$id.wav)
done
uv run -q --with numpy --with scipy python -I "$T/analyze.py" "$R/lib/LemnaClicks/Sources/LemnaClicks/DefaultPack" "${files[@]}"
