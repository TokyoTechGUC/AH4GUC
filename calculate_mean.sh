#!/bin/bash
#$ -cwd
#$ -l f_node=1
#$ -l h_rt=1:00:00

. ./tsubame_job_python_setup.sh
. ./compose_tif.sh

for month in {01..12}; do
  compose_tif correct_ahe/future_utc/AHE_SSP3_2050_"$month"_mean_UTC.tif "ahe.mean" correct_ahe/future_utc/AHE_SSP3_2050_"$month"_??HR_UTC.tif \
    -ot Int32 -k_st Int64 -a_scale 1e-5 &
done
wait

for month in {01..12}; do
  compose_tif correct_ahe/present_utc/AHE_SSP3_2010_"$month"_mean_UTC.tif "ahe.mean" correct_ahe/present_utc/AHE_SSP3_2010_"$month"_??HR_UTC.tif \
    -ot Int32 -k_st Int64 -a_scale 1e-5 &
      # -te 135 35 140 40
done
wait

compose_tif correct_ahe/future_utc/AHE_SSP3_2050_mean_UTC.tif "ahe.mean" correct_ahe/future_utc/AHE_SSP3_2050_??_mean_UTC.tif \
  -ot Int32 -k_st Int64 -a_scale 1e-5 &
compose_tif correct_ahe/present_utc/AHE_SSP3_2010_mean_UTC.tif "ahe.mean" correct_ahe/present_utc/AHE_SSP3_2010_??_mean_UTC.tif \
  -ot Int32 -k_st Int64 -a_scale 1e-5 &
wait
