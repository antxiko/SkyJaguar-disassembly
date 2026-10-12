# La música

Todo lo que suena aquí sale de ejecutar el motor de sonido del cartucho (`VUELCA_SONIDO`, 0x7A7A, y `PONE_SONIDO`, 0x79E5, que le reparte los canales; lo llama la interrupción en 0x4047) en un Z80 emulado, cuadro a cuadro y a 60 por segundo, igual que lo llama el juego. Lo que el motor escribe en el PSG pasa a sonido con un AY-3-8910 (`tools/musica.py`). Cada MP3 es la pieza entera hasta donde vuelve a empezar, más 8 segundos de la vuelta apagándose; las que no se repiten acaban donde acaba el motor.

## Cotejado con openMSX

Las escrituras al PSG se han comparado cuadro a cuadro con las de openMSX (C-BIOS MSX1 japonés). En todos los cuadros el PSG queda igual:

- la música de arranque (0x93) entera, 293 cuadros, tres veces: pedida a la fuerza y dos tal como el juego la pide.

El timbre no está cotejado: es el de un AY-3-8910 de manual, no una grabación del emulador. Las sondas están en `tools/omsx_psg.tcl` y `tools/coteja_psg.py`.

## Cómo se pide una pieza

`PIDE_SONIDO` recibe el número en A y solo suena con partida en marcha (bit 6 de 0xE002) y sin el avión muriendo; `PONE_SONIDO` salta esas comprobaciones y reparte el sonido entre los canales. Los números bajos son efectos y del 0x88 en adelante hay música. Cada canal ocupa doce bytes desde 0xE018 y 0xE03C guarda la copia del mezclador del PSG, que el arranque deja en 0xB8. Las pistas «de la tabla» están en la tabla de pistas pero ninguna rutina las pide con un `ld a`; se omiten la 0x9A y la 0x9B, de minutos de duración y casi sin notas. Solo hay una pieza cotejada con openMSX, la 0x93; las demás salen del mismo motor, pero no se ha comparado cada una.

## Las músicas

**La música de arranque** (0x93)

Lo pide `ESTADO_3`; dura 4,9 s.

<audio controls preload="none" src="../audio/musica_93.mp3?v=67a6c528"></audio>

**El fin de partida** (0x99)

Lo pide `FIN_DE_PARTIDA`; dura 4,7 s.

<audio controls preload="none" src="../audio/musica_99.mp3?v=25bbc404"></audio>

**La música del gigante** (0x88)

Lo pide `GIGANTE_EPISODIO_2`: mantiene sonando la música del gigante; dura 3,2 s.

<audio controls preload="none" src="../audio/musica_88.mp3?v=035f884e"></audio>

**La pieza del gigante** (0x91)

Lo pide `MONTA_GIGANTE`; dura 5,4 s.

<audio controls preload="none" src="../audio/musica_91.mp3?v=cc936b00"></audio>

**El gigante, una sola vez** (0x96)

Lo pide `GIGANTE_SUENA_UNA_VEZ`; dura 4,5 s.

<audio controls preload="none" src="../audio/musica_96.mp3?v=d7dfa7f4"></audio>

**Pista 0x92 de la tabla** (0x92)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 2,7 s.

<audio controls preload="none" src="../audio/musica_92.mp3?v=3c6df860"></audio>

**Pista 0x94 de la tabla** (0x94)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 4,8 s.

<audio controls preload="none" src="../audio/musica_94.mp3?v=dbab2b52"></audio>

**Pista 0x95 de la tabla** (0x95)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 4,8 s.

<audio controls preload="none" src="../audio/musica_95.mp3?v=4474f2c3"></audio>

**Pista 0x97 de la tabla** (0x97)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 4,5 s.

<audio controls preload="none" src="../audio/musica_97.mp3?v=4d3e3a65"></audio>

**Pista 0x98 de la tabla** (0x98)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 4,7 s.

<audio controls preload="none" src="../audio/musica_98.mp3?v=dcf17789"></audio>
