#!/bin/bash

. ../tsubame_job_python_setup.sh

set -eoua pipefail
. ../compose_tif.sh

moment=$1

year_mean_tif="$moment"/temp_year_mean.tif
compose_tif "$year_mean_tif" "temperature.mean" "$moment"/??_tempmask.tif

calculate_alpha_m() {
  month=$1
  alpha_m="$moment"/"$month"_alpha_m.tif
  compose_tif "$alpha_m" "temperature.alpha_m" "$moment"/"$month"_tempmask.tif "$year_mean_tif"
}

parallel calculate_alpha_m ::: {01..12}

alpha_m_mean="$moment"/alpha_m_mean.tif
compose_tif "$alpha_m_mean" "temperature.mean" "$moment"/??_alpha_m.tif

calculate_beta_m() {
  month=$1
  alpha_m="$moment"/"$month"_alpha_m.tif
  beta_m="$moment"/"$month"_beta_m.tif
  compose_tif "$beta_m" "temperature.div" "$alpha_m" "$alpha_m_mean"
}

parallel calculate_beta_m ::: {01..12}
