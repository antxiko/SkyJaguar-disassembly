#!/usr/bin/env python3
"""Busca tiras de bytes IDENTICAS entre dos cartuchos.

Konami reutilizaba codigo entre sus juegos de MSX. Eso, si es cierto, se tiene
que ver en el binario: las mismas rutinas dan los mismos bytes. Esto lo mide en
vez de suponerlo.

Metodo: se indexan todos los trozos de K bytes del primer cartucho y se recorre
el segundo; cada coincidencia se estira a izquierda y derecha hasta donde
llega. Lo que sale son tiras MAXIMALES, sin solapes.

Cuidado al leer el resultado: una tira de bytes iguales puede ser una rutina
compartida, pero tambien un trozo de relleno (00 repetido) o una tabla que
coincide por casualidad. Por eso se descarta lo que tenga menos de 4 valores
distintos, y la longitud minima es alta.

Uso: comun_konami.py <romA> <orgA> <romB> <orgB> [minimo]
"""
import sys
from collections import defaultdict

K = 12                                   # semilla: 12 bytes iguales


def tiras(a, b, minimo):
    idx = defaultdict(list)
    for i in range(len(a) - K + 1):
        idx[a[i:i + K]].append(i)
    res, jb = [], 0
    while jb <= len(b) - K:
        cand = idx.get(b[jb:jb + K])
        if not cand:
            jb += 1
            continue
        mejor = (0, 0, 0)
        for ia in cand:
            i, j = ia, jb
            while i > 0 and j > 0 and a[i - 1] == b[j - 1]:
                i -= 1
                j -= 1
            f1, f2 = ia + K, jb + K
            while f1 < len(a) and f2 < len(b) and a[f1] == b[f2]:
                f1 += 1
                f2 += 1
            if f1 - i > mejor[0]:
                mejor = (f1 - i, i, j)
        ln, ia, jbb = mejor
        if ln >= minimo and len(set(b[jbb:jbb + ln])) >= 4:
            res.append((ln, ia, jbb))
        jb = jbb + max(ln, 1)
    return res


def main():
    ra, oa, rb, ob = sys.argv[1], int(sys.argv[2], 16), sys.argv[3], int(sys.argv[4], 16)
    minimo = int(sys.argv[5]) if len(sys.argv) > 5 else 24
    a, b = open(ra, 'rb').read(), open(rb, 'rb').read()
    res = sorted(tiras(a, b, minimo), reverse=True)
    total = sum(r[0] for r in res)
    for ln, ia, jb in res:
        print("%5d B   A 0x%04X-0x%04X   B 0x%04X-0x%04X"
              % (ln, oa + ia, oa + ia + ln - 1, ob + jb, ob + jb + ln - 1))
    print("---- %d tiras, %d bytes en comun (%.1f %% de B)"
          % (len(res), total, 100.0 * total / len(b)))


main()
