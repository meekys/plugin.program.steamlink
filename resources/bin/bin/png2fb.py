#!/usr/bin/python3
import os
import sys
import fcntl
import struct
from PIL import Image
import numpy as np

FBIOGET_VSCREENINFO = 0x4600
FB_VAR_SCREENINFO_FORMAT = "6I2I3I3I3I3III2II10II4I"

if len(sys.argv) != 3:
    print("Usage: png2fb.py fbdev infile", file=sys.stderr)
    sys.exit(1)

print(f"Reading {sys.argv[1]}...")
fbdev = os.open(sys.argv[1], os.O_RDONLY)
try:

    vscreeninfo_buffer = bytearray(struct.calcsize(FB_VAR_SCREENINFO_FORMAT))
    fcntl.ioctl(fbdev, FBIOGET_VSCREENINFO, vscreeninfo_buffer)

    (xres, yres, xres_virtual, yres_virtual, xoffset, yoffset,
    bits_per_pixel, grayscale,
    red_offset, red_length, red_msb_right,
    green_offset, green_length, green_msb_right,
    blue_offset, blue_length, blue_msb_right,
    transp_offset, transp_length, transp_msb_right,
    nonstd, activate, height, width, accel_flags,
    pixclock, left_margin, right_margin, upper_margin, lower_margin,
    hsync_len, vsync_len, sync, vmode, rotate, colorspace,
    reserved1, reserved2, reserved3, reserved4) = struct.unpack(FB_VAR_SCREENINFO_FORMAT, vscreeninfo_buffer)

finally:
    os.close(fbdev)

print(f"Resolution: {xres}x{yres}")
print(f"Virtual Resolution: {xres_virtual}x{yres_virtual}")
print(f"Bits per pixel: {bits_per_pixel}")
print(f"rgba: {red_length}/{red_offset}, {green_length}/{green_offset}, {blue_length}/{blue_offset}, {transp_length}/{transp_offset}")

if (sys.argv[2] == '-'):
    print("Reading stdin...")
    im = Image.open(sys.stdin.buffer)
    sys.stdin.close()
else:
    print(f"Reading {sys.argv[2]}")
    im = Image.open(sys.argv[2])

print("Resizing...")
newsize = xres, yres
im.thumbnail(newsize) # Ensure picture fits within framebuffer size

print("Centering...")
im2 = Image.new("RGB", (xres, yres), (0,0,0))
offset_x = (xres - im.width) // 2
offset_y = (yres - im.height) // 2
im2.paste(im, (offset_x, offset_y))

print("Converting...")
pixels = np.array(im2)

red   = pixels[:, :, 0]
green = pixels[:, :, 1]
blue  = pixels[:, :, 2]

r5 = (red   >> (8 - red_length)).astype(np.uint16)
g6 = (green >> (8 - green_length)).astype(np.uint16)
b5 = (blue  >> (8 - blue_length)).astype(np.uint16)

rgb565 = (r5 << red_offset) | (g6 << green_offset) | (b5 << blue_offset)

print(f"Writing to {sys.argv[1]}...")
rgb565.tofile(sys.argv[1])

exit(0)



