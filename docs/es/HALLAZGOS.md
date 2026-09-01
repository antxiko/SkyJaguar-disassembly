# Hallazgos

## La tabla de puntería tiene dos entradas cambiadas

0x6917 son nueve direcciones de disparo, parejas (dx, dy) de dieciséis bits que
recorren un cuarto de vuelta con radio 320. **Siete de las nueve cuadran al bit**
con `320 · sen` y `320 · cos`. Las entradas **3 y 5 están intercambiadas entre
sí**: la 3 guarda (266, 177) donde tocaría (178, 266), y la 5 guarda (177, 266)
donde tocaría (266, 178).

No es una aproximación tosca ni un redondeo: cada una contiene **exactamente** lo
que le corresponde a la otra. Dos de las nueve direcciones de disparo enemigo
apuntan al ángulo espejo del que deberían.

## Dos saltos que caen en mitad de una instrucción, a propósito

En **0x6684**, un `jr c` aterriza en el **último byte** del `ld bc,0x0300` de
0x6686 —una dirección que no es principio de ninguna instrucción, que es
justamente de lo que va esto—. Ese byte es `0x03`, y suelto se ejecuta como `inc bc`.
El resultado: con acarreo BC queda en 0xFE01, y sin acarreo se ejecuta el `ld` y
BC queda en 0x0300. Un byte ahorrado frente a un `jp`.

En **0x69A1** hacen lo mismo con el `0x03` del `ld (hl),3`.

## Código que no se ejecuta nunca

En **0x67F5** se hace `ld a,001h` y justo después `rra`. Rotar un 1 a la derecha
deja el acarreo **siempre puesto**, así que el `jr nc` de 0x67F8 no salta jamás y
el `ld a,0FFh` de 0x67FA se ejecuta siempre.

## Seis rutinas a las que no llama nadie

Buscando `call`, `jp`, `jr` y la dirección cruda, no aparece ni una referencia a
0x407B (intercambia B bytes), 0x4085 (calcula la dirección de una celda), 0x4099
(HL por 8), 0x4188 (pondría el estado 7), 0x4392, y 0x43CE, que es la gemela de
0x43C2 para **leer** de la VRAM: este cartucho no lee la VRAM ni una vez. Están
declaradas en el `.entries` y salen desensambladas, porque decodifican limpio.

## Hay una mejora de disparo, y sale de una cuenta fija

Los enemigos del tipo 5 no sueltan premio al azar. El byte que decide qué dejan
al morir se lleva una cuenta, y de cada treinta y dos: el **número 24** deja el
objeto 0x10, que vale mil puntos y **atraviesa al avión sin matarlo**, y los
**números 6 y 22** dejan el 0x11, que sube 0xE1D5 y **mejora el disparo** —salvo
que ya esté al tope—.

La mejora hace dos cosas que se pueden medir en el binario: pasas de **dos balas
a tres**, y la caja con la que tus balas aciertan pasa de **dos píxeles a doce**
(0x69E3). O sea que no es sólo disparar más: es acertar mucho más fácil.

## Tres cosas que el juego no te cuenta

**La primera vida extra cae a los 10.000 puntos, y luego cada 40.000.** El
contador 0xE052 arranca en cero y sube de cuatro en cuatro; pasado 999.999 se
clava en 0xFF y ya no da más vidas.

**Al perder una vida, la fase retrocede.** No sigues donde estabas: 0x45C6 hace
un `and 0C0h` sobre la posición, o sea que vuelves al múltiplo de 64 filas
inmediatamente anterior.

**La demostración no empieza siempre igual.** 0xE040 cuenta las demos y
multiplica por 256, pero el contador **se salta el 2**, así que las seis
demostraciones arrancan en las filas 0, 256, 768, 1024, 1280 y 1536.

## El enemigo grande lo dibuja el fondo

Sale dos veces en la fase y va en dos mitades. El **cuerpo no son sprites**: las
tiras de tipo 18 y 19 son las únicas del mapa que usan los caracteres 0xB0 a
0xEC, y cada una aparece **una sola vez** (índices de mapa 0x4A y 0xEA). Encima
van los sprites de 0xE150, que son las piezas a las que se dispara. 0x7766 lo
arranca tres pasos antes de que asome, para dar tiempo a cargar sus gráficos.
