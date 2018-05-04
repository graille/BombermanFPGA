import os, sys
from PIL import Image
from os import listdir
from os.path import isfile, join
import numpy as np
import struct
from modes import Mode
from vhdl_generator import *

# ------------------------------------------------------------------------------
# CONFIGURATION
# ------------------------------------------------------------------------------

output_resize = True
output_width = 40

output_mode = Mode.VHDL # Mode.IMAGE / Mode.VHDL

output_transparent_color = "0D543D"
input_transparent_color = ["99D8E8", "253F90", "3B3320", "157E1F"]
images_available_extensions = ["jpg", "jpeg", "bmp", "tiff", "png", "gif"]

bits_resolution = 5
available_color = [  # 31 colors maximum (+ transparent)
    "000000",
    "FFFFFF",

    # Brique
    # "A5A399",
    "343237",
    "8B887C",

    "D5DDE6",
    "939BA3",
    "2D3543",
    "3C4C5A",

    # Bonus
    "F7C535",  # Yellow
    "F77525",  # Orange

    "0066F3",  # Blue
    "8FB8ED",  # Light blue

    "6F1D0D",  # Red

    "389E5D",  # Green

    # Bombs
    "345143",
    "516876",
    "68879D",

    "0B7EC9",
    "19BDE3",

    "F6291B",

    "2C1718",

    # Explosions
    "F7C342",
    "F72335",
    "F8E0A1",
    "F66E25",
    "9C0010",
    "F65C23",
    "F8CC46",

    "122D13",

    # Nuances de gris
    "343434",
    "3C4444",

    output_transparent_color
]


# ------------------------------------------------------------------------------
# PROCESSING
# ------------------------------------------------------------------------------


images_path = sys.argv[1]
images_tmp_names = [f for f in listdir(images_path) if isfile(join(images_path, f))]
images_names = []

# Check colors number
print("Number of selected colors : " + str(len(available_color)))
assert (len(available_color) <= 2 ** bits_resolution)

for i, im in enumerate(images_tmp_names):
    if im.split('.')[-1] in images_available_extensions:
        images_names += [(images_path + "/" + im).replace("//", "/")]

print("Images founded : " + str(images_names))

# Check entries and uppercase colors
for i, c in enumerate(available_color):
    available_color[i] = c.upper()

for i, c in enumerate(input_transparent_color):
    input_transparent_color[i] = c.upper()

for i, e in enumerate(images_available_extensions):
    images_available_extensions[i] = e.lower()

# Converting available color to tuple
available_color_rgb = []
for c in available_color:
    available_color_rgb += [tuple(int(c[i:i + 2], 16) for i in (0, 2, 4))]


# Processing functions
def diff_calculator(elt):
    # See https://en.wikipedia.org/wiki/Color_difference
    global available_color_rgb

    def calculate_diff(elt1, elt2):
        ds = [elt1[i] - elt2[i] for i in (0, 1, 2)]
        r = (elt1[0] + elt2[0]) / 2
        return (
                2 * ds[0] ** 2 + 4 * ds[1] ** 2 + 3 * ds[2] ** 2 + (r * (ds[0] ** 2 - ds[2] ** 2)) / 256
        )

    return list(
        map(
            lambda x: (calculate_diff(x, elt), x),
            available_color_rgb
        )
    )


def tupleToHex(tuple):
    return ('%02x%02x%02x' % tuple)


def hexToTuple(hex):
    return struct.unpack('BBB', rgbstr.decode('hex'))

used_colors = []
images_descriptor = []
for infile in images_names:
    try:
        im = Image.open(infile)
        print("-----------------------------")
        print("Process : " + str(infile))
        print("Image original size : " + repr(im.size))

        if output_resize:
            wpercent = (output_width / float(im.size[0]))
            hsize = int((float(im.size[1]) * float(wpercent)))
            im = im.resize((output_width, hsize), Image.NEAREST)

            print("Image new size : " + repr(im.size))

        # Get image pixel array
        p = np.asarray(im)

        max_w = im.size[0]
        max_h = im.size[1]

        output_image_description = [[] for i in range(max_h)]

        for i in range(max_h):
            for j in range(max_w):
                try:
                    if len(p[i, j]) == 4 and p[i, j][3] < 20:
                        hex_p = output_transparent_color
                    else:
                        tuple = (p[i, j][0], p[i, j][1], p[i, j][2])
                        hex_tmp = tupleToHex(tuple)

                        if hex_tmp.upper() in input_transparent_color:
                            hex_p = output_transparent_color
                        else:
                            differences_list = diff_calculator(tuple)
                            differences_list.sort()
                            real_tuple = differences_list[0][1]

                            hex_p = tupleToHex(real_tuple)
                except IndexError:
                    hex_p = output_transparent_color

                hex_p = hex_p.upper()
                h_index = available_color.index(hex_p)
                output_image_description[i] += [int(h_index)]

        # Save used colors
        for l, _ in enumerate(output_image_description):
            for p in output_image_description[l]:
                if p not in used_colors:
                    used_colors.append(p)

        if output_mode == Mode.IMAGE:
            print("Image reconstitution")
            im2 = Image.new(im.mode, im.size)
            pixelList = []

            for k, ui in enumerate(output_image_description):
                for l, elt in enumerate(output_image_description[k]):
                    pixelList.append(available_color_rgb[elt])

            outfile_name = os.path.splitext(infile)[0] + "_processed.bmp"

            im2.putdata(pixelList)
            im2.save(outfile_name, "BMP")
            print(outfile_name + " generated")

        if output_mode == Mode.VHDL:
            images_descriptor.append(output_image_description)

    except IOError:
        print("cannot create thumbnail for '%s'" % infile)

if output_mode == Mode.VHDL:
    generate_converter(bits_resolution, available_color)
    generate_rom(bits_resolution, available_color, images_descriptor)

# List unused colors
print("")
nb = 0
for i, elt in enumerate(available_color):
    if i not in used_colors:
        print(">> Color " + str(i) + " (#" + available_color[i] + ") unused")
        nb += 1

print("Total : " + str(nb) + " colors unused")
