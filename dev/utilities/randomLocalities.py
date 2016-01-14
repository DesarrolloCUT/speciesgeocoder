#!/usr/local/opt/python/bin/python2.7

# This script will generate a number of locality records 
# that can be used for e.g. performance testing of SpeciesGeoCoder.
#
# Usage: ./randomLocalities.py <INT> > file.csv
#
# where <INT> is the number of localities to generate.

import sys, random, string

nrLoc = int(sys.argv[1])

for i in range(nrLoc):
	name = ''.join(random.choice("abcdefghijklmnopqrstuvxyz") for i in range(8))
	lat = random.uniform(-90.0, 90.0)
	lon = random.uniform(-180.0, 180.0)

	print name, "\t", lat, "\t", lon

