# En el emulador

Los dibujos de esta web salen de la ROM, no del emulador. Pero **mirar una imagen
no basta para creérsela**: en esta serie se vuelca la VRAM de openMSX y se compara
byte a byte contra lo que monta el Python. Si cuadran, el formato está bien leído.

## Cargarlo

    openmsx -machine Philips_VG_8020 -cart skyjaguar.rom

## Los guiones de medida

En `tools/` hay guiones de TCL para openMSX que sirven para comprobar, no para
ilustrar: vuelcan los 16 KB de VRAM y los registros del VDP, y salen solos con un
perro guardián de tiempo real para que un guión roto no deje el emulador colgado.

Dos cosas aprendidas a base de perder tiempo, por si escribes los tuyos: en TCL no
pongas comillas anidadas dentro de una cadena (usa `{VDP regs}`), y **no pongas
puntos de ruptura que disparen en cada fotograma** dentro de rutinas de dibujo,
porque ahogan al emulador y no llega ni a arrancar la partida.
