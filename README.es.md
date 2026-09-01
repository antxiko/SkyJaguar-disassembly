# Sky Jaguar (Konami, RC-721) — desensamblado comentado

Un desensamblado comentado del cartucho de 16 KB para MSX, reproducible byte a
byte.

**[Leer el trabajo →](https://antxiko.github.io/SkyJaguar-disassembly/es/)**
· [In English](README.md)

    make            # traza, genera el listado, lo reensambla y pasa los tests
    make verify     # la prueba que decide: reensamblar tiene que devolver la ROM
    make sanity     # que ni un byte quede sin explicar
    make densidad   # cuánto está comentado, rutina a rutina
    make web        # rehace la web

La ROM **no se distribuye aquí**. Va en la raíz como `skyjaguar.rom`, 16384
bytes, sha256

    58abc5aec19dbca6f6aaf278b233a85219afde9622a9c3b34544b94a350d2a3b

`make comprueba` lo verifica.

## Cómo está

| | |
|---|---|
| reensambla byte a byte | sí |
| bytes explicados | 16.384 de 16.384 (100 %) |
| código trazado | 7.086 bytes |
| datos identificados | 9.298 bytes en 64 rangos con nombre |
| comentado | 1304 comentarios de línea, 32,1 % |

Las anotaciones viven aparte del listado, ancladas a la dirección que describen,
así que sobreviven a un retrazado. Lo que guarda el `.notes`:

| | |
|---|---|
| etiquetas con nombre | 464 |
| comentarios anclados | 1304 |
| rangos de datos con explicación | 64 |

## Qué hay aquí

- `src/skyjaguar.asm` — el listado; generado, no escrito a mano
- `src/skyjaguar.notes` — las anotaciones, ancladas a direcciones
- `src/skyjaguar.entries` — los puntos de entrada, cada uno justificado
- `docs/` — la web, en castellano y en inglés
- `tools/` — el trazador, el generador del listado, los recorredores de datos y
  los descompresores que dibujan las imágenes de la web desde la ROM

## El trabajo

| | |
|---|---|
| [Empezar](docs/es/EMPEZAR.md) | qué hace falta y qué hace cada orden |
| [El juego](docs/es/EL-JUEGO.md) | una sola fase que se repite, y lo que te viene encima |
| [El cartucho](docs/es/EL-CARTUCHO.md) | la cabecera, y por qué no lleva marca oculta |
| [El código](docs/es/EL-CODIGO.md) | la máquina de estados, el paisaje comprimido y el sonido |
| [Hallazgos](docs/es/HALLAZGOS.md) | lo que dice el binario |
| [En el emulador](docs/es/EN-EL-EMULADOR.md) | qué se puede medir, y cómo |
| [Preguntas abiertas](docs/es/PREGUNTAS-ABIERTAS.md) | lo que aún no está cerrado |

Ver `AVISO-LEGAL.md`.
