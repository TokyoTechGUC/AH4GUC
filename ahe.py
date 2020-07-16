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
    hourly_utc_jit(in_ar + (np.zeros_like(in_ar[0]), ), out_ar,
                   [float(kwargs["w1"])], [float(kwargs["w2"])],
                   [float(kwargs["w3"])], [float(kwargs["w4"])],
                   [float(kwargs["metabolism"])])


def hourly_utc(in_ar, out_ar, xoff, yoff, xsize, ysize, raster_xsize,
               raster_ysize, r, gt, **kwargs):
    def split(w):
        res = np.array([float(x) for x in w.split()])
        assert res.size == 24
        return res

    hourly_utc_jit(in_ar, out_ar, split(kwargs["w1"]), split(kwargs["w2"]),
                   split(kwargs["w3"]), split(kwargs["w4"]),
                   split(kwargs["metabolism"]))


@jit(nopython=True, nogil=True, cache=True, parallel=True)
def hourly_utc_jit(in_ar, out_ar, w1, w2, w3, w4, metabolism):
    """
    in_ar: float
        - in_ar[0]: Monthly AHE usage
        - in_ar[1]: Monthly mean temperature
        - in_ar[2]: Population density (person/km^2)
        - in_ar[3]: Local time
    out_ar: int
    w1, w2, w3, w4: Weight factors of 4 different usage patterns
    metabolism: human metabolism rate (W/person)
    """
    in_ar = np.stack(in_ar)
    for i in prange(out_ar.shape[0]):
        for j in range(out_ar.shape[1]):
            tz = round(in_ar[3, i, j])
            if 0 <= tz <= 23:
                out_ar[i, j] = 1e5 * _hourly_jit(
                    in_ar[0, i, j], in_ar[1, i, j], in_ar[2, i, j], w1[tz],
                    w2[tz], w3[tz], w4[tz], metabolism[tz])
            else:
                out_ar[i, j] = 0


@jit(nopython=True, nogil=True, cache=True)
def _hourly_jit(month_ahe, month_temp, pop_den, w1, w2, w3, w4, metabolism):
    if 0 < month_ahe < 20000:
        if month_temp <= 12.4:
            w = w1
        elif month_temp <= 16.95:
            w = w2
        elif month_temp <= 20.95:
            w = w3
        else:
            w = w4
        return month_ahe * w + pop_den * metabolism / 1e6
        # (person/km^2) * (W/person) / (1e6 m^2/km^2) = W/m^2
    return 0


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
