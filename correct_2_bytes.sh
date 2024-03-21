#!/bin/bash

set -eou pipefail

dir=$1

IFS=$'\n' filenames=($(basename -a "$dir"/??_24_2_bytes/*-* | sort -u))
unset IFS

for filename in "${filenames[@]}"; do
  file_in_3_bytes=("$dir"/??_24_3_bytes/"$filename")
  if [[ ! -e "${file_in_3_bytes[0]}" ]]; then
    continue
  fi
  echo Fixing "$filename"

  for month in {01..12}; do
    file_in_2_byte="$dir"/"$month"_24_2_bytes/"$filename"
    if [[ ! -e "$file_in_2_byte" ]]; then
      continue
    fi

    backup_dir="$dir"/"$month"_24_2_bytes/backup
    mkdir -p "$backup_dir"

    file_in_3_byte="$dir"/"$month"_24_3_bytes/"$filename"
    ./convert_2_bytes_to_3_bytes.e "$file_in_2_byte" "$file_in_3_byte" 
    mv "$file_in_2_byte" "$backup_dir"
  done
done
