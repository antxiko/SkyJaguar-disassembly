#!/usr/bin/env python3
"""La musica del cartucho, ejecutando su motor de sonido (ver motor_musica.py).

Pide el sonido con `PONE_SONIDO` (0x79E5, A = numero; `PIDE_SONIDO`, 0x79D8,
solo suena con partida) y corre `VUELCA_SONIDO` (0x7A7A), que la interrupcion
llama cada cuadro (0x4047). Tres voces de 12 bytes desde 0xE018; la copia del
registro 7 del PSG, en 0xE03C.
Uso:  musica.py registros 0x93 [cuadros] | mp3 0x93 f.mp3 | todas docs/audio
      musica.py barrido 0x80 0xFF | emu
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import motor_musica  # noqa: E402
from motor_musica import P  # noqa: E402

TABLA = "ninguna llamada directa: está en la tabla de pistas"

PIEZAS = [
    P(0x93, "La música de arranque", "The start-up tune", "`ESTADO_3`"),
    P(0x99, "El fin de partida", "Game over", "`FIN_DE_PARTIDA`"),
    P(0x88, "La música del gigante", "The giant's tune",
      "`GIGANTE_EPISODIO_2`: mantiene sonando la música del gigante"),
    P(0x91, "La pieza del gigante", "The giant tune", "`MONTA_GIGANTE`"),
    P(0x96, "El gigante, una sola vez", "The giant, once",
      "`GIGANTE_SUENA_UNA_VEZ`"),
] + [P(n, "Pista 0x%02X de la tabla" % n, "Table track 0x%02X" % n, TABLA)
     for n in (0x92, 0x94, 0x95, 0x97, 0x98)]

PAGINA = motor_musica.pagina_basica(
    "`VUELCA_SONIDO`, 0x7A7A, y `PONE_SONIDO`, 0x79E5, que le reparte los "
    "canales; lo llama la interrupción en 0x4047",
    "`VUELCA_SONIDO`, 0x7A7A, and `PONE_SONIDO`, 0x79E5, which hands it the "
    "channels; the interrupt calls it at 0x4047",
    "C-BIOS MSX1 japonés",
    [("la música de arranque (0x93) entera, 293 cuadros, tres veces: pedida "
      "a la fuerza y dos tal como el juego la pide",
      "the start-up tune (0x93), whole, 293 frames, three times: forced, and "
      "twice as the game asks for it")],
    [("Cómo se pide una pieza",
      "`PIDE_SONIDO` recibe el número en A y solo suena con partida en marcha "
      "(bit 6 de 0xE002) y sin el avión muriendo; `PONE_SONIDO` salta esas "
      "comprobaciones y reparte el sonido entre los canales. Los números "
      "bajos son efectos y del 0x88 en adelante hay música. Cada canal ocupa "
      "doce bytes desde 0xE018 y 0xE03C guarda la copia del mezclador del "
      "PSG, que el arranque deja en 0xB8. Las pistas «de la tabla» están en "
      "la tabla de pistas pero ninguna rutina las pide con un `ld a`; se "
      "omiten la 0x9A y la 0x9B, de minutos de duración y casi sin notas. "
      "Solo hay una pieza cotejada con openMSX, la 0x93; las demás salen del "
      "mismo motor, pero no se ha comparado cada una.",
      "How a piece is asked for",
      "`PIDE_SONIDO` takes the number in A and only sounds with a game "
      "running (bit 6 of 0xE002) and the plane not dying; `PONE_SONIDO` "
      "skips those checks and shares the sound among the channels. Low "
      "numbers are effects and from 0x88 up there is music. Each channel "
      "takes twelve bytes from 0xE018 and 0xE03C holds the copy of the PSG "
      "mixer, which start-up leaves at 0xB8. The tracks marked «in the "
      "table» are in the track table but no routine asks for them with an "
      "`ld a`; 0x9A and 0x9B, minutes long and nearly without notes, are left "
      "out. Only one piece has been checked against openMSX, 0x93; the rest "
      "come out of the same engine but each has not been compared.")])

CFG = dict(rom="skyjaguar.rom", org=0x4000, frame=0x7A7A, pide=0x79E5,
           ram=(0xE018, 0xE03D), ram0=[(0xE03C, 0xB8)],
           excluye=[0xE021, 0xE02D, 0xE039], hz=60, psg0={7: 0xB8},
           piezas=PIEZAS, pagina=PAGINA, cotejado=[(0x93, 293, None)])

if __name__ == "__main__":
    sys.exit(motor_musica.main(CFG, sys.argv[1:]))
