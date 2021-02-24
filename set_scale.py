from osgeo import gdal
import sys

ds = gdal.Open(sys.argv[1], gdal.GA_Update)

ds.GetRasterBand(1).SetScale(1e-5)
