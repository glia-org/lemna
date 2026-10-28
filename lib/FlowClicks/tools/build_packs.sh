#!/bin/zsh
# Builds the three new FlowClicks packs from Freesound's HQ previews. Run: build_packs.sh <scratch> <repo>
set -eu
S=$1; R=$2
F=/opt/homebrew/bin/ffmpeg
T="$R/lib/FlowClicks/tools/cut_click.py"
P="$R/lib/FlowClicks/Sources/FlowClicks"
O=$S/dl_packs/ogg
W=$S/work/src; B=$S/work/before
mkdir -p $W $B "$P/TypewriterPack" "$P/SoftPack" "$P/ElectricPack"
dec() { $F -hide_banner -loglevel error -y -i $O/$1-hq.ogg -af "$2" -ar 48000 -ac 1 -c:a pcm_s16le $W/$3.wav; }
cut() { python3 -I "$T" cut "$@"; }

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
