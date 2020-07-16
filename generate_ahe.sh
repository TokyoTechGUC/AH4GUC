#!/bin/bash

. /etc/profile.d/modules.sh
. "$HOME/.bashrc"
module unload python

conda activate

set -eou pipefail

export GDAL_VRT_ENABLE_PYTHON=YES
export PYTHONPATH=.
export PYTHONSO=$HOME/miniconda3/lib/libpython3.7m.so

. ./compose_tif.sh

w1=( 0.608215 0.434346 0.289504 0.259544 0.294717 0.337675 0.45107 0.804371 1.411348 1.316703 1.355483 1.323806 1.314536 1.29899 1.328093 1.307997 1.30695 1.393122 1.463495 1.433388 1.19949 1.210262 0.992553 0.8647332 )
w2=( 0.557478 0.39479 0.336615 0.293129 0.34431 0.405552 0.566222 0.861609 1.13571 1.188195 1.386827 1.392018 1.408568 1.38327 1.403093 1.428007 1.430827 1.450605 1.485231 1.398923 1.149193 1.086298 0.816803 0.696604 )
w3=( 0.508126 0.370016 0.343788 0.294209 0.352713 0.418111 0.591728 0.849874 0.954737 1.1498 1.430585 1.463298 1.481697 1.461458 1.47728 1.519798 1.523604 1.528128 1.532506 1.345529 1.08802 0.982672 0.725456 0.60609 )
w4=( 0.438995 0.338244 0.315746 0.26177 0.312785 0.357215 0.499174 0.709469 0.840674 1.178221 1.53088 1.587226 1.593552 1.584948 1.604017 1.646218 1.654345 1.646944 1.581719 1.290567 0.996295 0.875675 0.636464 0.521858 )
fact=( 70.0 70.0 70.0 70.0 70.0 84. 105. 122.5 140. 140. 140. 140. 140. 140. 140. 140. 140. 140. 140. 140. 140. 122.5 105. 84. )

moment=$1
year=$2
popden=$3
mon=$(printf '%02d' "$SGE_TASK_ID")

mkdir -p "$moment" "$moment"_utc

compose_tif ./"$moment"/AHE_no_meta_SSP3_"$year"_"$mon".tif "ahe.monthly_no_meta" \
  output_"$year"_corrected.tif ./monthly_temp/"$moment"/"$mon"_beta_m.tif \
  -tr 0.0083333333333333 0.0083333333333333 -te -180. -90. 180. 90.

for hor in {0..23}; do
  (
    horf=$(printf '%02d' "$hor")
    compose_tif ./"$moment"/AHE_SSP3_"$year"_"$mon"_"$horf"HR.tif "ahe.hourly" \
      ./"$moment"/AHE_no_meta_SSP3_"$year"_"$mon".tif ./monthly_temp/"$moment"/"$mon"_tempmask.tif "$popden" \
      -k_funcargs "$(printf 'w1="%lf" w2="%lf" w3="%lf" w4="%lf" fact="%lf"' "${w1[$hor]}" "${w2[$hor]}" "${w3[$hor]}" "${w4[$hor]}" "${fact[$hor]}")" \
      -tr 0.0083333333333333 0.0083333333333333 -te -180. -90. 180. 90. \
      -ot Int32 -k_st Float32
  ) &
done
wait

for horf in {00..23}; do
  (
    compose_tif ./"$moment"_utc/AHE_SSP3_"$year"_"$mon"_"$horf"HR_UTC.tif "ahe.utc" \
      ./"$moment"/AHE_SSP3_"$year"_"$mon"_{00..23}HR.tif ./timezone/time_"$horf".tif \
      -tr 0.0083333333333333 0.0083333333333333 -te -180. -90. 180. 90. -ot Int32
  ) &
done
wait
