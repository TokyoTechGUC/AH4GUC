# AH4GUC&mdash;Global 1-km present and future hourly anthropogenic heat flux

This repository contains source code used to calculate the
[AH4GUC dataset](https://urbanclimate.tse.ens.titech.ac.jp/2020/12/14/global-1-km-present-and-future-hourly-anthropogenic-heat-flux/)

This source code is originally written for running on TSUBAME 3 supercomputer.
Modify it appropriately for your system.

## Preparation

* Clone this repository.
* Download `raw_data.tar` from <https://urbanclimate.tse.ens.titech.ac.jp/database/AHE/AH4GUC/>
and extract it at the root directory of this repository.
Your directory should have the following structure.

```
ah4guc
  monthly_temp
    present
      01_tempmask.tif
      02_tempmask.tif
      ...
    future
      01_tempmask.tif
      02_tempmask.tif
      ...
  timezone
    time_00_float32.tif
    time_01_float32.tif
    ...
  output_2010_corrected.tif
  output_2050_corrected.tif
  popden_2013.tif
  popden_2050.tif
```

## Calculation procedure

### Calculate coefficients

```bash
cd monthly_temp
./calc_beta_m.sh present
./calc_beta_m.sh future
```

### Calculate AHE

For example, to calculate AHE in May in the present and future.
```bash
bash generate_ahe.sh present 2010 popden_2013.tif 05
bash generate_ahe.sh future 2050 popden_2050.tif 05
```

## Citation
Varquez, A.C.G., Kiyomoto, S., Khanh, D.N. et al. Global 1-km present and
future hourly anthropogenic heat flux. *Sci Data* **8**, 64 (2021).
<https://doi.org/10.1038/s41597-021-00850-w>
