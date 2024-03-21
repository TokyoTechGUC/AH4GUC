import sys

from netCDF4 import Dataset
import numpy as np
from osgeo import gdal

def geo_transform(gt, x, y):
    return gt[0] + x * gt[1] + y * gt[2], gt[3] + x * gt[4] + y * gt[5]

def format_latitude(lat):
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

def main(tif_prefix, tif_suffix, x_off, y_off, n_lon, n_lat, output_prefix, year):
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
                format_latitude(y_geo[-1, 0]),
                format_latitude(y_geo[0, 0])
                ), "w", diskless=True, persist=True)

    root_group.Conventions = "CF-1.6"
    root_group.title = "Anthropogenic Heat for Global Urban Climatology (AH4GUC) Data"
    #  root_group.institution = "Global Urban Climatology Lab (GUC Lab)/Alvin C. G. Varquez Lab - Tokyo Institute of Technology, Japan (https://www.tse.ens.titech.ac.jp/~varquez/en/)" ;
    root_group.source = "https://urbanclimate.tse.ens.titech.ac.jp/2020/12/14/global-1-km-present-and-future-hourly-anthropogenic-heat-flux/" ;
    root_group.references = "Varquez, A.C.G., Kiyomoto, S., Khanh, D.N. et al. Global 1-km present and future hourly anthropogenic heat flux. Sci Data 8, 64 (2021). https://doi.org/10.1038/s41597-021-00850-w" ;
    root_group.comment = "Original dataset in GeoTIFF format. Converted by Do Ngoc Khanh and I Dewa Gede A. Junnaedhi."
    # Both member of Kanda Lab and GUC Lab, Tokyo Institute of Technology. See also http://www.ide.titech.ac.jp/~kandalab/" ;


    dim_month = root_group.createDimension("month", n_month)
    dim_hour = root_group.createDimension("hour", n_hour)
    dim_lat = root_group.createDimension("lat", n_lat)
    dim_lon = root_group.createDimension("lon", n_lon)

    month = root_group.createVariable("month", "f4", ("month",), zlib=True)
    month.standard_name = "month"
    month.units = f"month since {year}-01-15 12:00:00"
    month.calendar = "standard"
    month.axis = "T"
    month[:] = np.arange(12)

    hour = root_group.createVariable("hour", "f4", ("hour", ), zlib=True)
    hour.standard_name = "hour"
    hour.long_name = "Hour"
    hour.units = "UTC hour"
    hour.axis = "Z"
    hour[:] = np.arange(24)

    lat = root_group.createVariable("lat", "f4", ("lat",), zlib=True)
    lat.standard_name = "latitude"
    lat.long_name = "Latitude"
    lat.units = "degrees_north"
    lat.axis = "Y"
    lat[:] = y_geo[::-1, 0]

    lon = root_group.createVariable("lon", "f4", ("lon",), zlib=True)
    lon.standard_name = "longitude"
    lon.long_name = "Longitude"
    lon.units = "degrees_east"
    lon.axis = "X" ;
    lon[:] = x_geo[0]

    ahe = root_group.createVariable("ahe", "i2", ("month", "hour", "lat", "lon"), zlib=True, chunksizes=(1, 12, 300, 300))
    ahe.standard_name = "AH4GUC"
    ahe.long_name = "Anthropogenic Heat for Global Urban Climatology"
    ahe.coordinates = "lat lon"
    ahe.units = "W/m^2"

    ahe_data = np.empty(ahe.shape, dtype=np.float64)

    for month in range(n_month):
        for hour in range(n_hour):
            tif = gdal.Open(tif_path % (month + 1, hour))
            ahe_data[month, hour] = tif.ReadAsArray(x_off, y_off, n_lon, n_lat)[::-1] * 1e-5
            del tif

    dmin, dmax = -32768, 32767
    vmin, vmax = np.min(ahe_data), np.max(ahe_data)
    if vmax > vmin:
        ahe.scale_factor = (vmax - vmin) / (dmax - dmin)
        ahe.add_offset = vmin - dmin * ahe.scale_factor

    ahe[:] = ahe_data

    root_group.close()

if __name__ == '__main__':
    main(sys.argv[1], sys.argv[2], int(sys.argv[3]), int(sys.argv[4]), int(sys.argv[5]), int(sys.argv[6]), sys.argv[7], int(sys.argv[8]))
