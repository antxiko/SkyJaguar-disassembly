# El cartucho

Sky Jaguar es un **RC-721** de Konami, de 1984: 16 KB en la página 1, sin cambio
de banco. La cabecera `AB` de 0x4000 declara **sólo INIT** (0x4010); STATEMENT,
DEVICE y TEXT van a cero.

## No lleva la marca oculta de Konami

Konami escondió en muchos de sus cartuchos de MSX, al final de la ROM, su número
de catálogo y el título en katakana. El hallazgo es de **Manuel Pazos**
([@ManuelPazosMSX](https://twitter.com/ManuelPazosMSX)), y el bloque vive en el
offset 0x3FF0, o sea el final de la página.

**Éste no la lleva, y se ha comprobado rastreando las 16.384 posiciones**, no
sólo el final. La razón se ve en el volcado: la ROM llega **llena de datos hasta
0x7FFB** y sólo sobran cuatro bytes de relleno 0xFF. No cabe.

El rastreador se validó antes contra cuatro cartuchos de la misma familia que
sí la llevan, que es la única manera de fiarse de un resultado negativo: un
buscador que no encuentra lo que está no demuestra nada sobre lo que no está.

## El reparto de los 16 KB

| | bytes | |
|---|---|---|
| código trazado | 7.086 | 43,25 % |
| datos identificados | 9.298 | 56,75 % |
| **sin explicar** | **0** | **0,00 %** |

Los datos van en **64 rangos** con nombre y explicación: el mapa de la fase, los
guiones comprimidos del paisaje, los patrones y colores de los caracteres, los
sprites, las tablas del reproductor de sonido y las de puntería.
