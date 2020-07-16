#!/bin/bash

options=(-o logs/ -e logs/ -cwd)
options+=(-m a -M do.k.aa@m.titech.ac.jp)
options+=(-g tga-wrf-guc)

set -x
qsub "${options[@]}" -l f_node=1 -l h_rt='00:30:00' -t 1-12 -N future_ahe generate_ahe.sh future 2050 popden_2050.tif
qsub "${options[@]}" -l f_node=1 -l h_rt='00:30:00' -t 1-12 -N present_ahe generate_ahe.sh present 2010 popden_2013.tif

# qsub "${options[@]}" -N future_ahe_geogrid -hold_jid future_ahe to_geogrid.sh future_utc/ 2050 future_utc/geogrid/
# qsub "${options[@]}" -N present_ahe_geogrid -hold_jid present_ahe to_geogrid.sh present_utc/ 2010 present_utc/geogrid/
