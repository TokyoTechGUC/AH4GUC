#!/bin/bash
#$ -l h_node=1
#$ -l h_rt=00:40:00

. /etc/profile.d/modules.sh
. "$HOME"/.bashrc

set -eou pipefail

basedir=$1
year=$2
base_output_dir=$3

for month in {01..12}; do
  output_dir=$base_output_dir/"$month"_24
  output_dir_2_bytes="$output_dir"_2_bytes
  output_dir_3_bytes="$output_dir"_3_bytes
  rm -rf "$output_dir"
  mkdir -p "$output_dir"
  {
    ./tif_to_geogrid.e "$basedir"/AHE_SSP3_"$year"_"$month"_??HR_UTC.tif "$output_dir_2_bytes" "$output_dir_3_bytes"
    cd "$base_output_dir"
    tar cfz "$month".tar.gz "$output_dir_2_bytes" "$output_dir_3_bytes"
  } &
done
wait
