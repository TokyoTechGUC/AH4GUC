import numpy as np
from numba import jit
from numba import prange

# pylint: disable=unused-argument,too-many-arguments,invalid-name


def monthly_no_meta(in_ar, out_ar, xoff, yoff, xsize, ysize, raster_xsize,
                    raster_ysize, r, gt, **kwargs):
    monthly_no_meta_jit(in_ar, out_ar)


@jit(nopython=True, nogil=True, cache=True, parallel=True)
def monthly_no_meta_jit(in_ar, out_ar):
    """
    in_ar[0]: Annual AHE usage
    in_ar[1]: Fraction of AHE used in a month
    """
    in_ar = np.stack(in_ar)
    for i in prange(out_ar.shape[0]):
        for j in range(out_ar.shape[1]):
            out_ar[i][j] = in_ar[0, i, j] * in_ar[1, i, j]


def hourly(in_ar, out_ar, xoff, yoff, xsize, ysize, raster_xsize, raster_ysize,
           r, gt, **kwargs):
    hourly_jit(in_ar, out_ar, float(kwargs["w1"]), float(kwargs["w2"]),
               float(kwargs["w3"]), float(kwargs["w4"]), float(kwargs["fact"]))


@jit(nopython=True, nogil=True, cache=True, parallel=True)
def hourly_jit(in_ar, out_ar, w1, w2, w3, w4, fact):
    """
    in_ar[0]: Monthly AHE usage
    in_ar[1]: Monthly mean temperature
    in_ar[2]: Population density (person/km^2)
    w1, w2, w3, w4: Weight factors of 4 different usage patterns
    fact: human metabolism rate (W/person)
    """
    in_ar = np.stack(in_ar)
    for i in prange(out_ar.shape[0]):
        for j in range(out_ar.shape[1]):
            if in_ar[0, i, j] > 0. and in_ar[0, i, j] < 20000.0:
                if in_ar[1, i, j] <= 12.4:
                    w = w1
                elif in_ar[1, i, j] <= 16.95:
                    w = w2
                elif in_ar[1, i, j] <= 20.95:
                    w = w3
                else:
                    w = w4
                out_ar[i][j] = 100000 * (in_ar[0, i, j] * w +
                                         in_ar[2, i, j] * fact / 1e6)
                # (person/km^2) * (W/person) / (1e6 m^2/km^2) = W/m^2
            else:
                out_ar[i][j] = 0.


def utc(in_ar, out_ar, xoff, yoff, xsize, ysize, raster_xsize, raster_ysize, r,
        gt, **kwargs):
    utc_jit(in_ar, out_ar)


@jit(nopython=True, nogil=True, cache=True, parallel=True)
def utc_jit(in_ar, out_ar):
    in_ar = np.stack(in_ar)
    for i in prange(out_ar.shape[0]):
        for j in range(out_ar.shape[1]):
            tz = in_ar[24, i, j]
            if 0 <= tz <= 23:
                out_ar[i][j] = in_ar[tz, i, j]
            else:
                out_ar[i][j] = 0
