# El código

## Un bucle muerto, y toda la máquina en la interrupción

INIT (0x4010) deja un `jp 0x4043` en el gancho H.KEYI y cae en un `jr` a sí
mismo. A partir de ahí **el programa principal no hace nada**: el juego entero
corre dentro de la interrupción de cada cuadro.

0x40A5 lee la pareja 0xE000 / 0xE001 —el estado y el subestado— y despacha por
0x4071, que es un `pop hl / add a,a / jp (hl)`: la tabla de ocho estados va
**pegada al CALL**, en 0x40C9, así que la propia dirección de retorno es el
puntero a la tabla. Dentro de cada estado, los subestados los reparten cadenas de
`djnz`.

## El fotograma de partida

0x4540 hace el cuadro entero: vuelca los sprites a la VRAM, avanza el fondo,
mueve el avión, la oleada, y recorre los **siete huecos de objeto** de 0xE200, de
16 bytes cada uno. Cada hueco lleva su tipo, y 0x534F lo despacha con un
`push bc / ret` por la tabla de **21 rutinas** de 0x535F.

## El paisaje va comprimido, y se dibuja de abajo arriba

Hay **una sola fase, de 1920 filas, que se repite** con la dificultad subiendo
(0xE1D3, con tope 2). `PASO_DE_FONDO` (0x5837) la redibuja entera una vez cada
dieciséis fotogramas, y el desplazamiento fino sale de un truco de tablas:

- **0x58FF** — el mapa: 244 bytes, un código de tira (0 a 19) por cada **ocho
  filas**; el índice es `posición / 8`.
- **0x59F3** — veinte punteros, uno por tipo de tira.
- **0x5A1B** — veinte subtablas de **ocho** punteros. El índice es
  `2 * (posición y 7)`: son las ocho maneras de empezar la misma tira
  **desplazada de cero a siete filas**. Ahí está el scroll.
- **0x5B5B** — los 160 guiones. El byte de mando: `0x00` cierra la fila y sube
  una, el **bit 7 puesto** copia tantas celdas tal cual, `0x01..0x7F` repite la
  siguiente, y `0xFF` acaba la tira y pide la siguiente del mapa.

Se vuelca en la tabla de nombres **de abajo arriba desde 0x3AE1**, en 24 filas de
**23 columnas**: las ocho de la derecha son el panel del marcador.

Los caracteres del paisaje son los 0x40 a 0xA7, con los patrones en 0x6DCA y los
colores en 0x702B. Los 0x00 a 0x0F **no tienen patrón**: 0x4B71 le da a cada uno
un color entero, y son el mar y los llanos.

## Dos descompresores de la casa

Los gráficos van todos comprimidos, con dos intérpretes propios: 0x439C vuelca a
la VRAM y 0x43D8 a la tabla de nombres. El segundo tiene un detalle bonito:
entrando por 0x43F3 escribe ceros en vez del dato, así que **el mismo guión sirve
para pintar y para borrar**.

## El sonido es el reproductor de tres canales de Konami

0x79D8 y 0x7A7A mueven el reproductor PSG de la casa, con **doce** bytes de estado
por canal —`ld de,0x000C` en 0x7A89, y las bases 0xE01A, 0xE026 y 0xE032 van de
doce en doce—. Es el mismo armazón que Konami repartía entre sus
cartuchos de MSX.
