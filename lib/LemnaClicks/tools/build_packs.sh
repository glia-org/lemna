#!/bin/zsh
# Builds the four new LemnaClicks packs, every pack's send sound (pass 19a) and the rain bed (pass 23a) from Freesound's
# HQ previews in <scratch>/dl_packs/ogg (https://cdn.freesound.org/previews/<id ÷ 1000>/<id>_<uploader>-hq.ogg) and VCSL's
# WAVs in <scratch>/dl_packs/vcsl (https://raw.githubusercontent.com/sgossner/VCSL/<commit>/<path>; THIRD_PARTY.md).
# Needs ffmpeg, and afconvert (macOS) for the bed's AAC.
# Run: build_packs.sh <scratch> <repo>
set -eu
S=$1; R=$2
F=/opt/homebrew/bin/ffmpeg
T="$R/lib/LemnaClicks/tools/cut_click.py"
P="$R/lib/LemnaClicks/Sources/LemnaClicks"
O=$S/dl_packs/ogg; V=$S/dl_packs/vcsl
W=$S/work/src; B=$S/work/before
mkdir -p $W $B "$P/TypewriterPack" "$P/SoftPack" "$P/ElectricPack" "$P/StonePack" "$P/Beds/Rain"
dec() { $F -hide_banner -loglevel error -y -i $O/$1-hq.ogg -af "$2" -ar 48000 -ac 1 -c:a pcm_s16le $W/$3.wav; }
decv() { $F -hide_banner -loglevel error -y -i $V/$1.wav -af "$2" -ar 48000 -ac 1 -c:a pcm_s16le $W/$3.wav; }
cut() { python3 -I "$T" cut "$@"; }
splice() { python3 -I "$T" splice "$@"; }

# Typewriter (A1): moodyfingers, Silver Typewriter Pack, CC0. A 12 dB/octave low-pass at 3.5 kHz.
for id in 734313 734318 734312; do dec $id "lowpass=f=3500:p=2" $id; dec $id "anull" $id-raw; done
tw="$P/TypewriterPack"
for v in "" "-raw"; do
  out=$tw; [[ -n $v ]] && out=$B
  cut $W/734313$v.wav $out/letter-1.wav 0.200 98
  cut $W/734313$v.wav $out/letter-2.wav 0.940 90 --gain -1.5
  cut $W/734313$v.wav $out/letter-3.wav 1.595 100 --gain -1.1
  cut $W/734313$v.wav $out/letter-4.wav 1.765 100 --gain -2.5
  cut $W/734313$v.wav $out/letter-5.wav 2.285 90 --gain -3.5
  cut $W/734313$v.wav $out/letter-6.wav 3.035 95
  cut $W/734318$v.wav $out/space-1.wav 1.282 110
  cut $W/734318$v.wav $out/space-2.wav 2.075 110
  cut $W/734312$v.wav $out/paragraph-1.wav 1.265 176 --lead 31 --fade 40 --max 250
  cut $W/734312$v.wav $out/paragraph-2.wav 2.455 180 --fade 40 --max 250
  cut $W/734313$v.wav $out/backspace-1.wav 0.940 70 --rate 0.9 --gain -6
  cut $W/734313$v.wav $out/backspace-2.wav 3.035 70 --rate 0.9 --gain -6
done
# The send (⌘⏎): the carriage's run and its stop, from the return of 734314 (no bell); the run faded in over 30 ms.
dec 734314 "lowpass=f=3500:p=2,atrim=8.78:9.24,asetpts=PTS-STARTPTS,afade=t=in:d=0.03:curve=qsin" 734314-tail
cut $W/734314-tail.wav $tw/send-1.wav 0.0 440 --lead 30 --fade 60 --max 500

# Soft (A2): Sadiquecat, MacBook Air M2 keys and FUJITSU Enter and Delete, CC0. The multi-takes' first channel
# (the mid of their MS pair). Enter and Delete: a 12 dB/octave high-pass at 150 Hz against their thump.
dec 799109 anull 799109; dec 799110 anull 799110
dec 799115 "highpass=f=150:p=2" 799115; dec 799116 "highpass=f=150:p=2" 799116
dec 799111 "pan=mono|c0=c0" 799111-mid; dec 799112 "pan=mono|c0=c0" 799112-mid
sp="$P/SoftPack"
cut $W/799109.wav $sp/letter-1.wav 0.028 74
cut $W/799110.wav $sp/letter-2.wav 0.015 80
cut $W/799111-mid.wav $sp/letter-3.wav 1.160 80
cut $W/799109.wav $sp/letter-4.wav 0.028 74 --rate 0.95
cut $W/799110.wav $sp/letter-5.wav 0.015 80 --rate 0.95
cut $W/799111-mid.wav $sp/letter-6.wav 1.160 80 --rate 0.95
cut $W/799112-mid.wav $sp/space-1.wav 1.926 68
cut $W/799112-mid.wav $sp/space-2.wav 4.347 70
cut $W/799116.wav $sp/paragraph-1.wav 0.088 110 --lead 8
cut $W/799116.wav $sp/paragraph-2.wav 0.088 110 --lead 8 --rate 0.94
cut $W/799115.wav $sp/backspace-1.wav 0.040 112 --lead 10
cut $W/799115.wav $sp/backspace-2.wav 0.040 112 --lead 10 --rate 0.94
cut $W/799116.wav $sp/send-1.wav 0.088 240 --lead 8 --fade 80 --max 300  # the send: Enter's press and its release

# Electric (A3): magedu, pack Typewriter, CC BY 4.0. A 12 dB/octave high-pass at 150 Hz against the motor's hum.
for id in 277721 277724 319944 319945; do dec $id "highpass=f=150:p=2" $id; done
el="$P/ElectricPack"
cut $W/277721.wav $el/letter-1.wav 0.702 100
cut $W/277721.wav $el/letter-2.wav 1.784 100
cut $W/277721.wav $el/letter-3.wav 3.332 100
cut $W/277721.wav $el/letter-4.wav 3.487 100
cut $W/277721.wav $el/letter-5.wav 5.797 100
cut $W/277721.wav $el/letter-6.wav 6.726 100
cut $W/277724.wav $el/space-1.wav 0.445 110
cut $W/319944.wav $el/space-2.wav 0.843 74
cut $W/319945.wav $el/paragraph-1.wav 0.313 600 --fade 200 --max 700
cut $W/319945.wav $el/paragraph-2.wav 0.313 600 --fade 200 --max 700 --rate 0.94
cut $W/277721.wav $el/backspace-1.wav 1.064 70 --rate 0.9 --gain -6
cut $W/277721.wav $el/backspace-2.wav 3.982 70 --rate 0.9 --gain -6
# The send: the clutch's impact spliced onto the end of the carriage's run, so the margin stop comes at about 245 ms.
splice $W/319945.wav $W/319945-splice.wav 0.305 0.45 1.45 1.76 --cross 30
cut $W/319945-splice.wav $el/send-1.wav 0.0 420 --lead 8 --fade 100 --max 500

# Keychron (the default pack, cut before this script): its send, the Enter take's press and release.
dec 789629 anull 789629
cut $W/789629.wav "$P/DefaultPack/send-1.wav" 0.006 290 --fade 120 --max 400

# Stone (CK1, pass 23a): worthahep88's single rock hitting wood, four takes, CC0; Return and send from VCSL, CC0. Each
# kind's cuts share one --gain that brings their mean M max to the Keychron kind's (THIRD_PARTY.md, the Stone pack).
for id in 319223 319226 319227 319228; do dec $id anull $id; done
st="$P/StonePack"
cut $W/319223.wav $st/letter-1.wav 0.038 60 --gain -1.9
cut $W/319226.wav $st/letter-2.wav 0.172 60 --gain -1.9
cut $W/319227.wav $st/letter-3.wav 0.069 60 --gain -1.9
cut $W/319228.wav $st/letter-4.wav 0.093 60 --gain -1.9
cut $W/319223.wav $st/letter-5.wav 0.038 60 --rate 0.94 --gain -1.9
cut $W/319226.wav $st/letter-6.wav 0.172 60 --rate 0.94 --gain -1.9
cut $W/319227.wav $st/letter-7.wav 0.069 60 --rate 0.94 --gain -1.9
cut $W/319228.wav $st/letter-8.wav 0.093 60 --rate 0.94 --gain -1.9
# The space: the dullest take (319227), 20 and 25 % slower: lower and darker than any letter.
cut $W/319227.wav $st/space-1.wav 0.069 60 --rate 0.8 --gain 2.6
cut $W/319227.wav $st/space-2.wav 0.069 60 --rate 0.75 --gain 2.6
cut $W/319226.wav $st/backspace-1.wav 0.172 60 --rate 0.88 --gain -1.9
cut $W/319228.wav $st/backspace-2.wav 0.093 60 --rate 0.88 --gain -1.9
# Return: the low slit drum, two strengths, from its onset.
decv LogDrumLo_MedM_v1_rr1_Sum anull logdrum-v1; decv LogDrumLo_MedM_v2_rr1_Sum anull logdrum-v2
cut $W/logdrum-v1.wav $st/paragraph-1.wav 0.0 200 --lead 10 --fade 50 --max 250 --gain -4.1
cut $W/logdrum-v2.wav $st/paragraph-2.wav 0.0 200 --lead 10 --fade 50 --max 250 --gain -4.1
# The send: one hand chime from its strike (6 ms in), its last 400 ms faded in the decode (cut fades a third at most).
decv sus_E4_r01_main "atrim=start=0.006,asetpts=PTS-STARTPTS,afade=t=out:st=0.5:d=0.4:curve=hsin" chime-e4
cut $W/chime-e4.wav $st/send-1.wav 0.0 900 --lead 30 --max 1000 --gain -14

# The rain bed (BD1, pass 23a): felix.blume 585845, CC0, stereo; its light first 5½ minutes, [30 s, 333 s), through a
# 12 dB/octave high-pass at 80 Hz. loop_points.py lists the starts whose wrap matches best; the first, 186.1 s into the
# stretch (3:36.1 in the recording), is taken: 90 s from there, the next 3 s laid over the head (quarter-sine fades,
# sample-exact), AAC 128 kbit/s in CAF (an m4a would carry its creation time).
$F -hide_banner -loglevel error -y -i $O/585845-hq.ogg -af "highpass=f=80:p=2,atrim=start=30:end=333,asetpts=PTS-STARTPTS" \
  -c:a pcm_f32le $W/585845.wav
python3 -I "$R/lib/LemnaClicks/tools/loop_points.py" match $W/585845.wav 0 210 --ffmpeg $F
s=$((1861 * 4800)); n=$((90 * 48000)); x=$((3 * 48000))
$F -hide_banner -loglevel error -y -i $W/585845.wav -filter_complex "[0]asplit=3[h][o][b];\
[h]atrim=start_sample=${s}:end_sample=$((s + x)),asetpts=PTS-STARTPTS,afade=t=in:ns=${x}:curve=qsin[hf];\
[o]atrim=start_sample=$((s + n)):end_sample=$((s + n + x)),asetpts=PTS-STARTPTS,afade=t=out:ns=${x}:curve=qsin[of];\
[hf][of]amix=inputs=2:normalize=0[xf];[b]atrim=start_sample=$((s + x)):end_sample=$((s + n)),asetpts=PTS-STARTPTS[bd];\
[xf][bd]concat=n=2:v=0:a=1" -c:a pcm_f32le $W/rain-loop.wav
afconvert -f caff -d aac -b 128000 -q 127 $W/rain-loop.wav "$P/Beds/Rain/rain.caf"
# bed.json's lufs: the integrated loudness of the loop as Core Audio decodes it.
afconvert -f WAVE -d LEF32 "$P/Beds/Rain/rain.caf" $W/rain-decoded.wav
$F -hide_banner -nostats -i $W/rain-decoded.wav -af ebur128 -f null - 2>&1 | grep -A1 "Integrated loudness" | tail -1
# The beds of pass 28 (Ship, Lab, Space, Synth) are made by build_beds.sh.
