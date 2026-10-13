# The music

Everything you hear here comes from running the cartridge's own sound engine (`VUELCA_SONIDO`, 0x7A7A, and `PONE_SONIDO`, 0x79E5, which hands it the channels; the interrupt calls it at 0x4047) on an emulated Z80, frame by frame at 60 per second, just as the game calls it. What the engine writes to the PSG is turned into sound with an AY-3-8910 (`tools/musica.py`). Each MP3 is the whole piece up to where it starts again, plus 8 seconds of the repeat fading out; those that do not repeat end where the engine ends.

## Checked against openMSX

The PSG writes have been compared frame by frame with those of openMSX (C-BIOS MSX1 japonés). In every frame the PSG ends up the same:

- the start-up tune (0x93), whole, 293 frames, three times: forced, and twice as the game asks for it;
- the first 210 frames of game over (0x99, which lasts 284), until the game asks for another sound on top.

The timbre is not checked: it is a textbook AY-3-8910, not a recording of the emulator. The probes are `tools/omsx_psg.tcl` and `tools/coteja_psg.py`.

## How a piece is asked for

`PIDE_SONIDO` takes the number in A and only sounds with a game running (bit 6 of 0xE002) and the plane not dying; `PONE_SONIDO` skips those checks and shares the sound among the channels. Low numbers are effects and from 0x88 up there is music. Each channel takes twelve bytes from 0xE018 and 0xE03C holds the copy of the PSG mixer, which start-up leaves at 0xB8. The tracks marked «in the table» are in the track table but no routine asks for them with an `ld a`; 0x9A and 0x9B, minutes long and nearly without notes, are left out. Two pieces have been checked against openMSX, 0x93 and 0x99 (the latter in its first 210 frames); the rest come out of the same engine but each has not been compared.

## The tunes

**The start-up tune** (0x93)

Asked for by `ESTADO_3`; lasts 4.9 s.

<audio controls preload="none" src="audio/musica_93.mp3?v=67a6c528"></audio>

**Game over** (0x99)

Asked for by `FIN_DE_PARTIDA`; lasts 4.7 s.

<audio controls preload="none" src="audio/musica_99.mp3?v=25bbc404"></audio>

**The giant's tune** (0x88)

Asked for by `GIGANTE_EPISODIO_2`: mantiene sonando la música del gigante; lasts 3.2 s.

<audio controls preload="none" src="audio/musica_88.mp3?v=035f884e"></audio>

**The giant tune** (0x91)

Asked for by `MONTA_GIGANTE`; lasts 5.4 s.

<audio controls preload="none" src="audio/musica_91.mp3?v=cc936b00"></audio>

**The giant, once** (0x96)

Asked for by `GIGANTE_SUENA_UNA_VEZ`; lasts 4.5 s.

<audio controls preload="none" src="audio/musica_96.mp3?v=d7dfa7f4"></audio>

**Table track 0x92** (0x92)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 2.7 s.

<audio controls preload="none" src="audio/musica_92.mp3?v=3c6df860"></audio>

**Table track 0x94** (0x94)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 4.8 s.

<audio controls preload="none" src="audio/musica_94.mp3?v=dbab2b52"></audio>

**Table track 0x95** (0x95)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 4.8 s.

<audio controls preload="none" src="audio/musica_95.mp3?v=4474f2c3"></audio>

**Table track 0x97** (0x97)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 4.5 s.

<audio controls preload="none" src="audio/musica_97.mp3?v=4d3e3a65"></audio>

**Table track 0x98** (0x98)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 4.7 s.

<audio controls preload="none" src="audio/musica_98.mp3?v=dcf17789"></audio>
