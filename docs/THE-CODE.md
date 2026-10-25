# The code

## One dead loop, and the whole machine in the interrupt

INIT (0x4010) leaves a `jp 0x4043` in the H.KEYI hook and falls into a `jr` to
itself. From there **the main program does nothing**: the entire game runs inside
the per-frame interrupt.

0x40A5 reads the 0xE000 / 0xE001 pair — the state and the sub-state — and
dispatches through 0x4071, which is a `pop hl / add a,a / jp (hl)`: the table of
eight states sits **right after the CALL**, at 0x40C9, so the return address is
itself the pointer to the table. Inside each state, `djnz` chains split the
sub-states.

## The gameplay frame

0x4540 does the whole frame: dumps the sprites to VRAM, advances the background,
moves the plane and the wave, and walks the **seven object slots** at 0xE200, 16
bytes each. Each slot carries its type, and 0x534F dispatches it with a
`push bc / ret` through the table of **21 routines** at 0x535F.

## The landscape is compressed, and drawn bottom-up

There is **a single 1920-row stage that repeats**, with the difficulty climbing
(0xE1D3, capped at 2). `PASO_DE_FONDO` (0x5837) redraws it whole once every
sixteen frames, and the fine scroll comes out of a table trick:

- **0x58FF** — the map: 244 bytes, one strip code (0 to 19) per **eight rows**;
  the index is `position / 8`.
- **0x59F3** — twenty pointers, one per strip type.
- **0x5A1B** — twenty sub-tables of **eight** pointers. The index is
  `2 * (position and 7)`: these are the eight ways of starting the same strip
  **offset by zero to seven rows**. That is the scroll.
- **0x5B5B** — the 160 scripts. The command byte: `0x00` closes the row and moves
  up one, **bit 7 set** copies that many cells verbatim, `0x01..0x7F` repeats the
  next one, and `0xFF` ends the strip and asks the map for the next.

It is written into the name table **bottom-up from 0x3AE1**, in 24 rows of **23
columns**: the eight on the right are the score panel.

The landscape characters are 0x40 to 0xA7, with patterns at 0x6DCA and colours at
0x702B. Characters 0x00 to 0x0F **have no pattern at all**: 0x4B71 gives each one
a solid colour, and they are the sea and the flatlands.

## Two in-house decompressors

The graphics are all compressed, with two of the house's own interpreters: 0x439C
writes to VRAM and 0x43D8 to the name table. The second has a nice touch:
entering at 0x43F3 it writes zeros instead of the data, so **the same script both
paints and erases**.

## The sound is Konami's three-channel player

0x79D8 and 0x7A7A drive the house PSG player, with **twelve** bytes of state per
channel —`ld de,0x000C` at 0x7A89, and the bases 0xE01A, 0xE026 and 0xE032 sit
twelve apart—. It is the same framework Konami spread across its MSX
cartridges.

## Code shared with other Konami cartridges

This disassembly has been compared, instruction by instruction, with
every other Konami one in the series. A block counts when the same
instructions, at least six of them from a label to its `ret` or its
unconditional jump, are in both cartridges; the addresses are left
aside, because they change from one cartridge to the next. Of the
other 57, **54** have at least one block in common with this one;
these are the ones that share the most:

| Cartridge | Blocks | Instructions | For example (here = there) |
|---|---:|---:|---|
| [Yie Ar Kung-Fu](https://antxiko.github.io/YieArKungFu-disassembly/) | 26 | 356 | `PASO_DE_ESTADO` (0x40A5) = `un_cuadro_de_juego` |
| [Hyper Sports 3](https://antxiko.github.io/HyperSports3-disassembly/) | 17 | 233 | `LEE_TECLADO` (0x4479) = `teclado_del_jugador_1` |
| [Yie Ar Kung-Fu II](https://antxiko.github.io/YieArKungFu2-disassembly/) | 17 | 180 | `LEE_TECLADO` (0x4479) = `lee_las_filas_7_y_8_del_teclado` |
| [Hyper Sports 2](https://antxiko.github.io/HyperSports2-disassembly/) | 16 | 224 | `REPARTE_CANALES` (0x7A07) = `SOLO_SI_PESA_MAS` |
| [Mopi Ranger](https://antxiko.github.io/MopiRanger-disassembly/) | 16 | 211 | `SUMA_PUNTOS` (0x424C) = `suma_al_marcador` |
| [The Goonies](https://antxiko.github.io/Goonies-disassembly/) | 15 | 184 | `PINTA_DOS_CIFRAS` (0x42F0) = `escribe_en_bcd` |
| [Knightmare](https://antxiko.github.io/Knightmare-disassembly/) | 15 | 162 | `INTERRUPCION` (0x4043) = `cada_cuadro` |
| [Konami’s Soccer](https://antxiko.github.io/KonamisSoccer-disassembly/) | 14 | 124 | `PASO_CORTINILLA` (0x4505) = `sube_el_logotipo_una_fila` |
| [Konami's Ping Pong](https://antxiko.github.io/KonamisPingPong-disassembly/) | 13 | 140 | `LEE_TECLADO` (0x4479) = `lee_teclado_1` |
| [Hyper Rally](https://antxiko.github.io/HyperRally-disassembly/) | 12 | 124 | `INTERRUPCION` (0x4043) = `INT` |

The whole matrix, the 58 cartridges against each other, is on
[The routines](https://antxiko.github.io/MSX-disassembly-database/THE-ROUTINES.html) in the series database, along
with the method and the program that measures it.
