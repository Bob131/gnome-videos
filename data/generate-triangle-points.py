#!/usr/bin/env python3

import sys
import math

def get_points (icon_size, circle_radius):
    center = (icon_size / 2,) * 2
    side_length = circle_radius * 2 * (60 / 100)

    R = side_length / math.sqrt (3)

    A = (-math.sqrt (R**2 - (side_length / 2)**2), -side_length / 2)
    B = (A[0], -A[1])
    C = (R, 0)

    vertex_strings = []

    for vertex in [A, B, C]:
        vertex_strings.append (
            "{},{}".format (*[vertex[i] + center[i] for i in range (2)]))

    return 'points="{} {} {}"'.format (*vertex_strings)

if __name__ == "__main__":
    if len (sys.argv) != 3:
        print ("Usage: {} <icon-size> <circle-radius>".format (sys.argv[0]))
        exit ()

    print (get_points (int (sys.argv[1]), int (sys.argv[2])))
