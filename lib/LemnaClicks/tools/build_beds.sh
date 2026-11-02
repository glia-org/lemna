#!/bin/zsh
# Builds the four beds of pass 28 (Ship, Lab, Space, Synth; FB2, FB6, FB7 and FB8 of
# docs/design-panel-lemna-future-bed.html, research_notes/Lemna future bed/candidates.md) into Sources/LemnaClicks/Beds,
# from Freesound's HQ previews, each in its own folder <fb>/dl/<id>/<id>-hq.ogg, fetched from
# https://cdn.freesound.org/previews/<id ÷ 1000>/<id>_<uploader id>-hq.ogg: 45347_359482 and 174450_746632 whole,
# 212025_71257 and 242773_3946286 their first 8 MiB only (`curl -r 0-8388607`; the loops lie within them).
# Each as the rain bed (build_packs.sh) and the panel's candidates (build_candidates.sh there): decoded to 48 kHz stereo
# float through the rain's 12 dB/octave high-pass at 80 Hz, and Ship and Lab through a second one at 120 Hz (the low
# cut the user asked for, 2026-11-02: "cut the low low end a bit"); 90 s from the start loop_points.py ranks first, the
# next 3 s laid over the head on quarter sines, sample-exact; scaled to -26 LUFS over both channels (the rain's) or lower
# if the sample peak would pass -1 dBFS; AAC 128 kbit/s in CAF; bed.json's lufs read back as Core Audio decodes it.
# Needs ffmpeg, and afconvert (macOS). Run: build_beds.sh <fb> <repo>
set -eu
C=$1; R=$2
F=/opt/homebrew/bin/ffmpeg; L="$R/lib/LemnaClicks/tools/loop_points.py"; P="$R/lib/LemnaClicks/Sources/LemnaClicks/Beds"
W=$C/work/beds; mkdir -p $W
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
# name: id, the last loop start loop_points.py tries, the start taken (its first), the filter
typeset -A BED=(
  Ship  "45347 38 5.3 highpass=f=80:p=2,highpass=f=120:p=2"
  Lab   "212025 280 48.7 highpass=f=80:p=2,highpass=f=120:p=2"
  Space "174450 58 4.3 highpass=f=80:p=2"
  Synth "242773 326 90.8 highpass=f=80:p=2"
)
for b in Ship Lab Space Synth; do
  a=(${=BED[$b]}); id=$a[1]; last=$a[2]; st=$a[3]; hp=$a[4]; f=${(L)b}
  echo "$b ($id): $hp, 90 s from $st s"
  $F -hide_banner -loglevel error -y -i $C/dl/$id/$id-hq.ogg -af "$hp,aformat=channel_layouts=stereo" -ar 48000 \
    -c:a pcm_f32le $W/$id.wav
  python3 -I "$L" match $W/$id.wav 0 $last --ffmpeg $F
  xloop $W/$id.wav $W/$f-loop.wav $st 90
  level $W/$f-loop.wav $W/$f-26.wav
  mkdir -p "$P/$b"
  afconvert -f caff -d aac -b 128000 -q 127 $W/$f-26.wav "$P/$b/$f.caf"
  # bed.json's lufs: the integrated loudness of the loop as Core Audio decodes it.
  afconvert -f WAVE -d LEF32 "$P/$b/$f.caf" $W/$f-decoded.wav
  echo "  $f.caf: $(lufs $W/$f-decoded.wav) LUFS, peak $(peak $W/$f-decoded.wav) dBFS, $(stat -f %z "$P/$b/$f.caf") bytes," \
    "sha256 $(shasum -a 256 "$P/$b/$f.caf" | cut -c1-64)"
done
