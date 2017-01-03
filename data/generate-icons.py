#!/usr/bin/env python3

import os
import sys

triangle_points = __import__ ("generate-triangle-points")

if __name__ == "__main__":
    if len (sys.argv) < 3:
        print ("Usage: {} <input-svg> <size/output.svg...>".format (
            sys.argv[0]))
        exit ()

    with open (sys.argv[1]) as f:
        svg_data = f.read ()

    for output in sys.argv[2:]:
        assert output.count ("/") == 1 and output.endswith (".svg")

        size = int (output.split ("/")[0])
        if not os.path.exists (str (size)):
            os.mkdir (str (size))

        center = size / 2
        radius = center - 2

        with open (output, 'w') as f:
            f.write (svg_data.format (size=size, center=center, radius=radius,
                points=triangle_points.get_points (size, radius)))
