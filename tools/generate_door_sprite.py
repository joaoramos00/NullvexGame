import struct, zlib

def make_png(width, height, pixels):
    def chunk(name, data):
        c = name + data
        return struct.pack('>I', len(data)) + c + struct.pack('>I', zlib.crc32(c) & 0xFFFFFFFF)

    raw = b''
    for y in range(height):
        raw += b'\x00'
        for x in range(width):
            r, g, b, a = pixels[y][x]
            raw += bytes([r, g, b, a])

    compressed = zlib.compress(raw, 9)
    ihdr = struct.pack('>II', width, height) + bytes([8, 6, 0, 0, 0])

    data  = b'\x89PNG\r\n\x1a\n'
    data += chunk(b'IHDR', ihdr)
    data += chunk(b'IDAT', compressed)
    data += chunk(b'IEND', b'')
    return data

W, H = 32, 128
PANEL_H = 32  # 4 panels

# Color palette
SEAM      = (6,   6,  22, 255)
ACCENT    = (60, 220, 220, 255)
DARK      = (16,  16,  52, 255)
MAIN      = (22,  22,  72, 255)
TECH_LINE = (36,  80, 200, 255)
EDGE_L    = (10,  10,  32, 255)
EDGE_R    = (44,  44, 180, 255)
RIVET     = (80, 200, 255, 255)

pixels = [[None]*W for _ in range(H)]

for panel in range(4):
    by = panel * PANEL_H
    for ly in range(PANEL_H):
        y = by + ly
        for x in range(W):
            if ly < 2:
                c = SEAM
            elif ly < 5:
                c = ACCENT
            elif ly < 7:
                c = DARK
            elif ly >= PANEL_H - 2:
                c = SEAM
            elif ly >= PANEL_H - 5:
                c = ACCENT
            elif ly >= PANEL_H - 7:
                c = DARK
            elif ly == PANEL_H // 2:
                c = TECH_LINE
            elif ly == PANEL_H // 2 - 1 or ly == PANEL_H // 2 + 1:
                c = DARK
            else:
                c = MAIN

            if x == 0 or x == 1:
                c = EDGE_L
            elif x == W - 1 or x == W - 2:
                c = EDGE_R

            rivet_y = by + PANEL_H // 2
            if y == rivet_y and x in (3, W - 4):
                c = RIVET

            pixels[y][x] = c

png_data = make_png(W, H, pixels)

import os, pathlib
out_path = str(pathlib.Path(__file__).parent / 'stages' / 'door.png')
with open(out_path, 'wb') as f:
    f.write(png_data)
print("OK: door.png written")
