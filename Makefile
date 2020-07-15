.DELETE_ON_ERROR:

all: tif_to_geogrid.e

CXX := icc

tif_to_geogrid.e: tif_to_geogrid.o # meminfo.o
	$(CXX) $^ -o $@ -lgdal

%.o: %.cc
	$(CXX) -c $< -o $@ -O2 -Wall -Wno-sign-compare

%.o: %.c
	$(CXX) -c $< -o $@ -O2 -Wall
