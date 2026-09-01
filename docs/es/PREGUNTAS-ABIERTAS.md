# Preguntas abiertas

Lo que aún no está cerrado, dicho tal cual. Nada de esto se ha rellenado a ojo.

## Qué representa la pareja de 0x55FC

`tabla_pareja_oleada_9`, ocho bytes: **cuatro parejas**. Lo que ya está medido es
**cuándo cambia** —el índice sale de los bits 6 y 7 del contador de 0x55C7, o sea
que la pareja se alterna cada 256 fotogramas— y **qué es cada byte**: el primero
va a la parte baja de la velocidad de caída del enemigo (0x80 o 0x00) y el segundo
es el patrón de su sprite (0x7C o 0x74). O sea, dos aspectos con dos velocidades.

Lo que sigue sin saberse es **por qué**: qué pinta esa alternancia en la oleada 9
y no en ninguna otra. Fuera de ella el juego usa siempre 0x7C / 0x80.

## Qué bicho es cada uno de los 21 tipos de objeto

La tabla de 0x535F despacha **veintiuna rutinas de objeto**, y cada una está
identificada por lo que hace con la ficha de 16 bytes. Lo que falta es bautizarlas
por lo que **son en pantalla**, y para eso hay que jugarlo y mirar. De momento van
como `OBJETO_TIPO_n` con una frase de lo que hace cada una.
