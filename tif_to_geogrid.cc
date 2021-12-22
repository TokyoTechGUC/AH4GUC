#include "gdal_priv.h"
#include <algorithm>
#include <cassert>
#include <cstdio>

int main(int argc, char **argv) {
  if (argc != 27) {
    printf("Usage: %s 00_utc_tif 01_utc_tif ... 24_utc_tif output_dir_wordsize_2 output_dir_wordsize_3\n",
           argv[0]);
    return 0;
  }

  GDALAllRegister();

  std::vector<GDALDatasetUniquePtr> datasets;
  datasets.reserve(24);
  for (int i = 1; i < 25; ++i) {
    datasets.emplace_back(
        GDALDataset::Open(argv[i], GDAL_OF_READONLY | GDAL_OF_VERBOSE_ERROR));
  }

  std::vector<GDALRasterBand *> bands(datasets.size());
  for (int i = 0; i < datasets.size(); ++i) {
    bands[i] = datasets[i]->GetRasterBand(1);
    assert(bands[i]->GetRasterDataType() == GDT_Int32);
  }

  int col = bands[0]->GetXSize();
  int row = bands[0]->GetYSize();
  const int tile_x = 600;

  const int wordsize[] = {2, 3};
  const char * output_dir[] = {argv[25], argv[26]};

  assert(col % tile_x == 0 && row % tile_x == 0);
  int tile_counts = (col / tile_x) * (row / tile_x);
  int tile_id = 0;

  int *data = new int[tile_x * tile_x * datasets.size()];
  char *filename = new char[std::max(strlen(output_dir[0]), strlen(output_dir[1])) + 25];

  for (int y_off = 0; y_off < row; y_off += tile_x) {
    for (int x_off = 0; x_off < col; x_off += tile_x) {
      ++tile_id;
      GDALTermProgress(1.0 * tile_id / tile_counts, nullptr, nullptr);
      for (int i = 0; i < bands.size(); ++i) {
        assert(bands[i]->RasterIO(GF_Read, x_off, y_off, tile_x, tile_x,
                                  data + tile_x * tile_x * i, tile_x, tile_x,
                                  GDT_Int32, 0, 0, nullptr) == CE_None);
      }
      int max_value = 0;
      for (int i = 0; i < tile_x * tile_x * datasets.size(); ++i) {
        data[i] /= 1000;
        if (data[i] < 0) {
          data[i] = 0;
        }
        if (data[i] > max_value) max_value = data[i];
      }
      if (max_value == 0) continue;
      int xstart = x_off + 1;
      int xend = xstart + tile_x - 1;
      int yend = row - y_off;
      int ystart = yend - tile_x + 1;

      int iwordsize = 0;
      for (iwordsize = 0; iwordsize < 2; ++iwordsize) {
        if (max_value < (1 << (8 * wordsize[iwordsize]))) {
          break;
        }
      }
      assert(iwordsize != 2);

      sprintf(filename, "%s/%05d-%05d.%05d-%05d", output_dir[iwordsize], xstart,
              xend, ystart, yend);
      FILE *fp = fopen(filename, "wb");
      for (int i = 0; i < bands.size(); ++i) {
        int *layer = data + tile_x * tile_x * i;
        for (int y = tile_x - 1; y >= 0; --y) {
          for (int x = 0; x < tile_x; ++x) {
            unsigned int v = layer[y * tile_x + x];
            for (int shift = 8 * (wordsize[iwordsize] - 1); shift >= 0; shift -= 8) {
              fputc(v >> shift & 0xff, fp);
            }
          }
        }
      }
      fclose(fp);
    }
  }

  for (int iwordsize = 0; iwordsize < 2; ++iwordsize) {
    sprintf(filename, "%s/index", output_dir[iwordsize]);
    FILE *fp = fopen(filename, "w");
    double padf[6];
    datasets[0]->GetGeoTransform(padf);
    fprintf(fp, "type = continuous\n");
    fprintf(fp, "signed = no\n");
    fprintf(fp, "projection = regular_ll\n");
    fprintf(fp, "dx = %e\n", padf[1]);
    fprintf(fp, "dy = %e\n", -padf[5]);
    fprintf(fp, "known_x = 1\n");
    fprintf(fp, "known_y = %d\n", row);
    fprintf(fp, "known_lat = %f\n", padf[3]);
    fprintf(fp, "known_lon = %f\n", padf[0]);
    fprintf(fp, "wordsize = %d\n", wordsize[iwordsize]);
    fprintf(fp, "tile_x = %d\n", tile_x);
    fprintf(fp, "tile_y = %d\n", tile_x);
    fprintf(fp, "tile_z = %lu\n", bands.size());
    fprintf(fp, "scale_factor = %e\n", 1e-2);
    fprintf(fp, "missing_value = 0\n");
    fclose(fp);
  }

  delete filename;
  delete data;

  return 0;
}
