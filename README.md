# Sky Jaguar (Konami, RC-721) — commented disassembly

A commented disassembly of the 16 KB MSX cartridge, reproducible byte for byte.

**[Read the write-up →](https://antxiko.github.io/SkyJaguar-disassembly/)**
· [En castellano](README.es.md)

    make            # trace, generate the listing, reassemble it and run the tests
    make verify     # the test that decides: reassembling has to give the ROM back
    make sanity     # that not one byte is left unexplained
    make densidad   # how much is commented, routine by routine
    make web        # rebuild the website

The ROM is **not distributed here**. It goes in the root as `skyjaguar.rom`,
16384 bytes, sha256

    58abc5aec19dbca6f6aaf278b233a85219afde9622a9c3b34544b94a350d2a3b

`make comprueba` checks it.

## Where it stands

| | |
|---|---|
| reassembles byte for byte | yes |
| bytes explained | 16,384 of 16,384 (100 %) |
| traced code | 7,086 bytes |
| identified data | 9,298 bytes in 64 named ranges |
| commented | 1304 line comments, 32.1 % |

The annotations live apart from the listing, anchored to the address they
describe, so they survive a re-trace. What the `.notes` file holds:

| | |
|---|---|
| named labels | 464 |
| anchored comments | 1304 |
| explained data ranges | 64 |

## What is in here

- `src/skyjaguar.asm` — the listing; generated, not hand-edited
- `src/skyjaguar.notes` — the annotations, anchored to addresses
- `src/skyjaguar.entries` — the entry points, each one justified
- `docs/` — the website, in English and Spanish
- `tools/` — the tracer, the listing generator, the data walkers and the
  script decompressors that draw the website's pictures from the ROM

## The write-up

| | |
|---|---|
| [Getting started](docs/GETTING-STARTED.md) | what you need and what each command does |
| [The game](docs/THE-GAME.md) | one stage that repeats, and what flies at you |
| [The cartridge](docs/THE-CARTRIDGE.md) | the header, and why it has no hidden mark |
| [The code](docs/THE-CODE.md) | the state machine, the compressed landscape and the sound |
| [Findings](docs/FINDINGS.md) | what the binary says |
| [In the emulator](docs/IN-THE-EMULATOR.md) | what can be measured, and how |
| [Open questions](docs/OPEN-QUESTIONS.md) | what is still not settled |

See `LEGAL-NOTICE.md`.
