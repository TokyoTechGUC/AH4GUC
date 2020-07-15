#!/bin/bash
#$ -l h_node=1
#$ -l h_rt=00:20:00

. /etc/profile.d/modules.sh
. "$HOME"/.bashrc

set -eou pipefail

basedir=$1
year=$2
base_output_dir=$3

for month in {01..12}; do
  output_dir=$base_output_dir/"$month"_24
  rm -rf "$output_dir"
  mkdir -p "$output_dir"
  ./tif_to_geogrid.e "$basedir"/AHE_SSP3_"$year"_"$month"_??HR_UTC.tif "$output_dir" &
done
wait
