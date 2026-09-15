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
a ojo: salen de las cuatro marcas de verdad que hay en la serie -las de los
cartuchos RC-701 (20 bytes), RC-718 (8), RC-729 (6) y RC-742
(8)- y de los falsos positivos que aparecieron al aflojarlos:
  - la longitud N esta entre 4 y 32. Con el minimo en 2, RC-700 y RC-716 daban un "RC-791" de dos bytes en mitad de la ROM: ni existe
    ese numero ni es el suyo. Casualidad, no marca.
  - el 0xAA cae al FINAL: el ultimo byte del fichero, el ultimo que no es
    relleno 0xFF, o el final de un banco de 16 KB. Las de la serie cierran en
    0x7FFF y la del RC-742 en 0xBFFF, y segun lo que publico Pazos el bloque
    vive en el offset 0x3FF0, o sea el final de la pagina.
  - el RC en BCD es un byte con las dos cifras validas (cada nibble <= 9)
  - los N bytes del titulo son o 0x00 (espacio) o >= 0x80, que es donde
    empiezan los codigos de la casa. NO se exige que el kana este en la tabla
    conocida: la marca del RC-718 usa 0xBA y 0xB8, que no lo estan, y una
    comprobacion mas estrecha la rechazaba (probado, fallaba el control)
  - DIGITOS. el cartucho RC-733 rompio esa regla y este rastreador lo daba
    por "sin marca": su marca cierra en el ULTIMO byte del fichero, son trece
    bytes y el primero de ellos, leyendo hacia atras, es 0x33, que es un '3' en
    ASCII y no un codigo de la casa. El resto si es kana:

        33 00 91 ba b8 9d 8c 00 ba b8 99 81 99   <- como estan en la ROM
        HA I HA(o) - _ SU HO(o) - TU _ 3         <- al reves, ya decodificado
        = ハイパースポーツ 3

    Konami escribio el numero de la secuela con el digito ASCII pelado. Asi que
    0x30..0x39 pasa el filtro, PERO no cuenta como kana: un titulo que sea todo
    digitos no es una marca. El control de la serie sigue dando lo mismo con el
    cambio, ROM por ROM.
  - no es todo espacios

Uso: busca_marca_konami.py <rom> [<rom> ...]
"""
import os
import sys

KANA = ("A I U E O KA KI KU KE KO SA SI SU SE SO TA TI TU TE TO "
        "NA NI NU NE NO HA HI HU HE HO MA MI MU ME MO YA YU YO "
        "RA RI RU RE RO WA N").split()
# Los kana pequenos y los signos van detras de los 45 basicos, del 49 en
# adelante. Cada uno se ha DESPEJADO con una marca ya conocida de la serie, no
# supuesto por el orden del silabario -que no lo siguen-. Los cartuchos se citan
# por numero de catalogo, que es como vienen dentro de la propia marca:
#
#   49 ya   RC-728  MO HI o RE N SI " [49] [58]        -> モピレンジャー
#   50 yu   RC-724  YA KI [50] U                       -> ヤキュウ
#   52 i    RC-742  KU " RA TE " [52] U SU             -> グラディウス
#   54 a    RC-730  RO [58] TO " _ HU [54] I TA [58]   -> ロードファイター
#   57 .    RC-725  I [58] [57] A RU [57] KA N HU [58] -> イー・アル・カンフー
#   58 -    los tres de arriba a la vez (alargamiento)
#
# Los otros cuatro ya venian de antes: 51 yo, 53 tsu, 55 dakuten, 56 handakuten.
EXTRA = {49: "ya", 50: "yu", 51: "yo", 52: "i", 53: "tsu", 54: "a",
         55: '"', 56: "o", 57: ".", 58: "-"}


def caracter(v):
    if v == 0:
        return " "
    i = v - 0x80
    if 0 <= i < len(KANA):
        return KANA[i]
    if i in EXTRA:
        return EXTRA[i]
    if 0x30 <= v <= 0x39:                        # el '3' del RC-733
        return chr(v)
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
        if 0x30 <= v <= 0x39:                    # ver DIGITOS, abajo
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
