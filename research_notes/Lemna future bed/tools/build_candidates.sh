#!/bin/zsh
# Builds the future-bed candidates for the panel into <fb>/out, from the Freesound HQ previews in <fb>/dl/<id>/<id>-hq.ogg
# (candidates.md §1; the long ones are the preview's first 8 MiB, fetched with `curl -r 0-8388607`), and the Rain bed's
# rain.caf in <repo> for comparison: each a seamless 90 s loop (the next 3 s laid over the head on quarter sines, as the
# rain), scaled to -26 LUFS over both channels (the rain bed's) or lower if the sample peak would pass -1 dBFS, AAC
# 128 kbit/s in CAF (afconvert), its loudness read back as Core Audio decodes it, an m4a preview, a 20 s spectrogram,
# then analyze.py (the code bed's), extra.py and ffmpeg's loudness range on every loop.
# Run: build_candidates.sh <fb> <repo>
set -eu
C=$1; R=$2; T="$R/research_notes/Lemna future bed/tools"; CB="$R/research_notes/Lemna code bed/tools"
PY=(uv run -q --with numpy --with scipy python -I) F=/opt/homebrew/bin/ffmpeg; W=$C/work; O=$C/out; mkdir -p $O $W/src $W/loop
lufs() { $F -hide_banner -nostats -i $1 -af ebur128=peak=sample -f null - 2>&1 | awk '/Integrated loudness/{f=1} f&&/I:/{print $2; exit}'; }
lra() { $F -hide_banner -nostats -i $1 -af ebur128 -f null - 2>&1 | awk '/Loudness range/{f=1} f&&/LRA:/{print $2; exit}'; }
peak() { $F -hide_banner -nostats -i $1 -af ebur128=peak=sample -f null - 2>&1 | awk '/Sample peak/{f=1} f&&/Peak:/{print $2; exit}'; }
xloop() {  # xloop in.wav out.wav start_s loop_s: the next 3 s laid over the head on quarter sines (build_packs.sh's rain)
  local s=$(( ${3} * 48000 )) n=$(( ${4} * 48000 )) x=$((3 * 48000)); s=${s%.*}; n=${n%.*}
  $F -hide_banner -loglevel error -y -i $1 -filter_complex "[0]asplit=3[h][o][b];\
[h]atrim=start_sample=${s}:end_sample=$((s + x)),asetpts=PTS-STARTPTS,afade=t=in:ns=${x}:curve=qsin[hf];\
[o]atrim=start_sample=$((s + n)):end_sample=$((s + n + x)),asetpts=PTS-STARTPTS,afade=t=out:ns=${x}:curve=qsin[of];\
[hf][of]amix=inputs=2:normalize=0[xf];[b]atrim=start_sample=$((s + x)):end_sample=$((s + n)),asetpts=PTS-STARTPTS[bd];\
[xf][bd]concat=n=2:v=0:a=1" -c:a pcm_f32le $2
}
level() {  # level in.wav out.wav: to -26 LUFS, or lower if the sample peak would pass -1 dBFS
  local i=$(lufs $1) p=$(peak $1); local g=$(python3 -c "i,p=$i,$p; g=-26-i; print(round(min(g,-1-p),2))")
  $F -hide_banner -loglevel error -y -i $1 -af "volume=${g}dB" -c:a pcm_f32le $2; echo "  gain ${g} dB (was ${i} LUFS, peak ${p})"
}
# id:start: the loop starts loop_points.py chose (candidates.md §1), 90 s each
typeset -A START=(fb1 715475:6.2 fb2 45347:5.3 fb3 353159:28.9 fb4 686237:20.3 fb5 743999:16.2 fb6 212025:48.7 fb7 174450:4.3 fb8 242773:90.8)
for b in ${(ok)START}; do
  id=${START[$b]%%:*}; st=${START[$b]##*:}
  # decoded through the rain's 80 Hz high-pass, 48 kHz stereo float
  [[ -f $W/src/$id.wav ]] || $F -hide_banner -loglevel error -y -i $C/dl/$id/$id-hq.ogg \
    -af "highpass=f=80:p=2,aformat=channel_layouts=stereo" -ar 48000 -c:a pcm_f32le $W/src/$id.wav
  xloop $W/src/$id.wav $W/loop/$b.wav $st 90
done
afconvert -f WAVE -d LEF32 "$R/lib/LemnaClicks/Sources/LemnaClicks/Beds/Rain/rain.caf" $W/loop/rain.wav
for b in rain ${(ok)START}; do
  echo "$b"; level $W/loop/$b.wav $W/loop/$b-26.wav
  afconvert -f caff -d aac -b 128000 -q 127 $W/loop/$b-26.wav $O/$b.caf
  afconvert -f WAVE -d LEF32 $O/$b.caf $W/loop/$b-decoded.wav
  echo "  caf: $(lufs $W/loop/$b-decoded.wav) LUFS, LRA $(lra $W/loop/$b-decoded.wav) LU, peak $(peak $W/loop/$b-decoded.wav) dBFS, $(afinfo $O/$b.caf | awk '/estimated duration/{print $3}') s, $(stat -f %z $O/$b.caf) bytes, sha256 $(shasum -a 256 $O/$b.caf | cut -c1-64)"
  afconvert -f m4af -d aac -b 128000 -q 127 $W/loop/$b-26.wav $O/$b.m4a
  echo "  m4a: $(lufs $O/$b.m4a) LUFS"
  $F -hide_banner -loglevel error -y -t 20 -i $W/loop/$b-decoded.wav -lavfi \
    "aformat=channel_layouts=mono,showspectrumpic=s=880x180:legend=0:fscale=log:scale=log:color=intensity:start=40:stop=16000" \
    -q:v 4 $O/$b-spec.jpg
done
$PY "$CB/analyze.py" "$R/lib/LemnaClicks/Sources/LemnaClicks/DefaultPack" $W/loop/{rain,fb1,fb2,fb3,fb4,fb5,fb6,fb7,fb8}-decoded.wav
$PY "$T/extra.py" "$CB" "$R/lib/LemnaClicks/Sources/LemnaClicks/DefaultPack" $W/loop/{rain,fb1,fb2,fb3,fb4,fb5,fb6,fb7,fb8}-decoded.wav
ls -la $O
$PY "$T/periods.py" "$CB" $W/loop/{rain,fb1,fb2,fb3,fb4,fb5}-decoded.wav
