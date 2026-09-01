# Getting started

A commented disassembly of **Sky Jaguar**, Konami's RC-721 for the MSX, a 16 KB
cartridge mapped into page 1 (0x4000–0x7FFF). It reassembles into the exact ROM,
byte for byte, and every one of its 16,384 bytes is accounted for.

## The cartridge is not here

No repository distributes the game. Put your own dump in the root as
`skyjaguar.rom`, 16384 bytes, sha256

    58abc5aec19dbca6f6aaf278b233a85219afde9622a9c3b34544b94a350d2a3b

`make comprueba` checks it.

## What each command does

    make            traces the flow, builds the listing, reassembles it and runs the tests
    make verify     the test that decides: reassembling must give the ROM back
    make sanity     that not one byte is left unexplained, and no data comes out as code
    make densidad   how much is commented, routine by routine
    make web        rebuilds this site from the ROM and the notes

## How it is put together

The listing is not hand-edited: `tools/mkasm.py` builds it from a flow trace and
a file of address-anchored notes, so the comments survive a re-trace. The tracer
follows the flow from the entry points; the ones it cannot deduce on its own —the
interrupt hook, the jump tables, and the routines reached through `push`/`ret`—
are declared in `src/skyjaguar.entries`, each with its reason.

The images on this site are not captures either: they are drawn by running in
Python the same decompressors the Z80 runs, over the cartridge's own bytes. If a
range or a format were wrong, noise would come out instead of the landscape.
