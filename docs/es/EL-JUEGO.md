# El juego

Sky Jaguar es un matamarcianos de desplazamiento vertical: pilotas un caza que
sube por un paisaje que baja, disparando a lo que se cruza. El cartucho es de
1984 y cabe en 16 KB.

## Una sola fase, que se repite

Esto es lo primero que dice el binario, y no se ve jugando: **no hay niveles**.
Hay **una fase de 1920 filas** y, al acabarla, vuelve a empezar. Lo que sube es
la dificultad, en 0xE1D3, **con tope 2**: a partir de la tercera vuelta el juego
ya no se endurece más.

El paisaje no está guardado como un mapa de celdas, sino como un guión: 244
bytes eligen, cada ocho filas, cuál de veinte tiras se dibuja, y cada tira es un
guión comprimido. En [El código](EL-CODIGO.md) está el formato entero, incluido
el truco de las ocho copias desplazadas con el que se hace el desplazamiento fino.

## Lo que te viene encima

El motor lleva **siete huecos de objeto** a la vez, de dieciséis bytes cada uno,
desde 0xE200. Cada hueco guarda su tipo, y una tabla de **veintiuna rutinas**
(0x535F) dice cómo se comporta. Veintiún comportamientos distintos con siete
sitios: eso es lo que da la sensación de que siempre hay algo nuevo.

Los enemigos apuntan con una tabla de nueve direcciones de disparo (0x6917), un
cuarto de vuelta. Dos de esas nueve están mal: ver [Hallazgos](HALLAZGOS.md).

## El enemigo grande

Sale **dos veces** en la fase, y va en dos mitades. Lo llamativo es cómo está
hecho: **el cuerpo no son sprites, lo dibuja el propio fondo**. Dos de las veinte
tiras del paisaje —los tipos 18 y 19— son las únicas que usan los caracteres 0xB0
a 0xEC, y cada una aparece una sola vez en todo el mapa. Encima van cuatro
sprites, que son las piezas a las que se dispara.

El juego empieza a montarlo **tres pasos antes** de que asome, para que dé tiempo
a descomprimir sus gráficos sin que se note el tirón.
