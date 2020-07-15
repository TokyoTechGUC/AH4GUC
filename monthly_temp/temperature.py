import numpy as np
from numba import jit
from numba import prange


def mean(in_ar, out_ar, xoff, yoff, xsize, ysize, raster_xsize, raster_ysize,
         r, gt, **kwargs):
    mean_jit(in_ar, out_ar)


@jit(nopython=True, nogil=True, cache=True, parallel=True)
def mean_jit(in_ar, out_ar):
    in_ar = np.stack(in_ar)
    out_ar[:] = np.sum(in_ar, axis=0, dtype=np.float64) / in_ar.shape[0]


def div(in_ar, out_ar, xoff, yoff, xsize, ysize, raster_xsize, raster_ysize, r,
        gt, **kwargs):
    out_ar[:] = div_jit(in_ar[0], in_ar[1])


@jit(nopython=True, nogil=True, cache=True, parallel=True)
def div_jit(a, b):
    return a / b


def alpha_m(in_ar, out_ar, xoff, yoff, xsize, ysize, raster_xsize,
            raster_ysize, r, gt, **kwargs):
    """
    in_ar[0]: Month temperature
    in_ar[1]: Year temperature
    """

    alpha_m_jit(in_ar[0], in_ar[1], out_ar)


@jit(nopython=True, nogil=True, cache=True, parallel=True)
def alpha_m_jit(T_m, T_y, alpha_m):
    for y in prange(alpha_m.shape[0]):
        for x in range(alpha_m.shape[1]):
            if T_y[y, x] < -1000:  # NODATA
                alpha_m[y, x] = 1
            else:
                alpha_m[y, x] = _alpha_m(T_m[y, x], T_y[y, x])


@jit(nopython=True, nogil=True, cache=True)
def _alpha_m(T_m, T_y):
    """
    T_m: month temperature
    T_y: year temperature
    """

    return abs(T_m - 20) * f_s(T_m, T_y) + 1


@jit(nopython=True, nogil=True, cache=True)
def f_s(T_m, T_y):
    if T_m > 20:  # Warm
        if T_y < 10:
            res = 0.3
        elif T_y < 27:
            res = 0.002 * T_y * T_y + 0.062 * T_y - 0.4495
        else:
            res = 2.8
    else:  # Cold
        if T_y < 10:
            res = 2.8
        elif T_y < 27:
            res = -0.0063 * T_y * T_y + 0.1063 * T_y + 2.2806
        else:
            res = 0.3
    return res / 100
