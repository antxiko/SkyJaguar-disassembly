# Findings

## The aiming table has two entries swapped

0x6917 holds nine firing directions, sixteen-bit (dx, dy) pairs walking a quarter
turn at radius 320. **Seven of the nine match to the bit** against `320 · sin` and
`320 · cos`. Entries **3 and 5 are swapped with each other**: entry 3 holds
(266, 177) where (178, 266) belongs, and entry 5 holds (177, 266) where
(266, 178) belongs.

This is not a coarse approximation or a rounding artefact: each one contains
**exactly** what the other should. Two of the nine enemy firing directions aim at
the mirror of their intended angle.

## Two jumps that land in the middle of an instruction, deliberately

At **0x6684**, a `jr c` lands on the **last byte** of the `ld bc,0x0300` at
0x6686 — an address that is not the start of any instruction, which is the whole
point. That byte is `0x03`, and on its own it executes as
`inc bc`. The result: with carry, BC ends up at 0xFE01; without carry the `ld`
runs and BC ends up at 0x0300. One byte saved over a `jp`.

At **0x69A1** the same trick is played with the `0x03` of `ld (hl),3`.

## Code that never runs

At **0x67F5** the code does `ld a,001h` and immediately `rra`. Rotating a 1 right
always leaves the carry **set**, so the `jr nc` at 0x67F8 never jumps and the
`ld a,0FFh` at 0x67FA always runs.

## Six routines nobody calls

Searching for `call`, `jp`, `jr` and the raw address turns up not one reference to
0x407B (swaps B bytes), 0x4085 (works out a cell address), 0x4099 (HL times 8),
0x4188 (would set state 7), 0x4392, and 0x43CE — the twin of 0x43C2 for **reading**
from VRAM: this cartridge never reads VRAM once. They are declared in the
`.entries` and come out disassembled, because they decode cleanly.

## There is a weapon upgrade, and it comes off a fixed count

Type 5 enemies do not drop their prize at random. The byte that decides what they
leave behind runs off a count, and out of every thirty-two: **number 24** drops
object 0x10, worth a thousand points, which **passes through the plane without
killing it**; and **numbers 6 and 22** drop 0x11, which raises 0xE1D5 and
**upgrades the gun** — unless it is already maxed.

The upgrade does two measurable things: you go from **two bullets to three**, and
the box your bullets hit with goes from **two pixels to twelve** (0x69E3). So it
is not only firing more: it is hitting far more easily.

## Three things the game does not tell you

**The first extra life comes at 10,000 points, and then every 40,000.** The
counter at 0xE052 starts at zero and climbs by four; past 999,999 it sticks at
0xFF and hands out no more.

**Losing a life rewinds the stage.** You do not carry on where you were: 0x45C6
does an `and 0C0h` on the position, so you go back to the multiple of 64 rows
immediately below.

**The demo does not always start in the same place.** 0xE040 counts the demos and
multiplies by 256, but the counter **skips 2**, so the six demo runs begin at rows
0, 256, 768, 1024, 1280 and 1536.

## The big enemy is drawn by the background

It appears twice in the stage and comes in two halves. Its **body is not sprites**:
strip types 18 and 19 are the only ones in the map that use characters 0xB0 to
0xEC, and each appears **exactly once** (map indices 0x4A and 0xEA). On top of it
go the sprites at 0xE150, which are the parts you shoot at. 0x7766 starts it three
steps before it comes into view, to give its graphics time to load.
