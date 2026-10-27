#!/bin/zsh
# Cold release build of appkit-line, timed, and the size of its binary stripped. Writes ../results/appkit-build.txt,
# which the app's summary reads. Run: spikes/appkit-line/build.sh
set -eu
zmodload zsh/datetime
cd "${0:A:h}"
rm -rf .build
t0=$EPOCHREALTIME
swift build -c release
t1=$EPOCHREALTIME
bin=.build/release/appkit-line
strip -o .build/appkit-line.stripped "$bin"
mkdir -p ../results
{
  printf 'cold_release_build_s=%.1f\n' $(( t1 - t0 ))
  printf 'stripped_binary_bytes=%d\n' $(stat -f %z .build/appkit-line.stripped)
  printf 'unstripped_binary_bytes=%d\n' $(stat -f %z "$bin")
  printf 'swift=%s\n' "$(swift --version 2>&1 | grep -o 'Apple Swift version [0-9.]*')"
} > ../results/appkit-build.txt
cat ../results/appkit-build.txt
