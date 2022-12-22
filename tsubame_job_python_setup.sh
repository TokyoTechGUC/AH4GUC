#!/bin/bash

. /etc/profile.d/modules.sh
. "$HOME/.bashrc"
module unload python

conda activate ${1:-base}

set -eou pipefail

export GDAL_VRT_ENABLE_PYTHON=YES
export PYTHONPATH=.
export PYTHONSO=$HOME/miniconda3/lib/libpython3.7m.so
