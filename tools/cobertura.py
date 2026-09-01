#!/usr/bin/env python3
"""Recorre TODOS los datos del cartucho desde sus raices y dice que queda suelto.

Es el control que hace falta para el presupuesto: en vez de mirar un volcado y
suponer, se sigue cada puntero desde el codigo que lo usa y se marca lo que se
gasta de verdad. Lo que quede sin marcar es lo que hay que ir a mirar.

Formatos que sabe recorrer (todos salidos de leer el codigo que los lee):
  guion largo   0x4D09   [N] y N ordenes de cinco tipos
  guion corto   0x4AFE   [dirVRAM][bytes][0xFE n b]*[0xFF], bloque tras bloque
  lista         0x425A   [N] y N guiones largos seguidos
  rotulo        0x4C63   tipo 0: [0][len][bytes con 0x11 n v]
                         tipo!=0: lista de glifos hasta 0xFF
  patron 8      op4      ocho bytes sueltos
"""
import sys

rom = open(sys.argv[1], "rb").read()
ORG = int(sys.argv[2], 0)
B = lambda a: rom[a - ORG] if 0 <= a - ORG < len(rom) else 0
W = lambda a: B(a) | (B(a + 1) << 8)

marca = {}


def m(a, f, q):
    if a not in marca or marca[a][0] < f:
        marca[a] = (f, q)


def rotulo(p):
    ini = p
    t = B(p); p += 1
    if t == 0:
        c = B(p) or 256
        while c > 0:
            p += 1
            if B(p) == 0x11:
                c -= min(B(p + 1) or 256, c)
                p += 2
            else:
                c -= 1
        p += 1
    else:
        while B(p) != 0xFF:
            p += 1
        p += 1
    m(ini, p, "rotulo")
    return p


def largo(p):
    ini = p
    n = B(p); p += 1
    for _ in range(n):
        op = B(p); p += 1
        if op == 0:
            k = B(p); p += 1
            for _ in range(k):
                p += 2
                c = B(p) or 256; p += 1
                while c > 0:
                    if B(p) == 0x11:
                        c -= min(B(p + 1) or 256, c); p += 3
                    else:
                        c -= 1; p += 1
        elif op == 1:
            k = B(p)
            for _ in range(k):
                p += 3
                while B(p) != 0xFF:
                    p += 1
            p += 1
        elif op == 2:
            k = B(p); p += 3
            for _ in range(k):
                rotulo(W(p)); p += 2
        elif op == 3:
            k = B(p); p += 2
            for _ in range(k):
                p += 2
            p += 1
        else:
            p += 2
            c = B(p); p += 1
            s = W(p); p += 2
            m(s, s + 8, "patron de 8")
    m(ini, p, "guion largo")
    return p


def corto(p):
    ini = p
    while True:
        p += 2
        while True:
            v = B(p)
            if v == 0xFE:
                p += 3
            elif v == 0xFF:
                p += 1
                break
            else:
                p += 1
        if B(p) == 0xFF:
            p += 1
            break
    m(ini, p, "guion corto")
    return p


def lista(p):
    ini = p
    n = B(p); p += 1
    for _ in range(n):
        p = largo(p)
    m(ini, p, "lista de guiones")
    return p


# --- las raices, cada una con el sitio del codigo que la carga
# Uso: cobertura.py <rom> <org> <titulo> <marco> <tablaA> <menu> <lo> <hi>
#      <corto1> <corto2> ...
av = sys.argv[3:]
TITULO, MARCO, TABLA, MENU = (int(x, 0) for x in av[0:4])
LO, HI = int(av[4], 0), int(av[5], 0)
largo(TITULO)
largo(MARCO)
for i in range(1, 5):                           # tabla A: un guion largo
    largo(W(TABLA + 2 * i))
for i in range(1, 5):                           # tabla B: una lista
    lista(W(TABLA + 8 + 2 * i))
for i in range(1, 5):                           # tabla C: un guion corto
    corto(W(TABLA + 16 + 2 * i))
p = MENU                                        # cinco grupos seguidos
for _ in range(5):
    p = corto(p)
for a in av[6:]:                                # guiones cortos sueltos
    corto(int(a, 0))

lo, hi = LO, HI
for a in sorted(marca):
    f, q = marca[a]
    print("    %-18s %04X..%04X  (%d B)" % (q, a, f - 1, f - a))
print()
usado = bytearray(0x4000)
for a, (f, _q) in marca.items():
    for i in range(a, f):
        usado[i - ORG] = 1
h = None
for i in range(lo, hi):
    if not usado[i - ORG] and h is None:
        h = i
    elif usado[i - ORG] and h is not None:
        print("    SUELTO %04X..%04X (%d B)" % (h, i - 1, i - h))
        h = None
if h is not None:
    print("    SUELTO %04X..%04X (%d B)" % (h, hi - 1, hi - h))
