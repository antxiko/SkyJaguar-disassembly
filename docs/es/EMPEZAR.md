# Empezar

Un desensamblado comentado de **Sky Jaguar**, el RC-721 de Konami para MSX, un
cartucho de 16 KB que se mapea en la página 1 (0x4000–0x7FFF). Reensambla dando
la ROM exacta, byte a byte, y cada uno de sus 16.384 bytes está explicado.

## El cartucho no está aquí

Ningún repositorio distribuye el juego. Pon tu propio volcado en la raíz como
`skyjaguar.rom`, 16384 bytes, sha256

    58abc5aec19dbca6f6aaf278b233a85219afde9622a9c3b34544b94a350d2a3b

`make comprueba` lo verifica.

## Qué hace cada orden

    make            traza el flujo, arma el listado, lo reensambla y pasa los tests
    make verify     la prueba que decide: reensamblar tiene que devolver la ROM
    make sanity     que ni un byte quede sin explicar, y que ningún dato salga como código
    make densidad   cuánto está comentado, rutina a rutina
    make web        rehace esta web desde la ROM y las notas

## Cómo está montado

El listado no se edita a mano: `tools/mkasm.py` lo arma desde un trazado de flujo
y un fichero de notas ancladas a direcciones, así que los comentarios sobreviven
a un retrazado. El trazador sigue el flujo desde los puntos de entrada; los que
no puede deducir solo —el gancho de la interrupción, las tablas de saltos y las
rutinas a las que se llega por `push`/`ret`— van declarados en
`src/skyjaguar.entries`, cada uno con su motivo.

Las imágenes de esta web tampoco son capturas: se dibujan ejecutando en Python
los mismos descompresores que corre el Z80, leyendo los bytes del cartucho. Si un
rango o un formato estuvieran mal, saldría ruido en vez del paisaje.
