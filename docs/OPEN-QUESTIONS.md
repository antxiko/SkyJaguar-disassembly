# Open questions

What is not settled yet, said plainly. None of this has been filled in by guessing.

## What the pair at 0x55FC represents

`tabla_pareja_oleada_9`, eight bytes: **four pairs**. What is now measured is
**when it changes** — the index comes off bits 6 and 7 of the counter at 0x55C7,
so the pair alternates every 256 frames — and **what each byte is**: the first
goes into the low half of the enemy's falling speed (0x80 or 0x00) and the second
is its sprite pattern (0x7C or 0x74). Two looks with two speeds.

What is still unknown is **why**: what that alternation is for in wave 9 and in no
other. Outside it the game always uses 0x7C / 0x80.

## Which creature each of the 21 object types is

The table at 0x535F dispatches **twenty-one object routines**, and each one is
identified by what it does with its 16-byte slot. What is missing is naming them
for what they **are on screen**, and that needs playing the game and looking. For
now they are `OBJETO_TIPO_n` with a sentence on what each one does.
