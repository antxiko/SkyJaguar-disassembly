#!/usr/bin/env python3
"""Compara dos cartuchos Konami SIN QUE LAS DIRECCIONES ESTORBEN.

comun_konami.py compara bytes crudos, y por eso solo ve rutinas compartidas si
ademas cayeron en la MISMA direccion. Konami reusaba codigo entre cartuchos que
no comparten mapa de memoria, asi que ese metodo se deja fuera lo que mas
interesa.

Aqui se traza cada ROM desde su INIT, se decodifican las instrucciones y se
construye una tira NORMALIZADA: los opcodes van tal cual y los operandos de
DIECISEIS BITS -que son los que llevan direcciones- se ponen a cero. Los saltos
relativos se dejan, que ya son relativos. Sobre esa tira se buscan los tramos
comunes maximales.

Lo que sale se lee asi: un tramo largo de instrucciones identicas salvo las
direcciones es la MISMA RUTINA reensamblada en otro sitio.

Uso: comun_normalizado.py <romA> <orgA> <romB> <orgB> [minimo_instrucciones]
"""
import os
import sys
from collections import defaultdict

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from z80trace import Tracer                                   # noqa: E402

# Opcodes cuyos dos ultimos bytes son una direccion o un inmediato de 16 bits.
ABS16 = ({0x01, 0x11, 0x21, 0x31, 0x22, 0x2A, 0x32, 0x3A, 0xC3, 0xCD}
         | {0xC2, 0xCA, 0xD2, 0xDA, 0xE2, 0xEA, 0xF2, 0xFA}
         | {0xC4, 0xCC, 0xD4, 0xDC, 0xE4, 0xEC, 0xF4, 0xFC})


def _ilen(rom, org, a):
    t = Tracer(rom, org)
    return t.ilen(a)


def entrada(rom):
    """INIT de la cabecera del cartucho."""
    return rom[2] | (rom[3] << 8)


def tira(path, org, traza=None):
    """Tira normalizada de una ROM.

    Si se le da el .trace.json de un desensamblado ya hecho, se usan SUS
    regiones de codigo, que es lo unico honrado: trazar a ciegas desde INIT
    deja fuera todo lo que cuelga de una tabla de saltos, y el reparto de
    coincidencias sale falseado.
    """
    rom = open(path, "rb").read()
    if traza:
        import json
        bl = json.load(open(traza))["blocks"]
        out, pos = bytearray(), []
        for k, a, b in bl:
            if k != "c":
                continue
            p = a
            while p < b:
                n = _ilen(rom, org, p)
                if not n or p + n > b:
                    break
                q = bytearray(rom[p - org:p - org + n])
                op = q[0]
                if op in ABS16 and n >= 3:
                    q[-2] = q[-1] = 0
                elif op in (0xDD, 0xFD) and n >= 4 and q[1] in ABS16:
                    q[-2] = q[-1] = 0
                elif op == 0xED and n == 4:
                    q[-2] = q[-1] = 0
                pos.append((len(out), p, n))
                out += q
                p += n
        return bytes(out), pos, len(pos)
    t = Tracer(rom, org)
    ini = [entrada(rom)]
    # el gancho de interrupcion casi siempre se instala con un `ld hl,nn` que
    # apunta a codigo del propio cartucho; se anaden todos los destinos de
    # `ld hl,nn` que caigan dentro para que el trazado no se quede corto
    t.trace(ini)
    extra = []
    for a in sorted(t.starts):
        if rom[a - org] == 0x21:
            d = rom[a - org + 1] | (rom[a - org + 2] << 8)
            if org <= d < org + len(rom):
                extra.append(d)
    t2 = Tracer(rom, org)
    t2.trace(ini + extra)
    out, pos = bytearray(), []
    for a in sorted(t2.starts):
        n = t2.ilen(a)
        if not n:
            continue
        b = bytearray(rom[a - org:a - org + n])
        op = b[0]
        if op in ABS16 and n >= 3:
            b[-2] = b[-1] = 0
        elif op in (0xDD, 0xFD) and n >= 4 and b[1] in ABS16:
            b[-2] = b[-1] = 0
        elif op == 0xED and n == 4:
            b[-2] = b[-1] = 0
        pos.append((len(out), a, n))
        out += b
    return bytes(out), pos, len(t2.starts)


def dir_de(pos, i):
    lo, hi = 0, len(pos) - 1
    while lo < hi:
        m = (lo + hi + 1) // 2
        if pos[m][0] <= i:
            lo = m
        else:
            hi = m - 1
    return pos[lo][1]


def main():
    av = [x for x in sys.argv[1:] if not x.startswith("--")]
    tz = [x[8:] for x in sys.argv[1:] if x.startswith("--traza=")]
    ra, oa, rb, ob = av[0], int(av[1], 16), av[2], int(av[3], 16)
    minimo = int(av[4]) if len(av) > 4 else 20
    A, pa, na = tira(ra, oa, tz[0] if len(tz) > 0 else None)
    B, pb, nb = tira(rb, ob, tz[1] if len(tz) > 1 else None)
    K = 16
    idx = defaultdict(list)
    for i in range(len(A) - K + 1):
        idx[A[i:i + K]].append(i)
    res, j = [], 0
    while j <= len(B) - K:
        cand = idx.get(B[j:j + K])
        if not cand:
            j += 1
            continue
        mejor = (0, 0, 0)
        for i0 in cand:
            i, k = i0, j
            while i > 0 and k > 0 and A[i - 1] == B[k - 1]:
                i -= 1
                k -= 1
            f1, f2 = i0 + K, j + K
            while f1 < len(A) and f2 < len(B) and A[f1] == B[f2]:
                f1 += 1
                f2 += 1
            if f1 - i > mejor[0]:
                mejor = (f1 - i, i, k)
        ln, i, k = mejor
        if ln >= minimo:
            res.append((ln, i, k))
        j = k + max(ln, 1)
    res.sort(reverse=True)
    total = sum(r[0] for r in res)
    for ln, i, k in res[:25]:
        print("  %5d B   A %04X   B %04X" % (ln, dir_de(pa, i), dir_de(pb, k)))
    print("  ---- %s: %d instrucciones trazadas, %d bytes normalizados"
          % (os.path.basename(ra), na, len(A)))
    print("  ---- %s: %d instrucciones trazadas, %d bytes normalizados"
          % (os.path.basename(rb), nb, len(B)))
    print("  ---- %d tramos, %d bytes en comun (%.1f %% de A, %.1f %% de B)"
          % (len(res), total, 100.0 * total / max(1, len(A)),
             100.0 * total / max(1, len(B))))


main()
