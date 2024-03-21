#include <cstdio>
#include <cassert>

int main(int argc, char **argv) {
  if (argc != 3) {
    printf("Usage: %s file_in_2_bytes file_in_3_bytes\n",
           argv[0]);
    return 0;
  }

  FILE *fp_in = fopen(argv[1], "rb");
  FILE *fp_out = fopen(argv[2], "wb");

  int b1, b2;
  while ((b1 = fgetc(fp_in)) != EOF) {
    b2 = fgetc(fp_in);
    assert(b2 != EOF);
    fputc(0, fp_out);
    fputc(b1, fp_out);
    fputc(b2, fp_out);
  }

  fclose(fp_in);
  fclose(fp_out);

  return 0;
}
