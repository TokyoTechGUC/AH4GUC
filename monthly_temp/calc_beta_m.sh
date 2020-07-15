#!/bin/bash

. /etc/profile.d/modules.sh
. "$HOME/.bashrc"
module unload python

conda activate

set -eou pipefail

export GDAL_VRT_ENABLE_PYTHON=YES
export PYTHONPATH=.
export PYTHONSO=$HOME/miniconda3/lib/libpython3.7m.so

moment=$1

year_mean_tif="$moment"/temp_year_mean.tif

if [[ ! -e "$year_mean_tif" ]]; then
  vrt_file="$moment"/temp_year_mean.vrt
  gdalbuildvrt "$vrt_file" "$moment"/??_tempmask.tif
  sed -i '/<VRTRasterBand/{
    s/<VRTRasterBand/& subClass="VRTDerivedRasterBand"/
    a <PixelFunctionLanguage>Python</PixelFunctionLanguage>
    a <PixelFunctionType>temperature.mean</PixelFunctionType>
  }' "$vrt_file"
  gdal_translate -ot Float32 -co COMPRESS=LZW -co PREDICTOR=2 "$vrt_file" "$year_mean_tif"
  rm "$vrt_file"
fi

for month in {01..12}; do
  vrt_file="$moment"/"$month"_alpha_m.vrt
  alpha_m="$moment"/"$month"_alpha_m.tif
  if [[ -e "$alpha_m" ]]; then
    continue
  fi
  gdalbuildvrt "$vrt_file" "$moment"/"$month"_tempmask.tif "$year_mean_tif"
  sed -i '/<VRTRasterBand/{
    s/<VRTRasterBand/& subClass="VRTDerivedRasterBand"/
    a <PixelFunctionLanguage>Python</PixelFunctionLanguage>
    a <PixelFunctionType>temperature.alpha_m</PixelFunctionType>
  }' "$vrt_file"
  gdal_translate -ot Float32 -co COMPRESS=LZW -co PREDICTOR=2 "$vrt_file" "$alpha_m"
  rm "$vrt_file"
done

alpha_m_mean="$moment"/alpha_m_mean.tif
if [[ ! -e "$alpha_m_mean" ]]; then
  vrt_file="$moment"/alpha_m_mean.vrt
  gdalbuildvrt "$vrt_file" "$moment"/??_alpha_m.tif
  sed -i '/<VRTRasterBand/{
    s/<VRTRasterBand/& subClass="VRTDerivedRasterBand"/
    a <PixelFunctionLanguage>Python</PixelFunctionLanguage>
    a <PixelFunctionType>temperature.mean</PixelFunctionType>
  }' "$vrt_file"
  gdal_translate -ot Float32 -co COMPRESS=LZW -co PREDICTOR=2 "$vrt_file" "$alpha_m_mean"
  rm "$vrt_file"
fi

for month in {01..12}; do
  alpha_m="$moment"/"$month"_alpha_m.tif
  beta_m="$moment"/"$month"_beta_m.tif
  vrt_file="$moment"/"$month"_beta_m.vrt
  if [[ -e "$beta_m" ]]; then
    continue
  fi
  gdalbuildvrt "$vrt_file" "$alpha_m" "$alpha_m_mean"
  sed -i '/<VRTRasterBand/{
    s/<VRTRasterBand/& subClass="VRTDerivedRasterBand"/
    a <PixelFunctionLanguage>Python</PixelFunctionLanguage>
    a <PixelFunctionType>temperature.div</PixelFunctionType>
  }' "$vrt_file"
  gdal_translate -ot Float32 -co COMPRESS=LZW -co PREDICTOR=2 "$vrt_file" "$beta_m"
  rm "$vrt_file"
done
