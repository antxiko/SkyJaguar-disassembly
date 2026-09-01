# The game

Sky Jaguar is a vertically scrolling shooter: you fly a fighter up a landscape
that comes down, shooting what crosses it. The cartridge is from 1984 and fits in
16 KB.

## One stage, repeated

This is the first thing the binary says, and you cannot see it by playing:
**there are no levels**. There is **one 1920-row stage**, and when it ends it
starts again. What goes up is the difficulty, at 0xE1D3, **capped at 2**: from the
third lap on, the game stops getting harder.

The landscape is not stored as a map of cells but as a script: 244 bytes choose,
every eight rows, which of twenty strips to draw, and each strip is a compressed
script. [The code](THE-CODE.md) has the whole format, including the trick of the
eight pre-shifted copies that produces the fine scroll.

## What comes at you

The engine carries **seven object slots** at a time, sixteen bytes each, from
0xE200. Each slot holds its type, and a table of **twenty-one routines** (0x535F)
says how it behaves. Twenty-one behaviours through seven slots: that is what makes
it feel like there is always something new.

Enemies aim with a table of nine firing directions (0x6917), a quarter turn. Two
of those nine are wrong: see [Findings](FINDINGS.md).

## The big enemy

It shows up **twice** in the stage, and comes in two halves. The striking part is
how it is built: **its body is not sprites — the background draws it**. Two of the
twenty landscape strips (types 18 and 19) are the only ones that use characters
0xB0 to 0xEC, and each appears exactly once in the whole map. On top go four
sprites, which are the parts you shoot at.

The game starts assembling it **three steps before** it comes into view, so its
graphics have time to decompress without a visible hitch.
