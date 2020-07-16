#!/bin/bash

. /etc/profile.d/modules.sh
. "$HOME/.bashrc"
module unload python

conda activate

set -eou pipefail

export GDAL_VRT_ENABLE_PYTHON=YES
export PYTHONPATH=.
export PYTHONSO=$HOME/miniconda3/lib/libpython3.7m.so

. ../compose_tif.sh

moment=$1

year_mean_tif="$moment"/temp_year_mean.tif
compose_tif "$year_mean_tif" "temperature.mean" "$moment"/??_tempmask.tif

for month in {01..12}; do
  alpha_m="$moment"/"$month"_alpha_m.tif
  compose_tif "$alpha_m" "temperature.alpha_m" "$moment"/"$month"_tempmask.tif "$year_mean_tif"
done

alpha_m_mean="$moment"/alpha_m_mean.tif
compose_tif "$alpha_m_mean" "temperature.mean" "$moment"/??_alpha_m.tif

for month in {01..12}; do
  alpha_m="$moment"/"$month"_alpha_m.tif
  beta_m="$moment"/"$month"_beta_m.tif
  compose_tif "$beta_m" "temperature.div" "$alpha_m" "$alpha_m_mean"
done
