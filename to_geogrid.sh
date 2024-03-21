#!/bin/bash
#$ -l h_node=1
#$ -l h_rt=00:40:00

. /etc/profile.d/modules.sh
. "$HOME"/.bashrc

set -eou pipefail

basedir=$1
year=$2
base_output_dir=$3

function combine_to_whole_year() {
  filenames=()
  for month in {01..12}; do
    cd "$base_output_dir"/"$month"_24_"$1"
    filenames+=(*-*)
    filesize=$(wc -c < "${filenames[-1]}")
    cd - > /dev/null
  done
  IFS=$'\n' filenames=($(sort -u <<<"${filenames[*]}"))
  unset IFS
  dummy_file=$(mktemp)
  truncate -s "$filesize" "$dummy_file"

  output_dir_basename=AHE_"$year"s/"$1"
  output_dir="$base_output_dir"/"$output_dir_basename"
  mkdir -p "$output_dir"

  sed '/tile_z/s/24/288/' "$base_output_dir"/01_24_"$1"/index > "$output_dir"/index

  for filename in "${filenames[@]}"; do
    while [[ $(jobs -p | wc -w) -ge 14 ]]; do
      wait -n
    done
    month_files=()
    for month in {01..12}; do
      month_file="$base_output_dir"/"$month"_24_"$1"/"$filename"
      if [[ -f "$month_file" ]]; then
        month_files+=("$month_file")
      else
        month_files+=("$dummy_file")
      fi
    done
    cat "${month_files[@]}" > "$output_dir"/"$filename" &
  done
  wait
  rm "$dummy_file"
}

for month in {01..12}; do
  output_dir=$base_output_dir/"$month"_24
  output_dir_2_bytes="$output_dir"_2_bytes
  output_dir_3_bytes="$output_dir"_3_bytes
  mkdir -p "$output_dir_2_bytes"
  mkdir -p "$output_dir_3_bytes"
  ./tif_to_geogrid.e "$basedir"/AHE_SSP3_"$year"_"$month"_??HR_UTC.tif "$output_dir_2_bytes" "$output_dir_3_bytes" &
done
wait

./correct_2_bytes.sh "$base_output_dir"

combine_to_whole_year "2_bytes"
combine_to_whole_year "3_bytes"

cd "$base_output_dir"
tar -cf - AHE_"$year"s/?_bytes/ | pigz > AHE_"$year"s.tar.gz
cd - > /dev/null
