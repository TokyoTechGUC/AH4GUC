import sys

from netCDF4 import Dataset
import numpy as np
from osgeo import gdal

def geo_transform(gt, x, y):
    return gt[0] + x * gt[1] + y * gt[2], gt[3] + x * gt[4] + y * gt[5]

def format_lattitude(lat):
    lat = round(lat)
    if lat < 0:
        return str(-lat) + "S"
    if lat > 0:
        return str(lat) + "N"
    return "0"

def format_longitude(lon):
    lon = round(lon)
    if lon < 0:
        return str(-lon) + "W"
    if lon > 0:
        return str(lon) + "E"
    return "0"

def main(tif_prefix, tif_suffix, x_off, y_off, n_lon, n_lat, output_prefix):
    tif_path = tif_prefix + '%02d_%02dHR' + tif_suffix
    n_month = 12
    n_hour = 24

    tif = gdal.Open(tif_path % (1, 0))
    x_grid, y_grid = np.meshgrid(np.arange(x_off, x_off + n_lon), np.arange(y_off, y_off + n_lat))
    x_geo, y_geo = geo_transform(tif.GetGeoTransform(), x_grid, y_grid)
    del tif

    root_group = Dataset(
            "%s%s_%s_%s_%s.nc" % (
                output_prefix,
                format_longitude(x_geo[0, 0]),
                format_longitude(x_geo[0, -1]),
                format_lattitude(y_geo[-1, 0]),
                format_lattitude(y_geo[0, 0])
                ), "w", diskless=True, persist=True)

    dim_month = root_group.createDimension("month", n_month)
    dim_hour = root_group.createDimension("hour", n_hour)
    dim_lat = root_group.createDimension("lat", n_lat)
    dim_lon = root_group.createDimension("lon", n_lon)
    lat = root_group.createVariable("lat", "f4", ("lat", "lon"), zlib=True)
    lon = root_group.createVariable("lon", "f4", ("lat", "lon"), zlib=True)
    lat[:] = y_geo[::-1]
    lon[:] = x_geo[::-1]

    ahe = root_group.createVariable("ahe", "i4", ("month", "hour", "lat", "lon"), zlib=True)
    ahe.coordinates = "lat lon"
    ahe.scale_factor = 1e-5
    ahe.units = "W/m^2"
    ahe.set_auto_scale(False)

    ahe_data = np.empty(ahe.shape, dtype=np.int32)

    for month in range(n_month):
        for hour in range(n_hour):
            tif = gdal.Open(tif_path % (month + 1, hour))
            ahe_data[month, hour] = tif.ReadAsArray(x_off, y_off, n_lon, n_lat)[::-1]
            del tif

    ahe[:] = ahe_data

    root_group.close()

if __name__ == '__main__':
    main(sys.argv[1], sys.argv[2], int(sys.argv[3]), int(sys.argv[4]), int(sys.argv[5]), int(sys.argv[6]), sys.argv[7])
    #  main('../correct_ahe/present/AHE_SSP3_2010_', 38160, 6360, 600, 600, 'test')
