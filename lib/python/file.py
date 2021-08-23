#!/bin/bash

import os

def splitFile(filename, nblines):
    # Get main filename
    dirname = os.path.dirname(filename)
    basename = os.path.basename(filename) 
    fileext = os.path.splitext(basename)

    # Open file
    input = open(filename, 'r')

    count = 0
    at = 0
    dest = None
    for line in input:
        if count % nblines == 0:
            if dest: dest.close()
            dest = open(dirname + '/' + fileext[0] + "-" + str(at) + fileext[1], 'w')
            at += 1
        dest.write(line)
        count += 1