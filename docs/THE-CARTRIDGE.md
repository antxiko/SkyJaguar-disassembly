# The cartridge

Sky Jaguar is Konami's **RC-721**, from 1984: 16 KB in page 1, with no bank
switching. The `AB` header at 0x4000 declares **only INIT** (0x4010); STATEMENT,
DEVICE and TEXT are all zero.

## It does not carry Konami's hidden mark

In many of its MSX cartridges Konami hid, at the end of the ROM, its catalogue
number and the title in katakana. The find is **Manuel Pazos**'s
([@ManuelPazosMSX](https://twitter.com/ManuelPazosMSX)), and the block lives at
offset 0x3FF0 — the end of the page.

**This one does not have it, and that was checked by scanning all 16,384
positions**, not just the tail. The dump shows why: the ROM runs **full of data
right up to 0x7FFB**, with only four bytes of 0xFF filler left over. There is no
room.

The scanner was validated first against four other cartridges of the same
family that do carry the mark, which is the only way to trust a negative result:
a finder that cannot find what is there proves nothing about what is not.

## How the 16 KB break down

| | bytes | |
|---|---|---|
| traced code | 7,086 | 43.25 % |
| identified data | 9,298 | 56.75 % |
| **unexplained** | **0** | **0.00 %** |

The data sits in **64 named and explained ranges**: the stage map, the compressed
scripts of the landscape, the character patterns and colours, the sprites, the
sound player's tables and the aiming tables.
