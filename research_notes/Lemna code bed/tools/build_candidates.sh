#!/bin/zsh
# Builds the Code bed candidates for the panel into <codebed>/out, from the Freesound HQ previews in <codebed>/dl/ogg
# (candidates.md §1), the rain bed's rain.caf in <repo> and tools/synth_code.py: each a seamless loop, scaled to -26 LUFS over both channels (the rain bed's), AAC 128 kbit/s
# in CAF (afconvert), its loudness read back as Core Audio decodes it, an m4a preview, a 20 s spectrogram.
# Run: build_candidates.sh <codebed> <repo>
set -eu
C=$1; R=$2; T="$R/research_notes/Lemna code bed/tools"; PY=(uv run -q --with numpy --with scipy python -I) F=/opt/homebrew/bin/ffmpeg; W=$C/work; O=$C/out; mkdir -p $O $W/loop
lufs() { $F -hide_banner -nostats -i $1 -af ebur128=peak=sample -f null - 2>&1 | awk '/Integrated loudness/{f=1} f&&/I:/{print $2; exit}'; }
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
mkdir -p $W/src
for id in 41497 838983; do  # decoded through the rain's 80 Hz high-pass, 48 kHz stereo float
  $F -hide_banner -loglevel error -y -i $C/dl/ogg/$id-hq.ogg -af "highpass=f=80:p=2,aformat=channel_layouts=stereo" \
    -ar 48000 -c:a pcm_f32le $W/src/$id.wav
done
afconvert -f WAVE -d LEF32 "$R/lib/LemnaClicks/Sources/LemnaClicks/Beds/Rain/rain.caf" $W/rain-decoded.wav
G=(--glass-lo 2200 --glass-hi 6500 --glass-tilt -3 --rate 60 --tau-lo 2 --tau-hi 6 --fizz-lo 4500 --fizz-db -15)
$PY "$T/synth_code.py" $W/synth-v4.wav $G --hiss-db -24                                          # CB3
$PY "$T/synth_code.py" $W/mix-v1.wav $G --layers glass,fizz --rain $W/rain-decoded.wav --rain-db 0  # CB4
$PY "$T/synth_code.py" $W/synth-sparse.wav --glass-lo 2200 --glass-hi 6500 --glass-tilt -3 --rate 6 --tau-lo 10 \
  --tau-hi 25 --layers glass,hum,hiss --hiss-db -24                                              # CB3 sparse
# CB1, Fishdog 41497 (MetaSynth), CC BY 3.0: 70 s from 3.6 s (loop_points.py: 0.19 dB). CB2, bassimat 838983, CC0: 63 s
# from 1.7 s (0.41 dB). Both already high-passed at 80 Hz in the decode.
xloop $W/src/41497.wav $W/loop/cb1.wav 3.6 70
xloop $W/src/838983.wav $W/loop/cb2.wav 1.7 63
cp $W/synth-v4.wav $W/loop/cb3.wav; cp $W/mix-v1.wav $W/loop/cb4.wav; cp $W/synth-sparse.wav $W/loop/cb3-sparse.wav
cp $W/rain-decoded.wav $W/loop/rain.wav
for b in cb1 cb2 cb3 cb4 cb3-sparse rain; do
  echo "$b"; level $W/loop/$b.wav $W/loop/$b-26.wav
  afconvert -f caff -d aac -b 128000 -q 127 $W/loop/$b-26.wav $O/$b.caf
  afconvert -f WAVE -d LEF32 $O/$b.caf $W/loop/$b-decoded.wav
  echo "  caf: $(lufs $W/loop/$b-decoded.wav) LUFS, peak $(peak $W/loop/$b-decoded.wav) dBFS, $(afinfo $O/$b.caf | awk '/estimated duration/{print $3}') s, $(stat -f %z $O/$b.caf) bytes"
  afconvert -f m4af -d aac -b 128000 -q 127 $W/loop/$b-26.wav $O/$b.m4a
  $F -hide_banner -loglevel error -y -t 20 -i $W/loop/$b-decoded.wav -lavfi \
    "aformat=channel_layouts=mono,showspectrumpic=s=880x180:legend=0:fscale=log:scale=log:color=intensity:start=100:stop=16000" \
    -q:v 4 $O/$b-spec.jpg
done
$PY "$T/analyze.py" "$R/lib/LemnaClicks/Sources/LemnaClicks/DefaultPack" $W/loop/{rain,cb1,cb2,cb3,cb4,cb3-sparse}-decoded.wav
ls -la $O
