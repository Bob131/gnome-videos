#!/usr/bin/env python3

import os
import sys
import subprocess

if __name__ == "__main__":
    if len (sys.argv) < 3:
        print ("Usage: {} <input-svg> <size/output.png...>")
        exit ()

    input_svg = sys.argv[1]

    for output in sys.argv[2:]:
        assert output.count ("/") == 1 and output.endswith (".png")

        size = int (output.split ("/")[0])
        if not os.path.exists (str (size)):
            os.mkdir (str (size))

        command = "rsvg-convert -w {0} -h {0} -o {2} {1}".format (
            str (size), input_svg, output)

        subprocess.check_call (command, shell=True)
