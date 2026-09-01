#!/usr/bin/env python3
"""Rastrea la marca oculta de Konami en TODA la ROM, no solo al final.

El hallazgo es de Manuel Pazos (@ManuelPazosMSX), septiembre de 2021: Konami
escondio en muchos de sus cartuchos de MSX el numero de catalogo y el titulo en
katakana. El formato, leyendo hacia adelante:

    [titulo, N bytes, EN ORDEN INVERSO]  [N]  [las dos cifras del RC en BCD]  [0xAA]

`tools/marca_konami.py` solo mira el final del fichero, saltando el relleno
0xFF. Pero la marca no tiene por que estar ahi: puede quedar delante de un
bloque de datos, o de relleno que no sea 0xFF. Asi que esto prueba TODAS las
posiciones de 0xAA de la ROM y se queda con las que dan una marca creible.

Que se considera creible, para no tragarse coincidencias. Los umbrales NO son
a ojo: salen de las cuatro marcas de verdad que hay en la serie -Antarctic
RC-701 (20 bytes), Hyper Rally RC-718 (8), Pippols RC-729 (6) y Nemesis RC-742
(8)- y de los falsos positivos que aparecieron al aflojarlos:
  - la longitud N esta entre 4 y 32. Con el minimo en 2, Athletic Land y
    Cabbage Patch daban un "RC-791" de dos bytes en mitad de la ROM: ni existe
    ese numero ni es el suyo. Casualidad, no marca.
  - el 0xAA cae al FINAL: el ultimo byte del fichero, el ultimo que no es
    relleno 0xFF, o el final de un banco de 16 KB. Las de la serie cierran en
    0x7FFF y la de Nemesis en 0xBFFF, y segun lo que publico Pazos el bloque
    vive en el offset 0x3FF0, o sea el final de la pagina.
  - el RC en BCD es un byte con las dos cifras validas (cada nibble <= 9)
  - los N bytes del titulo son o 0x00 (espacio) o >= 0x80, que es donde
    empiezan los codigos de la casa. NO se exige que el kana este en la tabla
    conocida: la marca de Hyper Rally usa 0xBA y 0xB8, que no lo estan, y una
    comprobacion mas estrecha la rechazaba (probado, fallaba el control)
  - no es todo espacios

Uso: busca_marca_konami.py <rom> [<rom> ...]
"""
import os
import sys

KANA = ("A I U E O KA KI KU KE KO SA SI SU SE SO TA TI TU TE TO "
        "NA NI NU NE NO HA HI HU HE HO MA MI MU ME MO YA YU YO "
        "RA RI RU RE RO WA N").split()
EXTRA = {51: "yo", 53: "tsu", 55: '"', 56: "o"}


def caracter(v):
    if v == 0:
        return " "
    i = v - 0x80
    if 0 <= i < len(KANA):
        return KANA[i]
    if i in EXTRA:
        return EXTRA[i]
    return "<%02X>" % v


def creible(rom, i):
    """Si en `i` hay un 0xAA que cierra una marca, devuelve (rc, n, titulo)."""
    if rom[i] != 0xAA or i < 4:
        return None
    rc, n = rom[i - 1], rom[i - 2]
    if not (4 <= n <= 32) or n > i - 2:
        return None
    # las de verdad cierran al final: ultimo byte, ultimo que no es relleno
    # 0xFF, o final de banco de 16 KB
    fin = len(rom) - 1
    while fin > 0 and rom[fin] == 0xFF:
        fin -= 1
    if i != len(rom) - 1 and i != fin and (i + 1) % 0x4000 != 0:
        return None
    if (rc >> 4) > 9 or (rc & 15) > 9:          # BCD de verdad
        return None
    tit = rom[i - 2 - n:i - 2]
    kana = 0
    for v in tit:
        if v == 0:
            continue
        if v < 0x80:                             # los codigos de la casa van de 0x80 arriba
            return None
        kana += 1
    if kana < 2:                                 # no cuentan los todo-espacios
        return None
    return rc, n, bytes(reversed(tit))


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        return 2
    alguna = False
    for fn in sys.argv[1:]:
        rom = open(fn, "rb").read()
        nombre = os.path.basename(fn)
        hallazgos = [(i, m) for i in range(len(rom))
                     for m in [creible(rom, i)] if m]
        if not hallazgos:
            print("  %-52s sin marca en toda la ROM (%d bytes rastreados)"
                  % (nombre[:52], len(rom)))
            continue
        alguna = True
        for i, (rc, n, tit) in hallazgos:
            print("  %-52s RC-7%02X  %d bytes  cierra en 0x%04X"
                  % (nombre[:52], rc, n, 0x4000 + i))
            print("  %-52s %s" % ("", " ".join(caracter(v) for v in tit)))
    return 0 if alguna else 1


sys.exit(main())
