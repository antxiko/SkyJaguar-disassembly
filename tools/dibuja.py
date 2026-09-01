#!/usr/bin/env python3
"""Pinta bloques de la ROM en PNG, para MIRARLOS en vez de leerlos.

Leer un volcado de graficos no basta: en esta serie, dibujarlos ha destapado
errores que leer no cazo. Aqui se pintan tres cosas:

  fuente  <dir> <n>    n glifos de 8x8 seguidos
  sprites <dir> <n>    n patrones de sprite de 16x16 (32 bytes, cuatro cuartos
                       de 8x8 en el orden del VDP: izq-arriba, izq-abajo,
                       der-arriba, der-abajo)
  crudo   <dir> <n>    n tiras de 8 bytes, sin suponer nada

Uso: dibuja.py <rom> <org> <salida> <modo> <dir> <n> [<modo> <dir> <n> ...]
"""
import os
import struct
import sys
import zlib


def png(w, h, px, fn):
    raw = b"".join(b"\0" + bytes(px[y * w * 3:(y + 1) * w * 3]) for y in range(h))

    def chunk(t, d):
        return (struct.pack(">I", len(d)) + t + d
                + struct.pack(">I", zlib.crc32(t + d) & 0xFFFFFFFF))
    open(fn, "wb").write(b"\x89PNG\r\n\x1a\n"
                         + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0))
                         + chunk(b"IDAT", zlib.compress(raw)) + chunk(b"IEND", b""))


def lienzo(w, h):
    return bytearray(b"\x20\x20\x30" * (w * h))


def pon(px, w, x, y, on):
    i = (y * w + x) * 3
    c = (0xF0, 0xF0, 0xE0) if on else (0x20, 0x20, 0x30)
    px[i:i + 3] = bytes(c)


def rejilla(px, w, x, y, esc):
    for k in range(esc):
        pon(px, w, x, y + k, False)


def tile(px, w, ox, oy, datos, esc):
    for f in range(8):
        v = datos[f]
        for c in range(8):
            on = (v >> (7 - c)) & 1
            for a in range(esc):
                for b in range(esc):
                    pon(px, w, ox + c * esc + b, oy + f * esc + a, on)


def main():
    rom = open(sys.argv[1], "rb").read()
    org = int(sys.argv[2], 0)
    sal = sys.argv[3]
    os.makedirs(sal, exist_ok=True)
    args = sys.argv[4:]
    while args:
        modo, d, n = args[0], int(args[1], 0), int(args[2], 0)
        args = args[3:]
        esc = 3
        if modo == "sprites":
            cols = 8
            filas = (n + cols - 1) // cols
            w, h = cols * 16 * esc, filas * 16 * esc
            px = lienzo(w, h)
            for i in range(n):
                a = d - org + 32 * i
                ox, oy = (i % cols) * 16 * esc, (i // cols) * 16 * esc
                tile(px, w, ox, oy, rom[a:a + 8], esc)
                tile(px, w, ox, oy + 8 * esc, rom[a + 8:a + 16], esc)
                tile(px, w, ox + 8 * esc, oy, rom[a + 16:a + 24], esc)
                tile(px, w, ox + 8 * esc, oy + 8 * esc, rom[a + 24:a + 32], esc)
        else:
            cols = 16
            filas = (n + cols - 1) // cols
            w, h = cols * 8 * esc, filas * 8 * esc
            px = lienzo(w, h)
            for i in range(n):
                a = d - org + 8 * i
                tile(px, w, (i % cols) * 8 * esc, (i // cols) * 8 * esc,
                     rom[a:a + 8], esc)
        fn = os.path.join(sal, "%s_%04X.png" % (modo, d))
        png(w, h, px, fn)
        print("  %s  %d de %04X" % (fn, n, d))


main()
