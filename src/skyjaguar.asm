; ==========================================================================
; SKY JAGUAR - Konami - MSX1 - cartucho RC-721 de 16 KB en la pagina 1
; ==========================================================================
; Generado por tools/mkasm.py a partir del trazado de flujo real.
; Los comentarios provienen de tools/../src/*.notes y estan anclados a
; direccion, de modo que sobreviven a un retrazado.
; ==========================================================================

	org 0x04000


; ----------------------------------------------------------------------
; Etiquetas que no caen en ninguna posicion emitida del listado
; (destinos fuera del binario o dentro de una instruccion).
; ----------------------------------------------------------------------
SALTO_AL_INC_BC:	equ 0x06688
SALTO_AL_LD_FF:	equ 0x067fb
SALTO_AL_INC_BC_2:	equ 0x069a7

; ----------------------------------------------------------------------
; DATOS cabecera_cartucho: AB y el puntero INIT (0x4010); STATEMENT, DEVICE y
;   TEXT a cero
;   0x4000..0x4010  (16 bytes)
DATA_cabecera_cartucho:
	defb 041h,042h	; 4000
	defw 04010h,00000h,00000h,00000h	; 4002  -> INIT 0x0000 0x0000 0x0000
	defw 00000h,00000h,00000h	; 400a

; ======================================================================
; CODIGO 0x4010..0x40c9  (185 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ARRANQUE. La BIOS entra aqui por la cabecera del cartucho.
; ----------------------------------------------------------------------
INIT:		; Prepara la maquina y engancha la interrupcion
	di			;4010
	im 1		;4011   ; modo de interrupcion 1
	ld a,0c3h		;4013   ; escribe un jp en el gancho H.KEYI (0xFD9A/0xFD9B)...
	ld (0fd9ah),a		;4015
	ld hl,INTERRUPCION		;4018   ; ...que apunta a la rutina de interrupcion, 0x4043
	ld (0fd9bh),hl		;401b
	ld sp,0e400h		;401e   ; la pila arranca en 0xE400
	ld hl,0e000h		;4021   ; borra de un ldir la RAM de trabajo, 0xE000-0xE3FF
	ld de,0e001h		;4024
	ld bc,003ffh		;4027
	ld (hl),000h		;402a
	ldir		;402c
	ld a,001h		;402e
	ld (0e006h),a		;4030
	call 00132h		;4033   ; BIOS CHGCAP - Alternates the CAPS lamp status | apaga el piloto de CAPS (entra con A distinto de cero)
	call ARRANCA_VDP		;4036   ; arranca el VDP y borra los 16 KB de VRAM
	xor a			;4039
	ld (0e006h),a		;403a
	call 0013eh		;403d   ; BIOS RDVDP - Reads VDP status register | acusa recibo de la interrupcion leyendo el registro de estado del VDP
	ei			;4040
BUCLE_MUERTO:		; Desde aqui el juego entero corre en la interrupcion
	jr BUCLE_MUERTO		;4041

; ----------------------------------------------------------------------
; LA INTERRUPCION. Un paso del juego por fotograma.
; ----------------------------------------------------------------------
INTERRUPCION:		; Gancho H.KEYI: un paso del juego por barrido
	call 0013eh		;4043   ; BIOS RDVDP - Reads VDP status register
	di			;4046
	call VUELCA_SONIDO		;4047   ; vuelca los tres canales de sonido al PSG
	ld hl,0e006h		;404a
	bit 0,(hl)		;404d   ; 0xE006 es el candado: si ya estamos dentro, no se reentra
	jr nz,INT_SALIDA		;404f
	inc (hl)			;4051
	ei			;4052
	call LEE_MANDOS		;4053   ; lee mandos y teclado
	call PASO_DE_ESTADO		;4056   ; y despacha el estado
	xor a			;4059
	ld (0e006h),a		;405a
INT_SALIDA:		; Fin de la interrupcion: acusa recibo y devuelve el control
	call 0013eh		;405d   ; BIOS RDVDP - Reads VDP status register
	or a			;4060
	di			;4061
	call m,VUELCA_SONIDO		;4062   ; si el paso dejo el bit 7 puesto, repite el volcado de sonido
	ei			;4065
	ret			;4066
SUMA_A_HL:		; HL = HL + A, con acarreo a H
	add a,l			;4067   ; el acarreo solo puede subir uno, asi que basta con inc h
	ld l,a			;4068
	ret nc			;4069
	inc h			;406a
	ret			;406b
SUMA_A_DE:		; DE = DE + A, con acarreo a D
	add a,e			;406c   ; la gemela de 0x4067 para DE, que es el registro de los guiones
	ld e,a			;406d
	ret nc			;406e
	inc d			;406f
	ret			;4070

; ----------------------------------------------------------------------
; EL DESPACHADOR. El pop hl coge la direccion de retorno, o sea la tabla que va PEGADA al CALL; A la indexa y se salta por ella.
; ----------------------------------------------------------------------
DESPACHA:		; Salta por la tabla que sigue al CALL, indexada por A
	pop hl			;4071   ; el pop coge la direccion de retorno: la tabla va PEGADA detras del call
	add a,a			;4072   ; dos bytes por entrada, asi que el indice se dobla
	call SUMA_A_HL		;4073
	ld e,(hl)			;4076   ; saca el puntero de la tabla...
	inc hl			;4077
	ld d,(hl)			;4078
	ex de,hl			;4079
	jp (hl)			;407a   ; ...y salta a el sin gastar pila
MUERTA_INTERCAMBIA:		; Intercambia B bytes entre (HL) y (DE). Nadie la llama
	ld c,(hl)			;407b   ; intercambia B bytes entre (HL) y (DE) usando C de apoyo. Nadie la llama
	ld a,(de)			;407c
	ld (hl),a			;407d
	ld a,c			;407e
	ld (de),a			;407f
	inc hl			;4080
	inc de			;4081
	djnz MUERTA_INTERCAMBIA		;4082
	ret			;4084
MUERTA_CELDA:		; De HL saca la direccion de la tabla de nombres. Nadie la llama
	ld a,l			;4085   ; de un punto en pixels saca su celda: entra la columna en H y la fila en L
	rra			;4086   ; los seis rra dejan en A los bits altos de la fila...
	rra			;4087
	rra			;4088
	rra			;4089
	rr h		;408a   ; ...y los tres rr h van metiendo la fila por arriba de H
	rra			;408c
	rr h		;408d
	rra			;408f
	rr h		;4090
	ld l,h			;4092   ; H queda con fila*32 + columna/8 dentro del tercio, y pasa a L
	and 003h		;4093   ; los dos bits que quedan en A son el tercio (0..2)
	add a,038h		;4095   ; 0x3800 es la tabla de nombres: HL sale ya apuntando a la celda
	ld h,a			;4097
	ret			;4098
MUERTA_POR_OCHO:		; HL = HL*8 recolocado en H:L. Nadie la llama
	add hl,hl			;4099   ; la vuelta de 0x4085: de la celda saca el punto en pixels. Nadie la llama
	add hl,hl			;409a
	add hl,hl			;409b
	ld a,h			;409c   ; HL*8 deja la fila en H y la columna en pixels en L...
	rla			;409d
	rla			;409e
	rla			;409f
	and 0f8h		;40a0
	ld h,l			;40a2   ; ...asi que se cruzan: H se queda la columna y L la fila por ocho
	ld l,a			;40a3
	ret			;40a4

; ----------------------------------------------------------------------
; LA MAQUINA DE ESTADOS. 0xE000 es el estado y 0xE001 el subestado.
; ----------------------------------------------------------------------
PASO_DE_ESTADO:		; Un paso de la maquina de estados
	ld hl,0e003h		;40a5   ; 0xE003 cuenta fotogramas sin parar
	inc (hl)			;40a8   ; 0xE003 cuenta fotogramas; en 0xE005 queda su parte baja
	ld a,(hl)			;40a9
	and 007h		;40aa   ; los tres bits bajos, que es el ritmo que usan las animaciones
	inc hl			;40ac
	inc hl			;40ad
	ld (hl),a			;40ae
	ld a,(0e002h)		;40af   ; bit 6 de 0xE002: hay partida en marcha
	and 040h		;40b2
	ld hl,0413ah		;40b4   ; sin partida en marcha el retorno comun es 0x44C4, el que lee el mando de la pantalla de titulo; con partida, 0x413A, que es un ret pelado
	jr nz,DESPACHA_ESTADO		;40b7
	ld hl,044c4h		;40b9
DESPACHA_ESTADO:		; Lee 0xE000/0xE001 y salta al manejador que toque
	ld bc,(0e000h)		;40bc   ; C es el estado y B el subestado
	ld a,c			;40c0
	cp 003h		;40c1   ; el estado 3 es el unico que no lleva retorno comun: acaba en un jp
	jr z,LLAMA_A_LA_TABLA		;40c3
	push hl			;40c5   ; empuja el retorno comun
LLAMA_A_LA_TABLA:		; El CALL que lleva la tabla de estados pegada detras
	call DESPACHA		;40c6   ; el call deja la tabla de 0x40C9 al alcance del pop de DESPACHA

; ----------------------------------------------------------------------
; DATOS tabla_estados: Los ocho manejadores de estado, indexados por 0xE000
;   0x40c9..0x40d9  (16 bytes)
DATA_tabla_estados:
	defw 040d9h,04116h,0411dh,0413bh,0414fh,0417bh,0418fh,041bbh	; 40c9

; ======================================================================
; CODIGO 0x40d9..0x4200  (295 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ESTADO 0. Cortinilla de entrada de la pantalla de titulo.
; ----------------------------------------------------------------------
ESTADO_0:		; Cortinilla de entrada del titulo, un anillo cada dos fotogramas
	djnz ESTADO_0_SUB_1		;40d9   ; B trae el subestado y el djnz lo baja: el subestado 0 cae al ULTIMO bloque de la cadena, el 1 al primero
	ld a,(0e003h)		;40db   ; un anillo cada dos fotogramas: el bit 0 del contador
	rra			;40de
	ret nc			;40df
	call PASO_CORTINILLA		;40e0   ; dibuja un anillo mas; con cero acaba la cortinilla
	ret nz			;40e3
	ld de,04b49h		;40e4   ; ya cerrada, escribe VIDEO CARTRIDGE
	call PINTA_GUION		;40e7
	xor a			;40ea   ; cuenta atras a cero, o sea 256 fotogramas de letrero
	jr FIJA_ESPERA		;40eb
ESTADO_0_SUB_1:		; Espera 256 fotogramas y se lleva el letrero VIDEO CARTRIDGE
	djnz ESTADO_0_SUB_2		;40ed   ; subestado 2: el letrero ya esta puesto
	ld hl,0e004h		;40ef   ; cuando se acaba la espera se lleva el letrero
	dec (hl)			;40f2
	ret nz			;40f3
	ld de,04b49h		;40f4   ; el mismo guion, ahora escribiendo ceros: eso lo borra
	call BORRA_GUION		;40f7
	call CARGA_TITULO		;40fa   ; y entran los graficos del titulo
	jr SUBE_SUBESTADO		;40fd
ESTADO_0_SUB_2:		; Carga el rotulo del titulo
	djnz ESTADO_0_SUB_3		;40ff   ; subestado 3
	call PINTA_ROTULO		;4101   ; pinta el rotulo SKY JAGUAR y el PUSH SPACE KEY
	xor a			;4104   ; sin espera: al estado 1
	jp ESPERA_Y_SUBE_ESTADO		;4105
ESTADO_0_SUB_3:		; Rearma el VDP, el sonido y la cortinilla
	call BORRA_NOMBRES		;4108   ; subestado 0, el primero que corre: deja la pantalla lista
	call CARGA_REGISTROS		;410b   ; los ocho registros del VDP
	call COLOR_LISOS		;410e   ; y el color entero de los caracteres lisos 0x00-0x0F
	call ARRANCA_CORTINILLA		;4111   ; arma la cortinilla de anillos
	jr SUBE_SUBESTADO		;4114

; ----------------------------------------------------------------------
; ESTADO 1. Espera.
; ----------------------------------------------------------------------
ESTADO_1:		; Cuenta atras a secas
	ld hl,0e004h		;4116   ; el estado 1 solo hace tiempo
	dec (hl)			;4119
	ret nz			;411a
	jr ESPERA_24		;411b   ; agotada la cuenta, al estado 2

; ----------------------------------------------------------------------
; ESTADO 2. LA DEMOSTRACION: la misma fase, jugada por el guion de mandos falsos de 0x4B5F.
; ----------------------------------------------------------------------
ESTADO_2:		; Un paso de la fase de la demostracion
	djnz ESTADO_2_SUB_1		;411d   ; subestado 1 en adelante: la demostracion ya rueda
	call PASO_DE_FASE		;411f   ; un paso de la fase
	ld a,(0e053h)		;4122   ; 0xE053 a cero es que la fase se ha terminado
	or a			;4125
	ret nz			;4126
A_FIN_DE_PARTIDA:		; Deja el estado en 0: se acabo la demostracion o la partida
	xor a			;4127   ; estado 0: la cortinilla de la pantalla de titulo otra vez
	jp FIJA_ESTADO		;4128
ESTADO_2_SUB_1:		; Monta la escena de la demostracion y espera 24 fotogramas
	call BORRA_NOMBRES		;412b   ; subestado 0: monta la escena de la demostracion
	call ARRANCA_ESCENA		;412e
	ld a,018h		;4131   ; 24 fotogramas para que se vea la pantalla montada
FIJA_ESPERA:		; Deja A en la cuenta atras 0xE004
	ld (0e004h),a		;4133
SUBE_SUBESTADO:		; Suma uno a 0xE001
	ld hl,0e001h		;4136   ; el subestado siempre sube de uno en uno
	inc (hl)			;4139
	ret			;413a

; ----------------------------------------------------------------------
; ESTADO 3. Arranca la partida de verdad.
; ----------------------------------------------------------------------
ESTADO_3:		; Pide la musica de arranque, prepara la partida y pasa al 4
	ld a,093h		;413b   ; 0x93 es la musica de arranque; mientras suena, FOTOGRAMA no deja correr la fase
	call PONE_SONIDO		;413d
	call PREPARA_PARTIDA		;4140   ; vidas, escena, puntos y demas a los valores de arranque
	jp ESPERA_24		;4143
VUELVE_AL_TITULO:		; Borra la pantalla, carga el titulo y sube el subestado
	call BORRA_NOMBRES		;4146   ; el camino de vuelta al titulo cuando se acaba la partida
	call CARGA_TITULO_ENTERO		;4149
	jp SUBE_SUBESTADO		;414c

; ----------------------------------------------------------------------
; ESTADO 4. Prepara una vida: quita una y coloca el avion.
; ----------------------------------------------------------------------
ESTADO_4:		; Espera, coloca el avion y marca la fase en marcha
	djnz ESTADO_4_SUB_1		;414f   ; subestado 1: el panel ya esta repintado
	ld hl,0e004h		;4151
	dec (hl)			;4154
	ret nz			;4155
	call ARRANCA_VIDA		;4156   ; coloca el avion en su sitio de salida
	ld hl,0e053h		;4159   ; 0xE053 a uno: la fase esta en marcha
	ld (hl),001h		;415c
ESPERA_24:		; Espera 24 y pasa al estado siguiente
	ld a,018h		;415e   ; 24 fotogramas es la espera de todos los cambios de estado
ESPERA_Y_SUBE_ESTADO:		; Deja A en 0xE004 y sube el estado
	ld (0e004h),a		;4160
SUBE_ESTADO:		; Suma uno a 0xE000 y pone el subestado a cero
	ld hl,0e000h		;4163   ; 0xE000 es el estado...
	inc (hl)			;4166
SUBESTADO_CERO:		; Devuelve el subestado a cero
	xor a			;4167   ; ...y el subestado vuelve a cero al cambiar de estado
	ld (0e001h),a		;4168
	ret			;416b
ESTADO_4_SUB_1:		; Quita una vida, repinta el panel y espera
	call BORRA_NOMBRES		;416c   ; subestado 0: se acaba de perder una vida
	ld hl,0e050h		;416f   ; una vida menos
	dec (hl)			;4172
	call PINTA_PANEL		;4173
	ld a,001h		;4176   ; un solo fotograma de espera
	jp FIJA_ESPERA		;4178

; ----------------------------------------------------------------------
; ESTADO 5. LA PARTIDA. Es el estado 2 sin subestados, con los mandos de verdad.
; ----------------------------------------------------------------------
ESTADO_5:		; Un paso de la fase de la partida hasta que la fase acaba
	call PASO_DE_FASE		;417b   ; los estados 2 y 5 pisan la misma fase; lo que cambia es de donde salen los mandos
	ld a,(0e053h)		;417e
	or a			;4181
	ret nz			;4182
	ld (0e1ddh),a		;4183   ; 0xE1DD a cero al acabar
	jr ESPERA_24		;4186
MUERTA_ESTADO7:		; Pondria el estado 7. Ningun salto entra aqui
	ld a,007h		;4188   ; pondria el estado 7, pero ni la tabla ni ningun salto entran aqui
	ld (0e000h),a		;418a
	jr SUBE_ESTADO		;418d

; ----------------------------------------------------------------------
; ESTADO 6. GAME OVER: si quedan vidas vuelve al 4, si no al titulo.
; ----------------------------------------------------------------------
ESTADO_6:		; Con vidas vuelve al 4; sin vidas, GAME OVER
	ld a,(0e050h)		;418f   ; sin vidas se acabo la partida
	or a			;4192
	jr z,FIN_DE_PARTIDA		;4193
	ld a,004h		;4195   ; con vidas, al estado 4, que es el que arranca una vida nueva
FIJA_ESTADO:		; Pone A como estado, espera 24 y vuelve al subestado cero
	ld (0e000h),a		;4197
	ld a,018h		;419a   ; otros 24 fotogramas
	ld (0e004h),a		;419c
	jr SUBESTADO_CERO		;419f
FIN_DE_PARTIDA:		; Apaga los sprites, escribe GAME  OVER y va al estado 6
	call APAGA_SPRITES_9		;41a1   ; deja solo las ocho primeras fichas de sprite
	call VUELCA_SONIDO		;41a4   ; vuelca el silencio al PSG en el acto
	ld de,04b3ch		;41a7   ; el guion del GAME OVER
	call PINTA_GUION		;41aa
	ld a,006h		;41ad   ; el 6 ya estaba puesto: aqui solo se llega desde el propio estado 6
	ld (0e000h),a		;41af
	ld a,099h		;41b2   ; 0x99 es la musica de fin de partida
	call PONE_SONIDO		;41b4
	xor a			;41b7
	jp ESPERA_Y_SUBE_ESTADO		;41b8

; ----------------------------------------------------------------------
; ESTADO 7. Espera al disparo para volver a empezar.
; ----------------------------------------------------------------------
ESTADO_7:		; Con el disparo vuelve al titulo y arranca otra partida
	ld de,0e002h		;41bb   ; DE apunta a los bits de partida para lo que venga
	ld a,(0e009h)		;41be   ; bit 4 de los mandos recien pulsados: el disparo
	and 010h		;41c1
	jr z,ESTADO_7_ESPERA		;41c3
	ld a,(de)			;41c5   ; baja el bit 6: ya no hay partida en marcha
	and 0bfh		;41c6
	ld (de),a			;41c8
	call VUELVE_AL_TITULO		;41c9   ; vuelve a la pantalla de titulo
	pop de			;41cc   ; tira el retorno comun que empujo el despachador
	ld hl,00001h		;41cd   ; estado 0 y subestado 1: la cortinilla ya no se rehace
	ld (0e000h),hl		;41d0
	ld a,09dh		;41d3   ; 0x9D es el silencio: su guion es un 0xFF pelado en los tres canales
	jp PONE_SONIDO		;41d5
ESTADO_7_ESPERA:		; Sin disparo, espera a que acabe el sonido
	ld a,(0e01ah)		;41d8   ; el canal A sigue en 0x99 mientras suena el GAME OVER
	cp 099h		;41db
	ret z			;41dd
	ld a,(de)			;41de   ; acabada la musica, cierra la partida el solo
	and 0bfh		;41df
	ld (de),a			;41e1
	jp A_FIN_DE_PARTIDA		;41e2
PREPARA_PARTIDA:		; Borra 0xE049-0xE33F y carga los valores iniciales
	ld hl,0e049h		;41e5   ; borra de 0xE049 a 0xE33F: puntos, avion, objetos y fase
	ld bc,002f7h		;41e8
	ld d,h			;41eb
	ld e,l			;41ec
	inc e			;41ed
	ld (hl),000h		;41ee
	ldir		;41f0
	ld hl,04200h		;41f2   ; y encima copia los cuatro valores de arranque
	ld de,0e050h		;41f5
	ld bc,00004h		;41f8
	ldir		;41fb
	jp CARGA_PAISAJE		;41fd   ; los caracteres del paisaje, que el titulo habia pisado

; ----------------------------------------------------------------------
; DATOS valores_iniciales_partida: Los cuatro bytes que van a 0xE050: tres
;   vidas, escena 1, el liston de la vida extra a cero (la primera cae a los
;   10000 puntos) y 0xE053 a 2
;   0x4200..0x4204  (4 bytes)
DATA_valores_iniciales_partida:
	defb 003h,001h,000h,002h	; 4200

; ======================================================================
; CODIGO 0x4204..0x443d  (569 bytes)
; ======================================================================


ARRANCA_ESCENA:		; Monta la pantalla de la demostracion y elige por donde empieza
	call PINTA_PANEL		;4204   ; el panel del lado derecho
	call CARGA_PAISAJE		;4207   ; los patrones y colores del paisaje
	xor a			;420a
	ld (0e140h),a		;420b   ; ningun episodio del enemigo grande empezado
	ld (0e00ch),a		;420e   ; el guion del demo, otra vez desde el principio
	inc a			;4211
	ld (0e053h),a		;4212   ; 0xE053 a uno: fase en marcha
	ld hl,0e040h		;4215   ; 0xE040 cuenta las demostraciones: dice por que fila de la fase arranca la siguiente
	ld a,(hl)			;4218
	inc (hl)			;4219
	cp 001h		;421a
	jr nz,ESCENA_A_CERO		;421c
	inc (hl)			;421e
ESCENA_A_CERO:		; El contador de demostraciones da la vuelta despues del 6
	cp 006h		;421f   ; el contador da la vuelta despues del 6, y ademas se salta el 2: las demostraciones arrancan en las filas 0, 256, 768, 1024, 1280 y 1536
	jr nz,GUARDA_TITULO		;4221
	ld (hl),000h		;4223
GUARDA_TITULO:		; Deja en 0xE1B8 la fila por la que arranca la demostracion
	ld h,a			;4225   ; la cuenta por 256 es la fila de la fase por la que entra la demostracion
	ld l,000h		;4226
	ld (0e1b8h),hl		;4228
	jp ARRANCA_VIDA		;422b   ; y a colocar el avion
APAGA_SPRITES:		; Manda las 32 fichas de sprite fuera de la pantalla
	ld hl,03b00h		;422e   ; las 32 fichas de sprite son 128 bytes de atributos
	ld bc,00080h		;4231
RELLENA_FICHAS:		; Rellena BC fichas de sprite con 0xE3 y ajusta el sonido
	ld a,0e3h		;4234   ; rellena las cuatro casillas de cada ficha con 0xE3; en la fila, ese valor la deja fuera de la pantalla
	call 00056h		;4236   ; BIOS FILVRM - Fills VRAM with value
	ld a,(0e01ah)		;4239   ; si sonaba la marcha de partida (0x93) la deja...
	cp 093h		;423c
	ld a,09dh		;423e   ; ...y si no, lo silencia todo con la 0x9D
	jp nz,PONE_SONIDO		;4240
	ret			;4243
APAGA_SPRITES_9:		; Igual, pero solo de la novena ficha en adelante
	ld hl,03b24h		;4244   ; de la ficha 9 en adelante: las nueve primeras (avion, balas y gigante) se quedan
	ld bc,0005ch		;4247
	jr RELLENA_FICHAS		;424a
SUMA_PUNTOS:		; Suma DE (en BCD) a los puntos y reparte las vidas extra
	ld a,(0e002h)		;424c   ; sin partida en marcha (bit 7 de 0xE002 tras el add) no puntua
	add a,a			;424f
	ret p			;4250
	ld hl,0e049h		;4251   ; los puntos son tres bytes BCD, del bajo al alto
	ld a,(hl)			;4254
	add a,e			;4255
	daa			;4256   ; el daa detras de cada suma es lo que los mantiene en BCD
	ld (hl),a			;4257
	ld e,a			;4258
	inc l			;4259
	ld a,(hl)			;425a
	adc a,d			;425b
	daa			;425c
	ld (hl),a			;425d
	ld d,a			;425e
	inc hl			;425f
	jr nc,MIRA_RECORD		;4260
	ld a,(hl)			;4262   ; y el tercer byte lleva el acarreo
	add a,001h		;4263
	daa			;4265
	ld (hl),a			;4266
	jr nc,MIRA_VIDA_EXTRA		;4267
	ld bc,09999h		;4269   ; pasado el 999999 el record se clava ahi: 0xE043 a 0xE045 a 99 99 99
	ld (0e043h),bc		;426c
	ld (0e044h),bc		;4270
	jr PINTA_EL_RECORD		;4274
MIRA_VIDA_EXTRA:		; Compara los puntos con el liston de 0xE052
	ld a,(0e052h)		;4276   ; el liston de 0xE052 se compara con el byte alto de los puntos: la primera vida extra cae a los 10000
	cp (hl)			;4279
	jr nc,MIRA_RECORD		;427a
	push de			;427c
	push hl			;427d
	add a,004h		;427e   ; y el liston sube 4, o sea 40000 puntos hasta la siguiente
	daa			;4280
	jr nc,DA_VIDA_EXTRA		;4281
	ld a,0ffh		;4283   ; pasado el 999999 el liston se clava en 0xFF y ya no da mas vidas
DA_VIDA_EXTRA:		; Sube el liston, suma una vida y repinta
	ld (0e052h),a		;4285   ; el liston nuevo
	ld hl,0e050h		;4288
	inc (hl)			;428b   ; una vida mas
	call PINTA_VIDAS		;428c
	ld a,00bh		;428f   ; 0x0B es el aviso de vida extra
	call PIDE_SONIDO		;4291
	pop hl			;4294
	pop de			;4295
MIRA_RECORD:		; Compara los puntos con el record
	ld a,(0e045h)		;4296   ; y si la puntuacion pasa al record, lo actualiza
	ld b,(hl)			;4299
	sub b			;429a
	jr c,NUEVO_RECORD		;429b
	jr nz,PINTA_LOS_PUNTOS		;429d
	ld hl,(0e043h)		;429f   ; ...y si empatan, por los dos de abajo
	sbc hl,de		;42a2
	jr nc,PINTA_LOS_PUNTOS		;42a4
NUEVO_RECORD:		; Copia los puntos al record
	ld (0e043h),de		;42a6   ; los puntos pasan a ser el record
	ld a,b			;42aa
	ld (0e045h),a		;42ab
	jr PINTA_EL_RECORD		;42ae
PINTA_PANEL:		; Rotulos del panel, vidas, escena, puntos y record
	ld de,04b00h		;42b0   ; el guion de los rotulos del panel
	call PINTA_GUION		;42b3
	call PINTA_VIDAS		;42b6
	call PINTA_ESCENA		;42b9
	ld de,04b2fh		;42bc   ; el rotulo (c)KONAMI, siete celdas en 0x3AD8
	ld hl,03ad8h		;42bf
	ld bc,00007h		;42c2
	call A_VRAM		;42c5
	ld hl,03afah		;42c8   ; y 1984, cinco celdas mas en 0x3AFA
	ld c,005h		;42cb
	call A_VRAM		;42cd
PINTA_EL_RECORD:		; Las seis cifras del record, en la fila 2 del panel
	ld de,0e045h		;42d0   ; el record va en 0x38B9, fila 2 del panel
	ld hl,038b9h		;42d3
	call PINTA_TRES		;42d6
PINTA_LOS_PUNTOS:		; Las seis cifras de los puntos, en la fila 1 del panel
	ld hl,03859h		;42d9   ; los puntos en 0x3859, fila 1
	ld de,0e04bh		;42dc
PINTA_TRES:		; Escribe tres bytes BCD (seis cifras) en la tabla de nombres
	ld b,003h		;42df   ; tres bytes BCD son seis cifras
	jr PINTA_DOS_CIFRAS		;42e1
PINTA_ESCENA:		; Escribe el numero de escena
	ld hl,03a3ch		;42e3   ; la escena es un solo byte BCD en 0x3A3C
	ld a,(0e002h)		;42e6   ; estas dos instrucciones no hacen nada: PINTA_DOS_CIFRAS pisa A en el acto con el byte BCD
	and 040h		;42e9
	ld de,0e051h		;42eb
	ld b,001h		;42ee
PINTA_DOS_CIFRAS:		; Las dos cifras BCD de un byte, del alto al bajo
	ld a,(de)			;42f0   ; la cifra de arriba es el nibble alto
	rra			;42f1
	rra			;42f2
	rra			;42f3
	rra			;42f4
	and 00fh		;42f5   ; la fuente arranca en 0x10, asi que la cifra se suma a 0x10
	add a,010h		;42f7
	call 0004dh		;42f9   ; BIOS WRTVRM - Writes data in VRAM
	inc hl			;42fc
	ld a,(de)			;42fd   ; y detras la cifra de abajo
	and 00fh		;42fe
	add a,010h		;4300
	call 0004dh		;4302   ; BIOS WRTVRM - Writes data in VRAM
	dec de			;4305   ; los bytes BCD van del alto al bajo, por eso dec de
	inc hl			;4306
	djnz PINTA_DOS_CIFRAS		;4307
	ret			;4309
PINTA_VIDAS:		; Dibuja hasta seis avioncitos de vidas
	ld a,(0e050h)		;430a   ; hasta seis avioncitos, aunque haya mas vidas
	ld b,006h		;430d
	ld c,a			;430f
PINTA_UNA_VIDA:		; Un avioncito: elige su celda de la tabla de nombres
	ld a,006h		;4310   ; cuenta los avioncitos de 0 a 5
	sub b			;4312
	ld hl,03939h		;4313   ; el primero va en la celda 0x3939
	cp 003h		;4316   ; del cuarto en adelante bajan a otra fila
	jr c,VIDAS_SEGUNDA_FILA		;4318
	ld l,079h		;431a   ; 0x3979 es la fila de abajo
	sub 003h		;431c
VIDAS_SEGUNDA_FILA:		; Los avioncitos del cuarto al sexto van una fila mas abajo
	add a,a			;431e   ; dos celdas de ancho por avioncito
	call SUMA_A_HL		;431f
	ld e,000h		;4322
	dec c			;4324   ; mientras queden vidas, E a 0xFF...
	inc c			;4325
	jr z,DIBUJA_O_BORRA		;4326
	dec c			;4328
	dec e			;4329   ; ...y agotadas, E a cero, que borra en vez de pintar
DIBUJA_O_BORRA:		; Con E a cero pinta ceros: asi se borra el avioncito
	ld a,0a4h		;432a   ; 0xA4 es la esquina de arriba a la izquierda del avioncito
	call PINTA_AVION		;432c
	djnz PINTA_UNA_VIDA		;432f
	ret			;4331
PINTA_AVION:		; Un avioncito de 2x2 celdas, o lo borra si E vale cero
	call PINTA_CELDA		;4332   ; arriba a la izquierda y arriba a la derecha
	call PINTA_CELDA		;4335
	ex af,af'			;4338   ; el patron va en A y no debe perderse en la cuenta de la fila
	ld a,01eh		;4339   ; 0x1E lleva de la esquina derecha de arriba a la izquierda de abajo
	add a,l			;433b
	ld l,a			;433c
	ex af,af'			;433d
	call PINTA_CELDA		;433e   ; y las dos celdas de abajo, que son 0xA6 y 0xA7
PINTA_CELDA:		; Escribe (A y E) en la celda HL y pasa a la siguiente
	and e			;4341   ; con E a cero sale un cero: eso borra la celda
	call 0004dh		;4342   ; BIOS WRTVRM - Writes data in VRAM
	inc a			;4345   ; los cuatro patrones van seguidos
	inc hl			;4346
	ret			;4347
CARGA_TITULO_ENTERO:		; Los graficos del titulo y su rotulo
	call CARGA_TITULO		;4348   ; la pantalla de titulo entera
	jr PINTA_ROTULO		;434b
CARGA_TITULO:		; Borra la pantalla y carga los graficos del titulo
	ld b,0e0h		;434d   ; 0xE0 apaga la pantalla mientras se cargan los graficos
	call REGISTRO_7		;434f
	call BORRA_NOMBRES		;4352
	ld de,04d61h		;4355   ; los patrones del rotulo van a 0x2600, encima de los del paisaje
	ld hl,02600h		;4358
	call DESC_TRES		;435b
	ld bc,000e0h		;435e   ; 224 bytes de color 0xF0 desde 0x0600: 28 caracteres en blanco sobre negro
	ld hl,00600h		;4361
	ld a,0f0h		;4364
	call RELLENA_TRES		;4366
	ld hl,006e0h		;4369   ; y 96 bytes mas, doce caracteres, del color 0x80
	ld bc,00060h		;436c
	ld a,080h		;436f
	jp RELLENA_TRES		;4371
PINTA_ROTULO:		; El rotulo del titulo y el letrero PUSH SPACE KEY
	ld de,04e82h		;4374   ; el guion de celdas del rotulo
	call DESC_VRAM		;4377
	ld de,04b1ch		;437a   ; y el letrero PUSH SPACE KEY
	call PINTA_GUION		;437d
	ret			;4380
BORRA_NOMBRES:		; Borra la tabla de nombres y apaga los sprites
	ld bc,00300h		;4381   ; las 768 celdas de la tabla de nombres a cero
	ld hl,03800h		;4384
	xor a			;4387
	call 00056h		;4388   ; BIOS FILVRM - Fills VRAM with value
	jp APAGA_SPRITES		;438b   ; y ninguna ficha de sprite a la vista
A_VRAM:		; LDIRVM con los argumentos al reves: DE origen, HL destino
	ex de,hl			;438e   ; LDIRVM quiere el destino en HL y el origen en DE, justo al reves
	jp 0005ch		;438f   ; BIOS LDIRVM - Block transfers to VRAM from memory
MUERTA_A_VRAM:		; La variante con C a cero de 0x438E. Nadie la llama
	ld c,000h		;4392   ; la misma con C a cero, o sea nada que copiar. Nadie la llama
	jr A_VRAM		;4394

; ----------------------------------------------------------------------
; EL DESCOMPRESOR A LA VRAM. El formato esta en la cabecera del fichero.
; ----------------------------------------------------------------------
DESC_VRAM:		; Descomprime a la VRAM leyendo la direccion del propio guion
	ex de,hl			;4396   ; los dos primeros bytes del guion son la direccion de VRAM
	ld e,(hl)			;4397
	inc hl			;4398
	ld d,(hl)			;4399
	ex de,hl			;439a
	inc de			;439b
DESC_VRAM_HL:		; Igual, pero con la direccion de VRAM ya puesta en HL
	call PREPARA_ESCRITURA		;439c   ; prepara la escritura y se guarda el puerto de datos
	exx			;439f
	ld a,c			;43a0   ; C prima trae el puerto; C lo usa el out (c),a
	exx			;43a1
	ld c,a			;43a2
DESC_VRAM_PASO:		; Lee el siguiente byte de mando del guion
	ld a,(de)			;43a3   ; el byte de mando
	inc de			;43a4
	ld b,a			;43a5
	and a			;43a6   ; 0x00 acaba el guion
	ret z			;43a7
	and 07fh		;43a8   ; quitado el bit 7, si no cambia era una repeticion
	cp b			;43aa
	jr z,DESC_VRAM_REPITE		;43ab
	and a			;43ad   ; 0x80 pelado empieza otro bloque, con su direccion detras
	jr z,DESC_VRAM		;43ae
	ld b,a			;43b0
DESC_VRAM_COPIA:		; Copia B bytes tal cual al puerto del VDP
	ld a,(de)			;43b1   ; los bytes van al puerto uno detras de otro
	inc de			;43b2
	out (c),a		;43b3
	djnz DESC_VRAM_COPIA		;43b5
	jr DESC_VRAM_PASO		;43b7
DESC_VRAM_REPITE:		; Coge el byte que hay que repetir
	ld a,(de)			;43b9   ; el byte que hay que repetir
	inc de			;43ba
DESC_VRAM_REPITE_BUCLE:		; Lo manda B veces, con un nop de respiro
	out (c),a		;43bb   ; el nop es el respiro que el VDP necesita entre escritura y escritura
	nop			;43bd
	djnz DESC_VRAM_REPITE_BUCLE		;43be
	jr DESC_VRAM_PASO		;43c0
PREPARA_ESCRITURA:		; SETWRT y deja el puerto de datos del VDP en C prima
	ex af,af'			;43c2   ; el registro alterno guarda A mientras la BIOS trabaja
	call 00053h		;43c3   ; BIOS SETWRT - Enables VDP to write
	exx			;43c6
	ld a,(00006h)		;43c7   ; 0x0006 es la variable de sistema con el puerto de datos del VDP
	ld c,a			;43ca
	exx			;43cb
	ex af,af'			;43cc
	ret			;43cd
MUERTA_PREPARA_LECTURA:		; La gemela para LEER de la VRAM. Nadie la llama
	call 00050h		;43ce   ; BIOS SETRD - Enables VDP to read | la gemela para LEER de la VRAM. Nadie la llama, este cartucho nunca lee la VRAM
	exx			;43d1
	ld a,(00007h)		;43d2
	ld c,a			;43d5
	exx			;43d6
	ret			;43d7
PINTA_GUION:		; Vuelca un guion de celdas en la tabla de nombres
	ld c,0ffh		;43d8   ; C a 0xFF deja pasar los bytes tal cual
PINTA_GUION_BLOQUE:		; Coge la direccion de VRAM del bloque que empieza
	ex de,hl			;43da   ; la direccion de VRAM, delante de cada bloque
	ld e,(hl)			;43db
	inc hl			;43dc
	ld d,(hl)			;43dd
	ex de,hl			;43de
	inc de			;43df
	call PREPARA_ESCRITURA		;43e0
PINTA_GUION_PASO:		; Un byte del guion: 0xFF acaba, 0xFE cambia de bloque
	ld a,(de)			;43e3   ; un byte por celda
	inc de			;43e4
	ld b,a			;43e5
	inc b			;43e6   ; 0xFF acaba el guion
	ret z			;43e7
	inc b			;43e8   ; 0xFE empieza otro bloque
	jr z,PINTA_GUION_BLOQUE		;43e9
	and c			;43eb   ; aqui esta el truco: con C a cero sale un cero y la celda se borra
	exx			;43ec
	out (c),a		;43ed
	exx			;43ef
	inc hl			;43f0   ; el inc hl no hace falta, la VRAM va sola
	jr PINTA_GUION_PASO		;43f1
BORRA_GUION:		; El mismo guion, pero escribiendo ceros
	ld c,000h		;43f3   ; la misma entrada, pero borrando
	jr PINTA_GUION_BLOQUE		;43f5
RELLENA_TRES:		; FILVRM repetido en los tres tercios
	ld d,003h		;43f7   ; los tres tercios de la pantalla llevan lo mismo
RELLENA_TERCIO:		; Un tercio, y suma 0x800 para el siguiente
	push bc			;43f9
	push de			;43fa
	call 00056h		;43fb   ; BIOS FILVRM - Fills VRAM with value
	ld de,00800h		;43fe   ; 0x800 es lo que mide un tercio de pantalla
	add hl,de			;4401
	pop de			;4402
	pop bc			;4403
	dec d			;4404   ; tres tercios y fuera
	jr nz,RELLENA_TERCIO		;4405
	ret			;4407
DESC_TRES:		; Descomprime lo mismo en los tres tercios
	ld b,003h		;4408   ; la version del descompresor para los tres tercios
DESC_TERCIO:		; Descomprime un tercio, y suma 0x800 para el siguiente
	push bc			;440a
	push de			;440b
	call DESC_VRAM_HL		;440c   ; descomprime en el tercio que toca...
	ld de,00800h		;440f   ; ...y el siguiente va 0x800 mas alla
	add hl,de			;4412
	pop de			;4413
	pop bc			;4414
	djnz DESC_TERCIO		;4415
	ret			;4417
ARRANCA_VDP:		; Registros del VDP y borrado de los 16 KB de VRAM
	ld a,0b8h		;4418   ; 0xB8 va al registro 7 del PSG: los tres tonos abiertos y el ruido cerrado
	call CORTA_SONIDO		;441a
	ld a,09dh		;441d   ; y silencia los tres canales con la 0x9D
	call PONE_SONIDO		;441f
	ld de,00000h		;4422   ; los 16 KB de VRAM a cero, de una sentada
	ld bc,04000h		;4425
	xor a			;4428
	call 00056h		;4429   ; BIOS FILVRM - Fills VRAM with value
CARGA_REGISTROS:		; Manda los ocho registros del VDP
	ld hl,0443dh		;442c   ; los ocho registros salen de la tabla de 0x443D
	ld d,008h		;442f
	ld c,000h		;4431   ; se escriben del 0 al 7, por orden
MANDA_REGISTRO:		; Escribe un registro del VDP y pasa al siguiente
	ld b,(hl)			;4433   ; B es el valor y C el numero de registro, que es lo que quiere WRTVDP
	call 00047h		;4434   ; BIOS WRTVDP - Writes data in the VDP-register
	inc hl			;4437
	inc c			;4438
	dec d			;4439
	jr nz,MANDA_REGISTRO		;443a
	ret			;443c

; ----------------------------------------------------------------------
; DATOS tabla_registros_vdp: Los ocho registros del VDP: SCREEN 2 y sprites de
;   16x16
;   0x443d..0x4445  (8 bytes)
DATA_tabla_registros_vdp:
	defb 002h,0e2h,00eh,07fh,007h,076h,003h,0e0h	; 443d  .....v..

; ======================================================================
; CODIGO 0x4445..0x4625  (480 bytes)
; ======================================================================


REGISTRO_7:		; Escribe B en el registro 7 (color del borde)
	ld c,007h		;4445   ; el registro 7 lleva el color del borde y del fondo
	jp 00047h		;4447   ; BIOS WRTVDP - Writes data in the VDP-register
LEE_MANDO:		; Lee el mando 1 por el PSG, registros 15 y 14
	ld e,08fh		;444a   ; bit 6 de 0x8F a cero: mando del puerto 1
LEE_MANDO_CON_E:		; Entrada de 0x444A con el registro 15 ya elegido en E
	ld a,00fh		;444c   ; el registro 15 del PSG elige el puerto...
	call 00093h		;444e   ; BIOS WRTPSG - Writes data to PSG-register
	ld a,00eh		;4451   ; ...y el 14 devuelve lo que hay en el
	di			;4453
	call 00096h		;4454   ; BIOS RDPSG - Reads value from PSG-register
	ei			;4457
	cpl			;4458   ; el PSG da los bits al reves y sobran los dos de arriba
	and 03fh		;4459
	ret			;445b
LEE_MANDOS:		; Junta mando y teclado en 0xE00A, y deja en 0xE009 los recien pulsados
	call LEE_MANDO		;445c   ; mando y teclado se suman: vale cualquiera de los dos
	push af			;445f
	call LEE_TECLADO		;4460
	pop hl			;4463
	or h			;4464
	ld hl,0e002h		;4465
	bit 6,(hl)		;4468   ; sin partida en marcha (bit 6 de 0xE002) manda el guion del demo
	call z,MANDO_DEL_DEMO		;446a
	ld hl,0e00ah		;446d   ; 0xE00A guarda lo que hay pulsado ahora...
	ld c,(hl)			;4470
	ld (hl),a			;4471
	xor c			;4472   ; ...y 0xE009 solo lo que se acaba de pulsar: lo nuevo y no lo de antes
	and (hl)			;4473
	dec hl			;4474
	ld (hl),a			;4475
	inc hl			;4476
	ld a,(hl)			;4477
	ret			;4478
LEE_TECLADO:		; Cursores y espacio de las filas 7 y 8, recolocados como el mando
	ld a,007h		;4479   ; la fila 7 del teclado; de ella solo interesa un bit
	call 00141h		;447b   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix
	cpl			;447e   ; el teclado tambien viene al reves
	rrca			;447f   ; el bit 6 de la fila 7 (SELECT) cae en el sitio del segundo disparo
	and 020h		;4480
	ld e,a			;4482
	ld a,008h		;4483   ; la fila 8: espacio, cursores y las teclas de edicion
	call 00141h		;4485   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix
	cpl			;4488
	rrca			;4489   ; dos rotaciones dejan el cursor izquierdo en su bit
	rrca			;448a
	ld b,a			;448b
	and 004h		;448c   ; el bit 2 es izquierda
	or e			;448e
	ld c,a			;448f
	ld a,b			;4490
	rrca			;4491   ; dos mas: el cursor derecho al bit 3 y el espacio al bit 4
	rrca			;4492
	ld b,a			;4493
	and 018h		;4494   ; bit 3 derecha y bit 4 disparo
	or c			;4496
	ld c,a			;4497
	ld a,b			;4498
	rrca			;4499   ; y una ultima: arriba al bit 0 y abajo al bit 1
	and 003h		;449a   ; asi queda el byte con la misma forma que el del mando
	or c			;449c
	ret			;449d
MANDO_DEL_DEMO:		; Sin partida en marcha, los mandos salen del guion del demo
	ld hl,0e00ch		;449e   ; 0xE00C es el paso del guion del demo
	ld a,(0e003h)		;44a1   ; el guion avanza un paso cada 32 fotogramas
	and 01fh		;44a4
	ld a,(hl)			;44a6
	jr nz,PASO_DEL_DEMO		;44a7
	inc (hl)			;44a9
PASO_DEL_DEMO:		; Coge el mando falso que toca y le anade el disparo
	ld hl,04b5fh		;44aa   ; el guion de mandos falsos empieza en 0x4B5F
	call SUMA_A_HL		;44ad
	ld a,(hl)			;44b0
	ld l,a			;44b1
	ld a,(0e003h)		;44b2   ; y cada ocho fotogramas se anade el disparo
	and 007h		;44b5
	jr nz,FIN_PASO_DEMO		;44b7
	set 4,l		;44b9   ; bit 4: disparo
FIN_PASO_DEMO:		; Con 0xFF el guion del demo vuelve al principio
	ld a,l			;44bb   ; 0xFF marca el final del guion...
	cp 0ffh		;44bc
	ret nz			;44be
	xor a			;44bf   ; ...y lo devuelve al principio
	ld (0e00ch),a		;44c0
	ret			;44c3
RETORNO_TITULO:		; Retorno comun de los estados 0 a 2: mira si se empieza a jugar
	ld e,08fh		;44c4   ; el mismo 0x8F que pone LEE_MANDO: entrar por 0x444C no ahorra nada
	call LEE_MANDO_CON_E		;44c6   ; lee el mando...
	ld d,a			;44c9
	call LEE_TECLADO		;44ca   ; ...y el teclado, y los junta
	or d			;44cd
	ld hl,0e042h		;44ce   ; 0xE042 lleva los mandos del titulo, aparte de los de la partida
	ld b,(hl)			;44d1
	ld (hl),a			;44d2
	xor b			;44d3
	and (hl)			;44d4
	and 01fh		;44d5   ; cualquiera de los cinco bits sirve; sin nada nuevo, nada que hacer
	ret z			;44d7
	ld hl,0e000h		;44d8   ; con la partida ya empezada (subestado distinto de cero) va a 0x44EC
	ld b,(hl)			;44db
	djnz EMPIEZA_PARTIDA		;44dc   ; en los estados 0 y 2 cualquier tecla adelanta al rotulo del titulo
	and 010h		;44de   ; en el estado 1 hace falta el disparo
	ret z			;44e0
	ld a,040h		;44e1   ; con el disparo: marca partida en marcha y salta al estado 3
	ld (0e002h),a		;44e3
	ld (hl),003h		;44e6   ; estado 3, que es el que la arranca
	inc hl			;44e8
	ld (hl),000h		;44e9
	ret			;44eb
EMPIEZA_PARTIDA:		; Pone el subestado a uno y vuelve al titulo por 0x4146
	xor a			;44ec   ; sin cuenta atras...
	ld (0e004h),a		;44ed
	ld (hl),001h		;44f0   ; ...estado 1, o sea directo a la espera del rotulo
	jp VUELVE_AL_TITULO		;44f2
ARRANCA_CORTINILLA:		; Prepara la cortinilla de la pantalla de titulo
	ld a,011h		;44f5   ; diecisiete anillos de cortinilla
	ld (0e00dh),a		;44f7
	ld hl,03aaah		;44fa   ; el primero arranca en la celda 0x3AAA, abajo del todo
	ld (0e00eh),hl		;44fd
	ld b,0e4h		;4500   ; 0xE4 pinta el borde mientras dura la cortinilla
	jp REGISTRO_7		;4502
PASO_CORTINILLA:		; Un anillo de la cortinilla, de fuera adentro
	ld hl,(0e00eh)		;4505   ; cada paso sube una fila entera
	ld de,0ffe0h		;4508
	add hl,de			;450b
	ld (0e00eh),hl		;450c
	ld a,040h		;450f   ; el adorno arranca en el caracter 0x40 y va subiendo
	ld b,003h		;4511   ; tres celdas en la primera fila...
	call ANILLO_CORTINILLA		;4513
	ld bc,00b0ch		;4516   ; ...once en la segunda...
	call ANILLO_CORTINILLA		;4519
	ld b,c			;451c   ; ...y doce en la tercera
	call ANILLO_CORTINILLA		;451d
	xor a			;4520   ; y borra las doce de la cuarta, que es la que va quedando atras
	call 00056h		;4521   ; BIOS FILVRM - Fills VRAM with value
	ld hl,0e00dh		;4524   ; un anillo menos
	dec (hl)			;4527
	ret			;4528
ANILLO_CORTINILLA:		; Pinta B celdas y baja una fila
	push hl			;4529   ; se guarda el arranque de la fila para poder bajar a la siguiente
ANILLO_BUCLE:		; Cada celda del anillo lleva el patron siguiente
	call 0004dh		;452a   ; BIOS WRTVRM - Writes data in VRAM | cada celda lleva el caracter siguiente: el adorno no se repite
	inc hl			;452d
	inc a			;452e
	djnz ANILLO_BUCLE		;452f
	pop de			;4531
	ld hl,00020h		;4532   ; 0x20 es una fila de la tabla de nombres
	add hl,de			;4535
	ret			;4536
PASO_DE_FASE:		; Un fotograma de la fase en marcha
	ld hl,0e1dch		;4537   ; 0xE1DC es la espera de entrada: mientras corre, la fase esta quieta
	ld a,(hl)			;453a
	and a			;453b
	jr z,FOTOGRAMA		;453c
	dec (hl)			;453e
	ret nz			;453f

; ----------------------------------------------------------------------
; EL FOTOGRAMA DE LA PARTIDA. Todo lo que pasa en un barrido.
; ----------------------------------------------------------------------
FOTOGRAMA:		; Todo lo que pasa en un barrido de la partida
	ld a,(0e01ah)		;4540   ; mientras suena la musica de arranque (0x93) no hay fotograma
	cp 093h		;4543
	ret z			;4545
	call SPRITES_A_VRAM		;4546   ; los sprites a la VRAM
	call PASO_DE_FONDO		;4549   ; el fondo
	call MUEVE_AVION		;454c   ; el avion
	call TOCA_ENEMIGO		;454f   ; el enemigo que toca
	call RECORRE_OBJETOS		;4552   ; los siete objetos
	call PASO_OBJETOS		;4555
	ld a,(0e1b0h)		;4558   ; 0xE1B0 a 7 pide el reparto de enemigos cada 60 fotogramas
	cp 007h		;455b
	call z,REPARTE_CADA_60		;455d
	call RECORRE_HUECOS_DISPARO		;4560
	call PASO_DISPAROS_MUEVE		;4563
	call PASO_DISPAROS		;4566
	call DISPARA		;4569
	call MUEVE_BALAS		;456c
	call CHOQUES_AVION_OBJETOS		;456f
	call CHOQUES_AVION_DISPAROS		;4572
	call CHOQUES_BALAS_OBJETOS		;4575
	call EPISODIO_GIGANTE		;4578
	ld a,(0e140h)		;457b   ; el episodio del gigante, en los dos bits de abajo
	and 003h		;457e
	jr z,FOTOGRAMA_FIN		;4580
	cp 002h		;4582   ; con 2 el gigante esta en pantalla y ademas siguen saliendo enemigos
	call z,ENEMIGO_PERIODICO		;4584
	call RECORRE_GIGANTE		;4587
	call MUEVE_GIGANTE		;458a
	ld a,(0e140h)		;458d   ; solo el episodio 2 anima y pinta el cuerpo del bicho
	cp 002h		;4590
	jr nz,FOTOGRAMA_GIGANTE		;4592
	call RITMO_GIGANTE		;4594
	call PINTA_GIGANTE		;4597
FOTOGRAMA_GIGANTE:		; Los sprites y los choques del enemigo grande
	call GIGANTE_A_SPRITES		;459a   ; los sprites del gigante son las piezas a las que se dispara
	call CHOQUES_BALAS_GIGANTE		;459d
FOTOGRAMA_FIN:		; Los caracteres del gigante y el reparto de oleadas
	call CARGA_GIGANTE		;45a0   ; los caracteres del gigante se cargan a plazos, un trozo por fotograma
	jp REVISA_OLEADA		;45a3
ARRANCA_VIDA:		; Coloca el avion y los contadores para una vida nueva
	ld b,0e0h		;45a6   ; 0xE0 apaga la pantalla mientras se rehace
	call REGISTRO_7		;45a8
	call APAGA_FICHAS		;45ab   ; quita las fichas de sprite de en medio
	ld hl,0e200h		;45ae   ; los siete huecos de objeto y todo 0xE200-0xE33F a cero
	ld de,0e201h		;45b1
	ld bc,0013fh		;45b4
	ld (hl),000h		;45b7
	ldir		;45b9
	ld de,0e180h		;45bb   ; el avion vuelve a su fila y su columna de salida
	ld hl,04625h		;45be
	ld bc,00007h		;45c1
	ldir		;45c4
	ld hl,0e1b8h		;45c6   ; la posicion en la fase retrocede al multiplo de 64 filas de mas abajo
	ld a,0c0h		;45c9
	and (hl)			;45cb
	ld (hl),a			;45cc
	inc hl			;45cd   ; 0xE1BA a cero: sin desplazamiento fino
	inc hl			;45ce
	ld (hl),000h		;45cf
	xor a			;45d1
	ld (0e1d9h),a		;45d2   ; contadores de oleada, objetos vivos y cuenta de muerte, todos a cero
	ld (0e196h),a		;45d5
	ld (0e1cfh),a		;45d8
	ld (0e194h),a		;45db
	ld (0e1d4h),a		;45de
	ld (0e1d5h),a		;45e1
	ld (0e198h),a		;45e4
	ld (0e1ddh),a		;45e7
	call ARRANCA_OLEADAS		;45ea   ; reparte la oleada que toca a esta altura de la fase
	ld hl,0e140h		;45ed
	ld a,(hl)			;45f0   ; si el gigante estaba en marcha hay que decidir si sigue
	ld c,(hl)			;45f1
	and 003h		;45f2
	jr z,BORRA_EXPLOSIONES		;45f4
	inc hl			;45f6
	dec a			;45f7   ; con el episodio 1 (aun no ha llegado) se cancela...
	ld a,008h		;45f8   ; ...y con el 2 o el 3 se queda, con el fotograma en 8
	jr nz,GUARDA_GIGANTE		;45fa
	xor a			;45fc
	ld c,a			;45fd
GUARDA_GIGANTE:		; Deja el episodio del gigante como estaba
	ld (hl),a			;45fe   ; deja el fotograma del gigante...
	dec hl			;45ff   ; ...y su episodio
	ld (hl),c			;4600
	call MUEVE_GIGANTE		;4601   ; y lo vuelve a colocar en sus sprites
	call GIGANTE_A_SPRITES		;4604
BORRA_EXPLOSIONES:		; Deja a cero las seis explosiones y espera 0x60
	ld hl,0e145h		;4607   ; las seis explosiones a cero
	ld de,0e146h		;460a
	ld bc,00005h		;460d
	ld (hl),000h		;4610
	ldir		;4612
	ld a,060h		;4614   ; 0x60 fotogramas de espera antes de que la fase eche a andar
	ld (0e1dch),a		;4616
	call CARGA_SPRITES		;4619   ; los 48 patrones de sprite
	call AVION_A_SPRITES		;461c   ; el avion a sus dos fichas...
	call SPRITES_A_VRAM		;461f   ; ...y las fichas a la VRAM
	jp PINTA_FONDO		;4622   ; y el fondo entero de una vez

; ----------------------------------------------------------------------
; DATOS estado_inicial_avion: Los siete bytes que van a 0xE180: fila 0xA0,
;   columna 0x5C y los patrones
;   0x4625..0x462c  (7 bytes)
DATA_estado_inicial_avion:
	defb 000h,0a0h,05ch,000h,004h,004h,00fh	; 4625

; ======================================================================
; CODIGO 0x462c..0x48ca  (670 bytes)
; ======================================================================


PASO_DE_MUERTE:		; La cuenta atras de la explosion del avion
	inc hl			;462c   ; 0xE1D0 es la cuenta atras de la explosion del avion
	dec (hl)			;462d
	jr z,MUERTE_FIN		;462e
	ld a,(hl)			;4630   ; la explosion cambia de patron dos veces por el camino
	cp 060h		;4631
	ld c,094h		;4633   ; 0x94 al principio...
	jr nc,MUERTE_COLOR		;4635
	ld c,09ch		;4637   ; ...0x9C por debajo de 0x60...
MUERTE_COLOR:		; Elige el patron de la explosion segun la cuenta atras
	cp 040h		;4639
	jr nc,MUERTE_FICHA		;463b
	ld c,0f8h		;463d   ; ...y 0xF8 por debajo de 0x40, que es el avion cayendo
MUERTE_FICHA:		; Deja las dos fichas de sprite de la explosion
	ld hl,0e0b2h		;463f   ; la ficha 0 del avion lleva el patron y el color 6
	ld (hl),c			;4642
	inc hl			;4643
	ld (hl),006h		;4644   ; color 6, rojo oscuro
	inc hl			;4646
	inc hl			;4647   ; y la ficha 1 va cuatro patrones mas alla
	inc hl			;4648
	ld a,c			;4649
	add a,004h		;464a
	ld (hl),a			;464c
	inc hl			;464d
	ld (hl),00fh		;464e   ; color 15, blanco, encima del rojo
	ret			;4650
MUERTE_FIN:		; Cuando no queda ninguna explosion, la fase para
	inc (hl)			;4651   ; se queda en 1: la cuenta no baja de ahi
	ex de,hl			;4652
	ld hl,0e145h		;4653   ; 0xE145-0xE14A son las seis explosiones
	xor a			;4656
	ld b,006h		;4657
SUMA_EXPLOSIONES:		; Junta los seis contadores para ver si queda alguna
	or (hl)			;4659   ; con que quede una sola, la fase sigue
	inc hl			;465a
	djnz SUMA_EXPLOSIONES		;465b
	ret nz			;465d
	ex de,hl			;465e
	ld (0e053h),a		;465f   ; agotadas todas, 0xE053 a cero acaba la fase
	ret			;4662
MUEVE_AVION:		; Lee los mandos y mueve el avion dentro de los topes
	ld hl,0e1cfh		;4663   ; 0xE1CF distinto de cero: el avion esta muerto
	ld a,(hl)			;4666
	and a			;4667
	jr nz,PASO_DE_MUERTE		;4668
	ld a,(0e00ah)		;466a   ; los mandos que usa el avion
	ld hl,(0e181h)		;466d   ; L es la fila y H la columna
	ld e,l			;4670   ; se guarda la posicion de antes por si el tope la rechaza
	ld d,h			;4671
	ld bc,00000h		;4672   ; B es lo que cambia la columna y C la fila
	rra			;4675   ; bit 0: sube una fila
	jr nc,MANDO_ABAJO		;4676
	dec c			;4678
MANDO_ABAJO:		; Bit 1 del mando: baja una fila
	rra			;4679   ; bit 1: baja una fila
	jr nc,MANDO_IZQUIERDA		;467a
	inc c			;467c
MANDO_IZQUIERDA:		; Bit 2 del mando: una columna a la izquierda
	rra			;467d   ; bit 2: una columna a la izquierda
	jr nc,MANDO_DERECHA		;467e
	dec b			;4680
MANDO_DERECHA:		; Bit 3 del mando: una columna a la derecha
	rra			;4681   ; bit 3: una a la derecha
	jr nc,TOPE_COLUMNA		;4682
	inc b			;4684
TOPE_COLUMNA:		; H es la columna; fuera de 0x0A-0xAD se queda como estaba
	ld a,h			;4685   ; la columna se mueve entre 0x0A y 0xAD
	add a,b			;4686
	ld h,a			;4687
	sub 00ah		;4688
	cp 0a4h		;468a
	jr c,TOPE_FILA		;468c
	ld h,d			;468e   ; fuera de ahi se queda como estaba
TOPE_FILA:		; L es la fila; fuera de 0x40-0xAF se queda como estaba
	ld a,l			;468f   ; y la fila entre 0x40 y 0xAF: el avion no puede subir mas alla de un tercio
	add a,c			;4690
	ld l,a			;4691
	sub 040h		;4692
	cp 070h		;4694
	jr c,GUARDA_AVION		;4696
	ld l,e			;4698   ; igual, se queda como estaba
GUARDA_AVION:		; Deja la posicion nueva en 0xE181/82
	ld (0e181h),hl		;4699   ; posicion nueva
AVION_A_SPRITES:		; Copia el avion a sus DOS fichas de sprite, 0xE0B0 a 0xE0B7
	ld de,0e0b0h		;469c   ; las dos fichas del avion son 0xE0B0 a 0xE0B7
	ld hl,0e181h		;469f
	push hl			;46a2
	ld bc,00004h		;46a3   ; fila, columna, patron 0 y color 4 de la primera
	ldir		;46a6
	pop hl			;46a8
	ld c,002h		;46a9   ; la segunda repite fila y columna...
	ldir		;46ab
	inc hl			;46ad
	inc hl			;46ae
	ld c,002h		;46af   ; ...y se queda el patron 4 y el color 15, encima de la otra
	ldir		;46b1
	ret			;46b3
DISPARA:		; Con el disparo, busca hueco libre y lanza una bala
	ld a,(0e1cfh)		;46b4   ; muerto no se dispara
	and a			;46b7
	ret nz			;46b8
	ld a,(0e009h)		;46b9   ; el disparo tiene que ser NUEVO: no vale dejarlo apretado
	and 010h		;46bc
	ret z			;46be
	ld b,002h		;46bf   ; dos balas a la vez de normal...
	ld a,(0e1d5h)		;46c1   ; ...y tres cuando 0xE1D5 llega a 2
	cp 002h		;46c4
	jr c,BUSCA_BALA		;46c6
	inc b			;46c8
BUSCA_BALA:		; Busca hueco entre las tres balas
	ld hl,0e0b8h		;46c9   ; las balas son las fichas de sprite 2, 3 y 4 (0xE0B8 en adelante)
BUSCA_BALA_PASO:		; Una bala esta libre cuando su fila vale 0xE0
	ld a,(hl)			;46cc   ; la fila 0xE0 es la marca de bala apagada
	cp 0e0h		;46cd
	jr z,LANZA_BALA		;46cf
	ld a,004h		;46d1   ; cuatro bytes por ficha
	add a,l			;46d3
	ld l,a			;46d4
	djnz BUSCA_BALA_PASO		;46d5
	ret			;46d7
LANZA_BALA:		; Copia la posicion del avion a la bala y hace sonar el disparo
	ld de,(0e181h)		;46d8   ; la bala nace donde esta el avion
	ld (hl),e			;46dc
	inc hl			;46dd
	ld (hl),d			;46de
	inc hl			;46df
	ld a,(0e1d5h)		;46e0   ; el patron de la bala cambia con 0xE1D5: 8 de normal...
	and a			;46e3
	ld a,008h		;46e4
	jr z,BALA_COLOR		;46e6
	ld a,00ch		;46e8   ; ...y 0x0C con el disparo mejorado
BALA_COLOR:		; Patron y color de la bala
	ld (hl),a			;46ea
	inc hl			;46eb
	ld (hl),00fh		;46ec   ; color 15, blanco
	ld a,00ch		;46ee   ; 0x0C es el ruido del disparo
	jp PIDE_SONIDO		;46f0
MUEVE_BALAS:		; Sube las balas seis pixeles y las apaga al salir de la pantalla
	ld b,003h		;46f3   ; las tres balas
	ld hl,0e0b8h		;46f5
MUEVE_UNA_BALA:		; Sube seis pixeles; al pasarse, la apaga
	ld a,(hl)			;46f8   ; la bala apagada no se mueve
	cp 0e0h		;46f9
	jr z,SIGUIENTE_BALA		;46fb
	sub 006h		;46fd   ; seis pixeles por fotograma hacia arriba
	jr nc,GUARDA_BALA		;46ff   ; al pasarse por arriba se apaga
	ld a,0e0h		;4701
GUARDA_BALA:		; Deja la fila nueva de la bala
	ld (hl),a			;4703
SIGUIENTE_BALA:		; Salta a la ficha de la bala siguiente
	inc hl			;4704   ; cuatro bytes hasta la ficha siguiente
	inc hl			;4705
	inc hl			;4706
	inc hl			;4707
	djnz MUEVE_UNA_BALA		;4708
	ret			;470a
PASO_APARICION:		; Cuenta atras entre enemigos
	dec hl			;470b   ; HL entra en 0xE196: retrocede a 0xE193, la cuenta entre enemigo y enemigo
	dec hl			;470c
	dec hl			;470d
	dec (hl)			;470e
	ret nz			;470f
	ld a,(0e1dbh)		;4710   ; el tipo de la tanda estaba guardado en 0xE1DB
	ld (0e1b0h),a		;4713
	ld a,008h		;4716   ; ocho fotogramas hasta el siguiente
	ld (hl),a			;4718
	dec hl			;4719
	ld a,(hl)			;471a   ; 0xE192 lleva el orden dentro de la tanda y pasa a 0xE198
	ld (0e198h),a		;471b
	dec hl			;471e
	dec (hl)			;471f   ; un enemigo menos de la tanda
	jr nz,CREA_ENEMIGO		;4720
	ld l,095h		;4722   ; agotada la tanda, 0xE195 y 0xE196 a cero
	xor a			;4724
	ld (hl),a			;4725
	inc hl			;4726
	ld (hl),a			;4727
	ld a,(0e1b1h)		;4728   ; 0xE1B1 recarga la cuenta de 0xE197
	ld (0e197h),a		;472b
	jr CREA_ENEMIGO		;472e
PIDE_ENEMIGO:		; Encarga el enemigo cuyo tipo llega en A
	ld (0e1dbh),a		;4730   ; se guarda el tipo para los enemigos que quedan de la tanda
	ld hl,0e194h		;4733   ; 0xE194 son los objetos vivos: con alguno en pantalla no se encarga la tanda
	ld c,005h		;4736
	ld a,(hl)			;4738
	and a			;4739
	ret nz			;473a
	ld (0e1dah),a		;473b   ; 0xE1DA a cero
	dec hl			;473e
	ld (hl),008h		;473f   ; ocho fotogramas hasta el primero
	dec hl			;4741
	inc (hl)			;4742   ; 0xE192 arranca la cuenta dentro de la tanda
	dec hl			;4743
	ld (hl),c			;4744   ; cinco enemigos por tanda
	ld l,095h		;4745   ; 0xE195 y 0xE196 marcan la tanda en marcha
	inc (hl)			;4747
	ld a,001h		;4748
	ld (0e196h),a		;474a
	ret			;474d
ENEMIGO_PERIODICO:		; Suelta enemigos cada cierto numero de fotogramas
	ld a,(0e003h)		;474e   ; cada 0x80 fotogramas cae un enemigo de tipo 5 pase lo que pase
	and 07fh		;4751
	jr nz,CUENTA_ATRAS_ENEMIGO		;4753
	ld a,005h		;4755
	jr PONE_TIPO		;4757
CUENTA_ATRAS_ENEMIGO:		; Cada 0x80 fotogramas cambia el tipo que sale
	ld a,(0e1d7h)		;4759   ; el resto del tiempo solo con el gigante en su fase 2
	cp 002h		;475c
	ret nz			;475e
	ld hl,0e144h		;475f   ; 0xE144 es la cuenta atras de los enemigos del gigante
	dec (hl)			;4762
	ret nz			;4763
	ld a,(0e1b1h)		;4764   ; y se recarga con 0xE1B1
	ld (hl),a			;4767
	ld hl,0e198h		;4768
	inc (hl)			;476b
	ld a,004h		;476c   ; tipo 4 mientras el gigante esta delante
PONE_TIPO:		; Deja A como tipo de enemigo y salta a montarlo
	ld (0e1b0h),a		;476e
	jr CREA_ENEMIGO		;4771
TOCA_ENEMIGO:		; Decide si toca soltar un enemigo, y cual
	ld a,(0e140h)		;4773   ; con el gigante en marcha no salen enemigos por la via normal
	and a			;4776
	ret nz			;4777
	ld hl,0e196h		;4778   ; 0xE196 distinto de cero: hay una tanda a medias
	ld a,(hl)			;477b
	and a			;477c
	jr nz,PASO_APARICION		;477d
	call TOCA_OLEADA		;477f   ; la oleada decide si toca soltar algo
	ret c			;4782
	ld a,(0e1b0h)		;4783   ; los tipos 16 y mas alla no existen
	cp 010h		;4786
	ret nc			;4788
	cp 00dh		;4789   ; del 13 al 15 salen en tanda de cinco
	jp nc,PIDE_ENEMIGO		;478b
	ld hl,0e198h		;478e   ; y los demas de uno en uno
	inc (hl)			;4791
CREA_ENEMIGO:		; Monta el hueco de objeto del enemigo 0xE1B0
	ld hl,0e198h		;4792   ; 0xE198 es el contador de aparicion
	ld a,(0e1b0h)		;4795   ; dos rutinas por tipo, asi que el indice va doblado
	add a,a			;4798
	ret z			;4799   ; el tipo 0 no existe
	bit 0,(hl)		;479a   ; el bit 0 del contador elige una de las dos: el mismo tipo alterna
	jr z,LEE_SUBTIPO		;479c
	inc a			;479e
LEE_SUBTIPO:		; Del tipo de enemigo saca su rutina de objeto y su fotograma de partida
	ld de,SALTO_A_COLA		;479f   ; la base es 0x48C8, o sea los dos bytes del jr de aqui arriba
	call SUMA_A_DE		;47a2
	ld a,(de)			;47a5
	ld (0e199h),a		;47a6   ; 0xE199 se queda la rutina de objeto
	ld c,a			;47a9
	inc hl			;47aa
	ld (hl),c			;47ab   ; byte +1 del hueco: la rutina que lo maneja
	inc hl			;47ac
	ld de,048e8h		;47ad   ; 0x48E8 da el fotograma de partida de esa rutina
	call SUMA_A_DE		;47b0
	ld a,(de)			;47b3
	ld (hl),a			;47b4
	ld de,0fff0h		;47b5   ; los huecos se recorren hacia atras, de 16 en 16
	ld hl,0e260h		;47b8
	ld a,(0e321h)		;47bb   ; en la oleada 0x0A solo se pueden usar cuatro de los siete huecos
	ld b,007h		;47be
	cp 00ah		;47c0
	jr nz,BUSCA_HUECO		;47c2
	ld b,004h		;47c4
BUSCA_HUECO:		; Busca hueco libre entre los siete, de 0xE260 hacia abajo
	ld a,(hl)			;47c6   ; hueco libre es el que tiene el tipo a cero
	and a			;47c7
	jr z,OCUPA_HUECO		;47c8
	add hl,de			;47ca
	djnz BUSCA_HUECO		;47cb
	ret			;47cd
OCUPA_HUECO:		; Escribe el tipo, la rutina de objeto y el estado en el hueco
	ld (0e310h),hl		;47ce   ; 0xE310 se queda el hueco elegido
	ld a,(0e1b0h)		;47d1
	ld (hl),a			;47d4   ; byte +0: el tipo
	inc hl			;47d5
	ld (hl),c			;47d6   ; byte +1: la rutina
	inc hl			;47d7
	ld a,003h		;47d8   ; byte +2: el estado, que arranca en 3
	ld (hl),a			;47da
	ld a,(0e1b0h)		;47db
	cp 009h		;47de   ; el tipo 9 usa el byte +2 para otra cosa
	jr nz,ENEMIGO_TIPO_5		;47e0
	ex af,af'			;47e2
	ld a,(0e198h)		;47e3   ; cuatro variantes que rotan con el contador de aparicion
	and 003h		;47e6
	ld de,04975h		;47e8
	call SUMA_A_DE		;47eb
	ld a,(de)			;47ee
	ld (hl),a			;47ef
	ex af,af'			;47f0
ENEMIGO_TIPO_5:		; El tipo 5 lleva en el byte +2 el premio que soltara al morir
	cp 005h		;47f1   ; el tipo 5 es el unico que deja premio al morir
	jr nz,SIGUE_MONTANDO		;47f3
	ex de,hl			;47f5
	ld hl,0e1d4h		;47f6   ; 0xE1D4 cuenta los enemigos de tipo 5 que han salido
	inc (hl)			;47f9
	ld a,(hl)			;47fa
	and 01fh		;47fb
	ld b,000h		;47fd
	cp 018h		;47ff   ; el numero 24 de cada 32 sueltara el premio de 1000 puntos
	jr nz,ENEMIGO_PREMIO		;4801
	inc b			;4803
ENEMIGO_PREMIO:		; Con la cuenta en 6 el premio es la mejora del disparo
	and 00fh		;4804   ; los numeros 6 y 22 de cada 32 sueltan la mejora del disparo...
	cp 006h		;4806
	jr nz,GUARDA_PREMIO		;4808
	ld b,002h		;480a
	ld a,(0e1d5h)		;480c   ; ...salvo que la mejora ya este al tope (0xE1D5 en 2), y entonces no sueltan nada
	cp 002h		;480f
	jr c,GUARDA_PREMIO		;4811
	ld b,000h		;4813
GUARDA_PREMIO:		; Deja el premio elegido en el hueco
	ex de,hl			;4815
	ld (hl),b			;4816   ; byte +2: el premio
SIGUE_MONTANDO:		; Columna de salida, velocidad y patron
	inc hl			;4817
	ld a,(0e1b7h)		;4818   ; byte +3: la cuenta atras hasta su primer disparo
	ld (hl),a			;481b
	inc hl			;481c
	ld a,(0e199h)		;481d   ; la velocidad de caida sale de 0x48FB, indexada por la rutina
	ld c,a			;4820
	ex de,hl			;4821
	ld hl,048fbh		;4822
	call SUMA_A_HL		;4825
	ld l,(hl)			;4828
	ld h,000h		;4829
	add hl,hl			;482b   ; por cuatro: el byte de la tabla es la parte alta de un valor de 16 bits
	add hl,hl			;482c
	ex de,hl			;482d
	ld (hl),e			;482e   ; bytes +4 y +5: la velocidad de fila
	inc hl			;482f
	ld (hl),d			;4830
	inc hl			;4831
	ld a,c			;4832
	add a,a			;4833
	ld de,0490dh		;4834   ; y la lateral sale de 0x490D, dos bytes por rutina
	push hl			;4837
	ex de,hl			;4838
	call LEE_PUNTERO		;4839
	ld a,(0e1b0h)		;483c
	cp 008h		;483f   ; el tipo 8 desvia su velocidad lateral...
	jr nz,GUARDA_VELOCIDAD		;4841
	ld a,(0e198h)		;4843   ; ...con uno de los ocho valores de 0x4979
	and 007h		;4846
	add a,a			;4848
	ld hl,04979h		;4849
	call SUMA_A_HL		;484c
	ld c,(hl)			;484f
	inc hl			;4850
	ld h,(hl)			;4851
	ld l,c			;4852
	add hl,de			;4853   ; el desvio se suma a la velocidad de la tabla
	ex de,hl			;4854
GUARDA_VELOCIDAD:		; Deja la velocidad de 16 bits en el hueco
	pop hl			;4855
	ld (hl),e			;4856   ; bytes +6 y +7: la velocidad de columna
	inc hl			;4857
	ld (hl),d			;4858
	inc hl			;4859
	inc hl			;485a
	ld a,(0e1b0h)		;485b   ; el tipo 5 entra siempre por arriba
	cp 005h		;485e
	jr z,ENEMIGO_FILA		;4860
	ld a,(0e140h)		;4862   ; con el gigante delante, los demas entran por donde el diga
	cp 002h		;4865
	jr z,ENEMIGO_EN_GIGANTE		;4867
ENEMIGO_FILA:		; El tipo 12 entra por 0xE0 y los demas por 0xF0
	ld a,(0e1b0h)		;4869   ; el tipo 12 entra por la fila 0xE0...
	cp 00ch		;486c
	ld a,0e0h		;486e
	jr z,GUARDA_FILA		;4870
	ld a,0f0h		;4872   ; ...y los demas por la 0xF0, o sea por debajo del borde
GUARDA_FILA:		; Deja la fila de entrada
	ld (hl),a			;4874   ; byte +9: la parte entera de la fila
	inc hl			;4875
	inc hl			;4876
	ld a,(0e19ah)		;4877   ; la columna de entrada sale de 0x4931
	ld c,a			;487a
	ld a,(0e198h)		;487b   ; los tres bits bajos del contador reparten a los cinco de la tanda
	and 007h		;487e
	add a,c			;4880
	ld de,04931h		;4881
	call SUMA_A_DE		;4884
	ld a,(de)			;4887
	ld (hl),a			;4888   ; byte +11: la parte entera de la columna
COLA_DEL_HUECO:		; Copia los cuatro bytes de cola de la plantilla
	inc hl			;4889
	ld a,(0e1b0h)		;488a   ; los tipos 13 en adelante comparten plantilla con los del 1 al 3
	ld de,04945h		;488d
	cp 00dh		;4890
	jr c,COPIA_PLANTILLA		;4892
	sub 00ch		;4894
COPIA_PLANTILLA:		; Los cuatro bytes de 0x4945, indexados por el tipo
	add a,a			;4896   ; cuatro bytes por tipo
	add a,a			;4897
	call SUMA_A_DE		;4898
	ex de,hl			;489b
	ld bc,00004h		;489c   ; bytes +12 a +15: dos parejas de patron y color
	ldir		;489f
	ld hl,0e194h		;48a1   ; un objeto vivo mas
	inc (hl)			;48a4
	ld a,(0e199h)		;48a5   ; las rutinas 0 a 4 hacen ruido al aparecer, menos la 2
	cp 005h		;48a8
	ret nc			;48aa
	cp 002h		;48ab
	ret z			;48ad
	ld a,002h		;48ae   ; 0x02 es el zumbido del enemigo que entra
	call PIDE_SONIDO		;48b0
	ld a,(0e140h)		;48b3   ; con el gigante delante...
	cp 002h		;48b6
	ret nz			;48b8
	ld hl,(0e310h)		;48b9   ; ...la rutina se cambia por su pareja: 0 por 3 y 1 por 2
	inc l			;48bc
	ld a,(hl)			;48bd
	xor 003h		;48be
	ld (hl),a			;48c0
	ret			;48c1
ENEMIGO_EN_GIGANTE:		; Con el gigante en pantalla, patrones fijos 0x1C y 0x5C
	ld (hl),01ch		;48c2   ; con el gigante en pantalla los enemigos entran por la fila 0x1C...
	inc l			;48c4
	inc l			;48c5
	ld (hl),05ch		;48c6   ; ...y por la columna 0x5C, o sea desde el propio bicho
SALTO_A_COLA:		; Los dos bytes del jr que son tambien la base de 0x48CA
	jr COLA_DEL_HUECO		;48c8   ; estos dos bytes son a la vez el jr y la base de la tabla de 0x48CA

; ----------------------------------------------------------------------
; DATOS tabla_rutina_por_tipo: De que rutina de objeto (0 a 0x12, la de la
;   tabla 0x535F) es cada tipo de enemigo. Base 0x48C8, dos bytes antes de los
;   datos; el indice es 2*tipo mas el bit 0 del contador de aparicion, o sea
;   que un mismo tipo alterna entre dos rutinas
;   0x48ca..0x48e8  (30 bytes)
DATA_tabla_rutina_por_tipo:
	defb 000h,001h,002h,002h,003h,004h,005h,006h,007h,007h,008h,009h,00ah,00bh,00ch	; 48ca  ...............
	defb 00dh,00eh,00fh,010h,010h,011h,011h,012h,012h,000h,001h,002h,002h,003h,004h	; 48d9  ...............

; ----------------------------------------------------------------------
; DATOS tabla_base_columna: Base del indice de columna de entrada (va a
;   0xE19A) de cada rutina de objeto; 0x4877 le suma los tres bits bajos del
;   contador de aparicion para indexar 0x4931
;   0x48e8..0x48fb  (19 bytes)
DATA_tabla_base_columna:
	defb 000h,000h,000h,000h,000h,008h,008h,000h,008h,008h,008h,008h,000h,000h,000h,000h,010h,000h,010h	; 48e8  ...................

; ----------------------------------------------------------------------
; DATOS tabla_velocidad_fila: Velocidad con la que baja cada rutina de objeto;
;   el byte se multiplica por CUATRO y va a los bytes 4 y 5 del hueco
;   0x48fb..0x490d  (18 bytes)
DATA_tabla_velocidad_fila:
	defb 060h,060h,040h,060h,060h,03bh,03bh,01ch,028h,028h,028h,028h,038h,038h,01ch,01ch,040h,040h	; 48fb  ``@``;;.((((88..@@

; ----------------------------------------------------------------------
; DATOS tabla_velocidad_columna: Velocidad lateral de 16 bits de cada rutina
;   de objeto; va a los bytes 6 y 7 del hueco
;   0x490d..0x4931  (36 bytes)
DATA_tabla_velocidad_columna:
	defw 00000h,00000h	; 490d
	defw 00000h,00060h	; 4911
	defw 0ffa0h,00061h	; 4915
	defw 0ffa0h,00000h	; 4919
	defw 00090h,0ff70h	; 491d
	defw 00000h,00000h	; 4921
	defw 00000h,00000h	; 4925
	defw 00000h,00000h	; 4929
	defw 00000h,00000h	; 492d

; ----------------------------------------------------------------------
; DATOS tabla_columna_de_entrada: Columna por la que entra el enemigo (va al
;   byte +11 del hueco), indexada por 0xE19A mas los tres bits bajos del
;   contador de aparicion
;   0x4931..0x4945  (20 bytes)
DATA_tabla_columna_de_entrada:
	defb 010h,0aah,03ch,068h,026h,07eh,052h,094h,010h,0aah,010h,0aah,010h,0aah,010h,0aah,010h,052h,03ch,068h	; 4931  ..<h&~R..........R<h

; ----------------------------------------------------------------------
; DATOS plantillas_enemigo: Los cuatro bytes de cola del hueco, por tipo
;   (indice 4*tipo)
;   0x4945..0x4975  (48 bytes)
DATA_plantillas_enemigo:
	defb 010h,026h,058h,068h	; 4945
	defb 010h,001h,014h,00fh	; 4949
	defb 010h,001h,014h,00fh	; 494d
	defb 010h,001h,014h,00fh	; 4951
	defb 030h,00fh,034h,001h	; 4955
	defb 050h,00fh,054h,001h	; 4959
	defb 058h,00fh,05ch,00fh	; 495d
	defb 068h,001h,000h,000h	; 4961
	defb 06ch,003h,070h,00fh	; 4965
	defb 07ch,001h,080h,00fh	; 4969
	defb 084h,00fh,0b8h,00fh	; 496d
	defb 08ch,00bh,090h,00bh	; 4971

; ----------------------------------------------------------------------
; DATOS tabla_variante_tipo9: Los cuatro patrones que alterna el enemigo de
;   tipo 9
;   0x4975..0x4979  (4 bytes)
DATA_tabla_variante_tipo9:
	defb 020h,018h,028h,010h	; 4975

; ----------------------------------------------------------------------
; DATOS tabla_desvio_tipo8: Ocho desvios de 16 bits que el enemigo de tipo 8
;   suma a su velocidad lateral, segun los tres bits bajos del contador de
;   aparicion
;   0x4979..0x4989  (16 bytes)
DATA_tabla_desvio_tipo8:
	defw 000c0h,0ff40h	; 4979
	defw 00060h,00000h	; 497d
	defw 00090h,0ffa0h	; 4981
	defw 00000h,0ff70h	; 4985

; ======================================================================
; CODIGO 0x4989..0x4b00  (375 bytes)
; ======================================================================


MARCA_MUERTO:		; Libera el disparo fijo que este hueco tenia colgado en 0xE290
	push hl			;4989   ; del hueco saca SU hueco de disparo: 0xE290 mas 16 por hueco, o sea el disparo n+2
	ld a,l			;498a
	and 0f0h		;498b
	add a,090h		;498d
	ld l,a			;498f
	ld a,(hl)			;4990   ; solo lo libera si era uno de los fijos (0xFF)
	inc a			;4991
	jr nz,FIN_MARCA_MUERTO		;4992
	ld (hl),a			;4994
FIN_MARCA_MUERTO:		; Devuelve HL y sale
	pop hl			;4995
	ret			;4996
QUITA_OBJETO:		; Apaga el hueco y pasa al siguiente
	call APAGA_HUECO		;4997   ; apaga el hueco y a por el siguiente
	jr OBJETO_SIGUIENTE		;499a
PASO_OBJETOS:		; Recorre los siete huecos y mueve cada objeto
	ld hl,0e200h		;499c   ; los siete huecos, de 0xE200 en adelante
	ld b,007h		;499f
OBJETO_PASO:		; Suma la velocidad de 16 bits a la posicion del objeto
	push bc			;49a1
	ld a,(hl)			;49a2   ; hueco vacio, nada que mover
	and a			;49a3
	ld (0e310h),hl		;49a4   ; 0xE310 apunta al hueco para las rutinas que vienen detras
	jr z,OBJETO_SIGUIENTE		;49a7
	inc hl			;49a9
	ld a,(hl)			;49aa
	cp 013h		;49ab   ; la rutina 0x13 se mueve sola: aqui no se le toca
	jr z,OBJETO_SIGUIENTE		;49ad
	inc hl			;49af   ; HL a los bytes +4/+5 (velocidad) y DE a los +8/+9 (fila)
	inc hl			;49b0
	inc hl			;49b1
	ld e,l			;49b2
	ld d,h			;49b3
	inc de			;49b4
	inc de			;49b5
	inc de			;49b6
	inc de			;49b7
	ld a,(de)			;49b8
	add a,(hl)			;49b9   ; la fila es de 16 bits: primero la parte de abajo...
	ld (de),a			;49ba
	inc hl			;49bb
	inc de			;49bc
	ld a,(de)			;49bd
	adc a,(hl)			;49be   ; ...y luego la de arriba, con el acarreo
	cp 0c0h		;49bf   ; de 0xC0 a 0xCF el objeto se ha ido por debajo: fuera
	jr c,OBJETO_GUARDA_FILA		;49c1
	cp 0d0h		;49c3   ; de 0xD0 en adelante es que aun esta entrando por abajo
	jr c,QUITA_OBJETO		;49c5
OBJETO_GUARDA_FILA:		; La fila cabe: guarda y sigue con la columna
	ld (de),a			;49c7   ; byte +9 nuevo
	inc hl			;49c8
	inc de			;49c9
	ld a,(de)			;49ca
	add a,(hl)			;49cb   ; y lo mismo con la columna, bytes +10 y +11
	ld (de),a			;49cc
	inc hl			;49cd
	inc de			;49ce
	ld a,(de)			;49cf
	adc a,(hl)			;49d0
	cp 0b0h		;49d1   ; pasada la columna 0xB0 se ha salido por un lado
	jr nc,QUITA_OBJETO		;49d3
	ld (de),a			;49d5
OBJETO_SIGUIENTE:		; Salta al hueco siguiente, 16 bytes mas alla
	ld hl,(0e310h)		;49d6
	ld de,00010h		;49d9   ; 16 bytes por hueco
	add hl,de			;49dc
	pop bc			;49dd
	djnz OBJETO_PASO		;49de
	ld b,007h		;49e0
	exx			;49e2
	ld de,0e0d4h		;49e3   ; los objetos usan las fichas de sprite de la 9 en adelante (0xE0D4)
	ld hl,0e200h		;49e6
	exx			;49e9
OBJETO_A_SPRITES:		; Vuelca cada hueco a sus dos fichas de sprite
	exx			;49ea
	ld (0e310h),hl		;49eb
	ld (0e312h),de		;49ee
	ld a,(hl)			;49f2   ; hueco vacio, ficha sin tocar
	and a			;49f3
	jp z,OBJETO_A_SPRITES_FIN		;49f4
	cp 006h		;49f7   ; el tipo 6 mide el doble de ancho
	jp z,TIPO_6_A_SPRITES		;49f9
	inc hl			;49fc
	ld a,(hl)			;49fd
	cp 013h		;49fe   ; la rutina 0x13 lleva dos piezas sueltas
	jp z,TIPO_13_A_SPRITES		;4a00
	cp 010h		;4a03   ; y la 0x10 arrastra un rastro
	jp z,TIPO_10_A_SPRITES		;4a05
	ld a,008h		;4a08   ; de +1 a +9: la fila
	add a,l			;4a0a
	ld l,a			;4a0b
	ld a,(hl)			;4a0c
	ld (de),a			;4a0d
	ex af,af'			;4a0e   ; la fila hace falta otra vez para la segunda ficha
	inc hl			;4a0f
	inc hl			;4a10
	inc de			;4a11
	ld c,(hl)			;4a12   ; +11 es la columna
	ex de,hl			;4a13
	ld (hl),c			;4a14
	ex de,hl			;4a15
	inc de			;4a16
	inc hl			;4a17
	ld a,(hl)			;4a18   ; +12 y +13: patron y color de la primera ficha
	ld (de),a			;4a19
	inc hl			;4a1a
	inc de			;4a1b
	ld a,(hl)			;4a1c
	ld (de),a			;4a1d
	inc de			;4a1e
	ex af,af'			;4a1f   ; la segunda ficha va en la misma fila...
	ld (de),a			;4a20
	inc de			;4a21
	ex de,hl			;4a22
	ld (hl),c			;4a23   ; ...y en la misma columna: dos sprites superpuestos para tener dos colores
	ex de,hl			;4a24
	inc de			;4a25
	inc hl			;4a26
	ld a,(hl)			;4a27   ; +14 y +15: patron y color de la segunda
	ld (de),a			;4a28
	inc hl			;4a29
	inc de			;4a2a
	ld a,(hl)			;4a2b
	ld (de),a			;4a2c
OBJETO_A_SPRITES_FIN:		; Avanza al hueco y a la ficha siguientes
	ld hl,(0e310h)		;4a2d
	ld de,(0e312h)		;4a30
	ld a,010h		;4a34   ; 16 bytes al hueco siguiente...
	add a,l			;4a36
	ld l,a			;4a37
	ld a,008h		;4a38   ; ...y ocho bytes (dos fichas) a la ficha siguiente
	call SUMA_A_DE		;4a3a
	exx			;4a3d
	djnz OBJETO_A_SPRITES		;4a3e
	ret			;4a40
TIPO_13_SIN_PARTE:		; La primera pieza no esta: salta a la segunda
	inc de			;4a41   ; sin primera pieza, deja sus dos fichas a cero y salta
	inc de			;4a42
	inc de			;4a43
	inc de			;4a44
	ld a,009h		;4a45
	add a,l			;4a47
	ld l,a			;4a48
	jr TIPO_13_SEGUNDA		;4a49
TIPO_13_A_SPRITES:		; Volcado del tipo 0x13, que lleva dos piezas sueltas
	inc l			;4a4b   ; +2 a cero: la primera pieza ya no esta
	ld a,(hl)			;4a4c
	and a			;4a4d
	jr z,TIPO_13_SIN_PARTE		;4a4e
	inc l			;4a50
	ld a,(hl)			;4a51
	ld (de),a			;4a52   ; fila de la primera pieza
	inc l			;4a53   ; de +3 a +7: la columna de la primera pieza
	inc l			;4a54
	inc l			;4a55
	inc l			;4a56
	inc de			;4a57
	ld a,(hl)			;4a58   ; columna a la ficha
	ld (de),a			;4a59
	inc l			;4a5a
	inc de			;4a5b
	ld a,(hl)			;4a5c   ; +8: el patron
	ld (de),a			;4a5d
	inc l			;4a5e
	inc de			;4a5f
	ld a,(hl)			;4a60   ; +9: el color
	ld (de),a			;4a61
	inc l			;4a62   ; y de +9 a +11, donde empieza la segunda pieza
	inc l			;4a63
	inc de			;4a64
TIPO_13_SEGUNDA:		; La segunda pieza del tipo 0x13
	ld a,(hl)			;4a65   ; +12 a cero: la segunda pieza tampoco esta
	and a			;4a66
	jp z,OBJETO_A_SPRITES_FIN		;4a67
	inc l			;4a6a
	ld a,(hl)			;4a6b   ; +12: la fila de la segunda pieza
	ld (de),a			;4a6c
	inc l			;4a6d
	inc de			;4a6e
	ld a,(hl)			;4a6f   ; +13: su columna
	ld (de),a			;4a70
	inc l			;4a71
	inc de			;4a72
	ld a,(hl)			;4a73   ; +14: su patron
	ld (de),a			;4a74
	inc l			;4a75
	inc de			;4a76
	ld a,(hl)			;4a77   ; +15: su color
	ld (de),a			;4a78
	jp OBJETO_A_SPRITES_FIN		;4a79
TIPO_10_A_SPRITES:		; Volcado de la rutina 0x10, que ademas cuelga un disparo fijo
	inc l			;4a7c   ; +2 es el estado, y decide si ademas deja rastro
	ld a,(hl)			;4a7d
	push af			;4a7e
	ld a,007h		;4a7f   ; de +2 a +9: la fila
	add a,l			;4a81
	ld l,a			;4a82
	ld c,(hl)			;4a83   ; C se queda la fila y B la columna
	inc hl			;4a84
	inc hl			;4a85
	ld b,(hl)			;4a86
	inc hl			;4a87
	ex de,hl			;4a88
	ld (hl),c			;4a89
	inc hl			;4a8a
	ld (hl),b			;4a8b
	inc hl			;4a8c
	ld a,(de)			;4a8d
	ld (hl),a			;4a8e
	inc de			;4a8f
	inc hl			;4a90
	ld a,(de)			;4a91
	ld (hl),a			;4a92
	inc de			;4a93
	inc hl			;4a94
	ld (hl),c			;4a95   ; la segunda ficha va en la misma fila...
	inc hl			;4a96
	ld a,b			;4a97
	add a,040h		;4a98   ; ...y 0x40 pixeles a la derecha: el objeto mide cuatro sprites de ancho
	ld (hl),a			;4a9a
	inc hl			;4a9b
	ld a,(de)			;4a9c
	ld (hl),a			;4a9d
	inc de			;4a9e
	inc hl			;4a9f
	ld a,(de)			;4aa0
	ld (hl),a			;4aa1
	pop af			;4aa2
	and 003h		;4aa3   ; solo con el estado en 3 cuelga el disparo fijo
	cp 003h		;4aa5
	jp nz,OBJETO_A_SPRITES_FIN		;4aa7
	ld a,(0e310h)		;4aaa   ; el rastro no es un adorno: es un DISPARO ENEMIGO mas, montado a mano
	and 0f0h		;4aad
	ld hl,0e290h		;4aaf
	add a,l			;4ab2
	ld l,a			;4ab3
	ld (hl),0ffh		;4ab4   ; tipo 0xFF: un disparo que no se mueve solo, esta rutina lo recoloca cada fotograma
	ld de,00006h		;4ab6   ; byte +6 del disparo: la fila
	add hl,de			;4ab9
	ld (hl),c			;4aba
	inc hl			;4abb
	inc hl			;4abc
	ld a,(0e003h)		;4abd   ; los cuatro bits bajos del contador de fotogramas, por ocho: 0 a 0x78
	and 00fh		;4ac0
	add a,a			;4ac2
	add a,a			;4ac3
	add a,a			;4ac4
	cp 040h		;4ac5   ; pasado 0x40 la cuenta vuelve hacia atras
	jr c,RASTRO_COLUMNA		;4ac7
	sub 080h		;4ac9
	neg		;4acb
RASTRO_COLUMNA:		; Un vaiven de 0x40 pixeles para la columna del rastro
	add a,b			;4acd   ; asi la columna del disparo va y viene 0x40 pixeles alrededor del objeto
	ld (hl),a			;4ace
	inc hl			;4acf
	ld (hl),088h		;4ad0   ; patron 0x88 y color 15, los del disparo enemigo
	inc hl			;4ad2
	ld (hl),00fh		;4ad3
	jp OBJETO_A_SPRITES_FIN		;4ad5
TIPO_6_A_SPRITES:		; Volcado del tipo 6, con la segunda ficha 16 pixeles a la derecha
	ld a,009h		;4ad8   ; de +1 a +9: la fila
	add a,l			;4ada
	ld l,a			;4adb
	ld a,(hl)			;4adc
	ld c,a			;4add   ; C se queda la fila y B la columna
	ld (de),a			;4ade
	inc hl			;4adf
	inc hl			;4ae0
	inc de			;4ae1
	ld a,(hl)			;4ae2
	ld b,a			;4ae3
	ld (de),a			;4ae4
	inc hl			;4ae5
	inc de			;4ae6
	ld a,(hl)			;4ae7   ; +12 y +13: patron y color de la primera ficha
	ld (de),a			;4ae8
	inc hl			;4ae9
	inc de			;4aea
	ld a,(hl)			;4aeb
	ld (de),a			;4aec
	inc hl			;4aed
	inc de			;4aee
	ex de,hl			;4aef
	ld (hl),c			;4af0   ; la segunda ficha comparte fila...
	inc hl			;4af1
	ld a,010h		;4af2   ; ...y va 16 pixeles a la derecha: el tipo 6 mide dos sprites de ancho
	add a,b			;4af4
	ld (hl),a			;4af5
	inc hl			;4af6
	ld a,(de)			;4af7   ; +14 y +15: patron y color de la segunda
	ld (hl),a			;4af8
	inc de			;4af9
	inc hl			;4afa
	ld a,(de)			;4afb
	ld (hl),a			;4afc
	jp OBJETO_A_SPRITES_FIN		;4afd

; ----------------------------------------------------------------------
; DATOS guion_panel: Guion de la tabla de nombres: HI, SCENE, SCORE y REST
;   0x4b00..0x4b1c  (28 bytes)
DATA_guion_panel:
	defb 099h,038h,028h,029h,0feh,019h,03ah,033h,023h,025h,02eh,025h,0feh,039h,038h,033h	; 4b00  .8()..:3#%.%.983
	defb 023h,02fh,032h,025h,0feh,019h,039h,032h,025h,033h,034h,0ffh	; 4b10  #/2%..92%34.

; ----------------------------------------------------------------------
; DATOS guion_pulsa_espacio: Guion de la tabla de nombres: PUSH SPACE KEY
;   0x4b1c..0x4b2f  (19 bytes)
DATA_guion_pulsa_espacio:
	defb 029h,03ah,030h,035h,033h,028h,000h,033h,030h,021h,023h,025h,000h,02bh,025h,039h	; 4b1c  ):053(.30!#%.+%9
	defb 0feh,04ah,039h	; 4b2c

; ----------------------------------------------------------------------
; DATOS rotulo_konami: (c) KONAMI y 1984. Sirve dos veces: es el segundo
;   bloque del guion de 0x4B1C y es lo que 0x42BC copia al panel con dos
;   LDIRVM
;   0x4b2f..0x4b3c  (13 bytes)
DATA_rotulo_konami:
	defb 01ah,02bh,02fh,02eh,021h,02dh,029h,000h,011h,019h,018h,014h,0ffh	; 4b2f  .+/.!-)......

; ----------------------------------------------------------------------
; DATOS guion_game_over: Guion de la tabla de nombres: GAME  OVER
;   0x4b3c..0x4b49  (13 bytes)
DATA_guion_game_over:
	defb 068h,039h,027h,021h,02dh,025h,000h,000h,02fh,036h,025h,032h,0ffh	; 4b3c  h9'!-%../6%2.

; ----------------------------------------------------------------------
; DATOS guion_video_cartridge: Guion de la tabla de nombres: VIDEO CARTRIDGE
;   entre dos adornos
;   0x4b49..0x4b5f  (22 bytes)
DATA_guion_video_cartridge:
	defb 066h,039h,020h,000h,036h,029h,024h,025h,02fh,000h,023h,021h,032h,034h,032h,029h	; 4b49  f9 .6)$%/.#!242)
	defb 024h,027h,025h,000h,020h,0ffh	; 4b59

; ----------------------------------------------------------------------
; DATOS guion_del_demo: Los mandos que se inventa 0x449E en el demo: un paso
;   cada 32 fotogramas, y 0xFF vuelve al principio
;   0x4b5f..0x4b71  (18 bytes)
DATA_guion_del_demo:
	defb 004h,005h,008h,008h,00ah,008h,001h,004h,006h,006h,005h,009h,008h,00ah,002h,004h,0ffh,0ffh	; 4b5f  ..................

; ======================================================================
; CODIGO 0x4b71..0x4bab  (58 bytes)
; ======================================================================


COLOR_LISOS:		; Da a los caracteres 0x00-0x0F un color entero cada uno
	ld hl,00000h		;4b71   ; el tercio de arriba...
	call COLOR_DIECISEIS		;4b74
	ld hl,00800h		;4b77   ; ...el de en medio...
	call COLOR_DIECISEIS		;4b7a
	ld hl,01000h		;4b7d   ; ...y el de abajo, que llevan lo mismo
	call COLOR_DIECISEIS		;4b80
	jp CARGA_FUENTE		;4b83   ; y ya puestos, la fuente del panel
COLOR_DIECISEIS:		; Dieciseis pares de color, ocho bytes cada uno
	xor a			;4b86   ; el color arranca en 0x00, negro sobre negro
	ld c,010h		;4b87   ; los dieciseis caracteres lisos, del 0x00 al 0x0F
COLOR_UN_CARACTER:		; Ocho bytes con el mismo par de color
	ld b,008h		;4b89   ; ocho bytes de color por caracter, uno por fila
COLOR_UN_BYTE:		; Un byte de la tabla de color
	call 0004dh		;4b8b   ; BIOS WRTVRM - Writes data in VRAM
	inc hl			;4b8e
	djnz COLOR_UN_BYTE		;4b8f
	add a,011h		;4b91   ; 0x11 sube a la vez el tinte y el fondo: 0x00, 0x11, 0x22... el caracter queda de un solo color
	dec c			;4b93
	jr nz,COLOR_UN_CARACTER		;4b94
	ret			;4b96
CARGA_FUENTE:		; Descomprime la fuente en 0x2080 y le pone color
	ld de,04babh		;4b97   ; el guion de la fuente
	ld hl,02080h		;4b9a   ; los patrones van a 0x2080, o sea al caracter 0x10
	call DESC_TRES		;4b9d
	ld hl,00080h		;4ba0   ; la fuente entera en blanco sobre negro
	ld a,0f0h		;4ba3
	ld bc,00250h		;4ba5   ; 0x250 bytes son los 74 caracteres
	jp RELLENA_TRES		;4ba8

; ----------------------------------------------------------------------
; DATOS patrones_fuente: Guion comprimido: 592 bytes (74 caracteres, del 0x10
;   al 0x59) a 0x2080 en los tres tercios
;   0x4bab..0x4d61  (438 bytes)
DATA_patrones_fuente:
	defb 08bh,000h,01ch,022h,063h,063h,063h,022h,01ch,000h,018h,038h,004h,018h,0c9h,07eh	; 4bab  ..."ccc"...8...~
	defb 000h,03eh,063h,003h,00eh,03ch,070h,07fh,000h,03eh,063h,003h,00eh,003h,063h,03eh	; 4bbb  .>c..<p..>c...c>
	defb 000h,00eh,01eh,036h,066h,066h,07fh,006h,000h,07fh,060h,07eh,063h,003h,063h,03eh	; 4bcb  ...6ff....`~c.c>
	defb 000h,03eh,063h,060h,07eh,063h,063h,03eh,000h,07fh,063h,006h,00ch,018h,018h,018h	; 4bdb  .>c`~cc>..c.....
	defb 000h,03eh,063h,063h,03eh,063h,063h,03eh,000h,03eh,063h,063h,03fh,003h,063h,03eh	; 4beb  .>cc>cc>.>cc?.c>
	defb 03ch,042h,099h,0a1h,0a1h,099h,042h,03ch,02bh,000h,001h,07eh,004h,000h,0c2h,000h	; 4bfb  <B....B<+..~....
	defb 01ch,036h,063h,063h,07fh,063h,063h,000h,07eh,063h,063h,07eh,063h,063h,07eh,000h	; 4c0b  .6cc.cc.~cc~cc~.
	defb 03eh,063h,060h,060h,060h,063h,03eh,000h,07ch,066h,063h,063h,063h,066h,07ch,000h	; 4c1b  >c```c>.|fcccf|.
	defb 07fh,060h,060h,07eh,060h,060h,07fh,000h,07fh,060h,060h,07eh,060h,060h,060h,000h	; 4c2b  .``~``...``~```.
	defb 03eh,063h,060h,067h,063h,063h,03fh,000h,063h,063h,063h,07fh,063h,063h,063h,000h	; 4c3b  >c`gcc?.ccc.ccc.
	defb 03ch,005h,018h,083h,03ch,000h,01fh,004h,006h,08bh,066h,03ch,000h,063h,066h,06ch	; 4c4b  <...<.....f<.cfl
	defb 078h,07ch,06eh,067h,000h,006h,060h,093h,07fh,000h,063h,077h,07fh,07fh,06bh,063h	; 4c5b  x|ng..`...cw..kc
	defb 063h,000h,063h,073h,07bh,07fh,06fh,067h,063h,000h,03eh,005h,063h,0a3h,03eh,000h	; 4c6b  c.cs{.ogc.>.c.>.
	defb 07eh,063h,063h,063h,07eh,060h,060h,000h,03eh,063h,063h,063h,06fh,066h,03dh,000h	; 4c7b  ~ccc~``.>cccof=.
	defb 07eh,063h,063h,062h,07ch,066h,063h,000h,03eh,063h,060h,03eh,003h,063h,03eh,000h	; 4c8b  ~ccb|fc.>c`>.c>.
	defb 07eh,006h,018h,001h,000h,006h,063h,082h,03eh,000h,004h,063h,093h,036h,01ch,008h	; 4c9b  ~.....c.>..c.6..
	defb 000h,063h,063h,06bh,06bh,07fh,077h,022h,000h,063h,076h,03ch,01ch,01eh,037h,063h	; 4cab  .cckk.w".cv<..7c
	defb 090h,000h,066h,066h,07eh,03ch,018h,018h,018h,000h,07fh,007h,00eh,01ch,038h,070h	; 4cbb  ..ff~<........8p
	defb 07fh,028h,000h,00eh,000h,082h,007h,00fh,006h,000h,082h,0f8h,0f0h,004h,03eh,004h	; 4ccb  .(............>.
	defb 03fh,08bh,01fh,03fh,07fh,0ffh,0feh,0fch,0f8h,0f0h,0e0h,0c0h,080h,003h,000h,002h	; 4cdb  ?..?............
	defb 03eh,005h,000h,083h,01fh,07fh,0fbh,005h,000h,083h,00fh,0cfh,0efh,005h,000h,083h	; 4ceb  >...............
	defb 078h,0fch,0bch,005h,000h,083h,03fh,07fh,0f3h,005h,000h,083h,087h,0c7h,0c7h,005h	; 4cfb  x.....?.........
	defb 000h,083h,0bch,0feh,0dfh,005h,000h,088h,078h,0fch,0bch,060h,0f0h,0f0h,060h,000h	; 4d0b  ........x..`..`.
	defb 003h,0f0h,002h,03fh,006h,03eh,088h,0f8h,0fch,0feh,07fh,03fh,01fh,00fh,007h,003h	; 4d1b  ...?.>.....?....
	defb 03eh,085h,07eh,0fch,0fch,0f8h,0e0h,005h,0f1h,083h,0fbh,07fh,01fh,006h,0efh,082h	; 4d2b  >.~.............
	defb 0cfh,00fh,008h,01eh,088h,0e1h,003h,03fh,0f1h,0e1h,0f3h,07fh,01eh,007h,0e7h,081h	; 4d3b  .......?........
	defb 0f7h,008h,08fh,008h,01eh,082h,0f1h,0f2h,004h,0f5h,08ah,0f2h,0f1h,0e0h,010h,0c8h	; 4d4b  ................
	defb 068h,0c8h,028h,010h,0e0h,000h	; 4d5b

; ----------------------------------------------------------------------
; DATOS patrones_rotulo: Guion comprimido: 320 bytes (40 caracteres, del 0xC0
;   al 0xE7) a 0x2600 en los tres tercios; son las 52 piezas del rotulo del
;   titulo, que 0x4E82 monta en cuatro filas
;   0x4d61..0x4e82  (289 bytes)
DATA_patrones_rotulo:
	defb 0a9h,00fh,010h,020h,060h,061h,061h,060h,070h,0e7h,014h,004h,004h,086h,0feh,03eh	; 4d61  ... `aa`p......>
	defb 006h,0f7h,018h,018h,010h,000h,000h,001h,000h,0bfh,020h,020h,020h,0f0h,0b0h,0b0h	; 4d71  ..........   ...
	defb 098h,07fh,0c1h,0c1h,0c1h,0c2h,002h,002h,004h,03fh,003h,030h,004h,018h,08bh,087h	; 4d81  .........?.0....
	defb 058h,070h,060h,061h,061h,060h,060h,0e0h,011h,00bh,005h,006h,094h,0ffh,080h,000h	; 4d91  Xp`aa``.........
	defb 000h,018h,01fh,010h,010h,0beh,041h,041h,041h,061h,0e1h,061h,061h,0feh,082h,083h	; 4da1  ......AAAa.aa...
	defb 082h,004h,086h,08ch,07eh,081h,000h,000h,018h,018h,000h,000h,03fh,020h,0a0h,060h	; 4db1  ....~.......? .`
	defb 004h,070h,08bh,0f8h,004h,002h,002h,0c2h,0c2h,004h,008h,01eh,021h,061h,004h,060h	; 4dc1  .p..........!a.`
	defb 08ah,07fh,006h,086h,086h,006h,00ch,01ch,02ch,0efh,000h,006h,018h,084h,0ffh,04ch	; 4dd1  ........,......L
	defb 046h,046h,004h,02ch,084h,0efh,00fh,016h,016h,004h,00eh,0b2h,0ffh,0f8h,018h,018h	; 4de1  FF.,............
	defb 000h,000h,000h,001h,0feh,060h,061h,061h,041h,041h,0c1h,0c1h,0ffh,006h,086h,086h	; 4df1  .....`aaAA......
	defb 086h,087h,083h,081h,0fch,010h,018h,018h,000h,000h,080h,0c0h,0ffh,061h,061h,061h	; 4e01  .............aaa
	defb 060h,060h,070h,038h,01fh,086h,086h,086h,004h,004h,00ch,014h,0e7h,000h,006h,018h	; 4e11  ``p8............
	defb 081h,0efh,003h,070h,004h,020h,08ch,0bfh,004h,0c2h,0c2h,0c3h,0c1h,0c1h,0c1h,0feh	; 4e21  ...p. ..........
	defb 000h,03fh,007h,006h,000h,083h,0ffh,0ffh,000h,0a7h,03fh,007h,000h,000h,000h,0ffh	; 4e31  .?........?.....
	defb 0ffh,000h,0ffh,0ffh,000h,03fh,000h,0ffh,0ffh,000h,0ffh,0ffh,000h,0ffh,000h,0ffh	; 4e41  .....?..........
	defb 0ffh,000h,0ffh,0ffh,000h,0fch,000h,0ffh,0ffh,000h,0fch,0e0h,000h,000h,000h,0fch	; 4e51  ................
	defb 0e0h,005h,000h,081h,007h,007h,000h,084h,0ffh,000h,01fh,003h,004h,000h,084h,0ffh	; 4e61  ................
	defb 000h,0ffh,0ffh,004h,000h,084h,0ffh,000h,0f8h,0c0h,004h,000h,081h,0e0h,007h,000h	; 4e71  ................
	defb 000h	; 4e81

; ----------------------------------------------------------------------
; DATOS guion_rotulo: Guion COMPRIMIDO (el de 0x4396, no el de nombres) que
;   coloca el rotulo del titulo en la tabla de nombres: 14 celdas en la fila 6
;   columna 9, otras 14 en la 7, otras 14 en la 8 y 10 en la fila 9 columna 11
;   0x4e82..0x4ebe  (60 bytes)
DATA_guion_rotulo:
	defb 0c9h,038h,08eh,0c0h,0c1h,0c2h,0c3h,0c4h,0c5h,0c6h,0c7h,0c8h,0c9h,0cah,0cbh,0cch	; 4e82  .8..............
	defb 0cdh,080h,0e9h,038h,08eh,0ceh,0cfh,0d0h,0d1h,0d2h,0d3h,0d4h,0d5h,0d6h,0d7h,0d8h	; 4e92  ...8............
	defb 0d9h,0dah,0dbh,080h,009h,039h,083h,0dch,0ddh,0deh,008h,0dfh,083h,0e0h,0e1h,0e2h	; 4ea2  .....9..........
	defb 080h,02bh,039h,082h,0e3h,0e4h,006h,0e5h,082h,0e6h,0e7h,000h	; 4eb2  .+9.........

; ======================================================================
; CODIGO 0x4ebe..0x4efd  (63 bytes)
; ======================================================================


APAGA_FICHAS:		; Pone las 32 fichas de sprite de 0xE0B0 fuera de la pantalla
	ld hl,0e0b0h		;4ebe   ; 32 fichas de cuatro bytes son 128
	ld b,080h		;4ec1
APAGA_UNA_FICHA:		; Pone 0xE0 en un byte de la copia de atributos
	ld (hl),0e0h		;4ec3   ; 0xE0 en la fila deja la ficha fuera de la pantalla
	inc hl			;4ec5
	djnz APAGA_UNA_FICHA		;4ec6
	ret			;4ec8
SPRITES_A_VRAM:		; Vuelca los atributos: nueve fichas fijas y una tanda que rota
	ld hl,03b00h		;4ec9   ; las nueve primeras fichas (dos del avion, tres de las balas y cuatro del gigante) van siempre delante
	ld de,0e0b0h		;4ecc
	ld bc,00024h		;4ecf   ; 0x24 bytes son nueve fichas
	call A_VRAM		;4ed2
	ld hl,03b24h		;4ed5   ; de la ficha 9 en adelante van los objetos
	call PREPARA_ESCRITURA		;4ed8
	ld a,(0e003h)		;4edb   ; el fotograma elige por donde empieza la tanda: 0, 1, 2 o 3
	and 003h		;4ede
	ld b,a			;4ee0
	add a,a			;4ee1   ; tres bytes por tanda
	add a,b			;4ee2
	ld c,004h		;4ee3   ; cuatro tandas seguidas de la tabla de siete
	ld hl,04efdh		;4ee5
	call SUMA_A_HL		;4ee8
TANDA_DE_SPRITES:		; Coge cuantas fichas y de donde salen
	ld b,(hl)			;4eeb   ; primer byte: cuantos bytes lleva la tanda
	inc hl			;4eec
	ld e,(hl)			;4eed   ; y detras, de donde salen
	inc hl			;4eee
	ld d,(hl)			;4eef
	inc hl			;4ef0
TANDA_BUCLE:		; Vuelca los bytes de la tanda al puerto del VDP
	ld a,(de)			;4ef1   ; los bytes van derechos al puerto del VDP
	inc de			;4ef2
	exx			;4ef3
	out (c),a		;4ef4
	exx			;4ef6
	djnz TANDA_BUCLE		;4ef7
	dec c			;4ef9   ; cuatro tandas y fuera
	jr nz,TANDA_DE_SPRITES		;4efa
	ret			;4efc

; ----------------------------------------------------------------------
; DATOS tabla_tandas_sprites: Siete tandas de cuantas fichas y de donde salen,
;   que 0x4EC9 alterna segun el fotograma
;   0x4efd..0x4f12  (21 bytes)
DATA_tabla_tandas_sprites:
	defb 018h,0d4h,0e0h	; 4efd
	defb 018h,0ech,0e0h	; 4f00
	defb 018h,004h,0e1h	; 4f03
	defb 014h,01ch,0e1h	; 4f06
	defb 018h,0d4h,0e0h	; 4f09
	defb 018h,0ech,0e0h	; 4f0c
	defb 018h,004h,0e1h	; 4f0f

; ======================================================================
; CODIGO 0x4f12..0x4f1b  (9 bytes)
; ======================================================================


CARGA_SPRITES:		; Descomprime los patrones de sprite en 0x1800
	ld hl,01800h		;4f12   ; este ld hl es CODIGO MUERTO: DESC_VRAM lee el destino del propio guion, cuyos dos primeros bytes son 00 18
	ld de,04f1bh		;4f15   ; el guion de los 48 sprites
	jp DESC_VRAM		;4f18

; ----------------------------------------------------------------------
; DATOS patrones_sprites: Guion comprimido: 1536 bytes a 0x1800, o sea 192
;   patrones de 8x8, que en 16x16 son 48 sprites
;   0x4f1b..0x5334  (1049 bytes)
DATA_patrones_sprites:
	defb 000h,018h,002h,001h,003h,000h,002h,001h,08bh,004h,00ch,01ch,03ch,07dh,07dh,06dh	; 4f1b  ............<}}m
	defb 001h,001h,080h,080h,003h,000h,002h,080h,089h,020h,030h,038h,03ch,0beh,0beh,0b6h	; 4f2b  ......... 08<...
	defb 080h,080h,003h,001h,003h,003h,084h,017h,01fh,0dfh,0bfh,004h,0ffh,082h,003h,001h	; 4f3b  ................
	defb 003h,080h,003h,0c0h,084h,0e8h,0f8h,0f9h,0fdh,004h,0ffh,084h,0c0h,080h,001h,001h	; 4f4b  ................
	defb 00eh,000h,002h,080h,00eh,000h,002h,00ch,00eh,000h,002h,030h,00eh,000h,002h,001h	; 4f5b  ...........0....
	defb 081h,005h,004h,065h,002h,044h,084h,004h,006h,002h,002h,005h,000h,081h,040h,004h	; 4f6b  ...e.D........@.
	defb 04ch,002h,044h,084h,040h,0c0h,080h,080h,003h,000h,083h,001h,003h,003h,005h,01fh	; 4f7b  L.D.@...........
	defb 003h,00fh,081h,007h,004h,001h,083h,000h,080h,080h,005h,0f0h,003h,0e0h,081h,0c0h	; 4f8b  ................
	defb 006h,000h,08dh,01fh,01eh,000h,000h,03fh,000h,0feh,000h,03fh,000h,000h,01eh,01fh	; 4f9b  .......?...?....
	defb 003h,000h,081h,080h,003h,000h,085h,0e0h,038h,000h,038h,0e0h,003h,000h,081h,080h	; 4fab  ........8.8.....
	defb 005h,000h,003h,01fh,003h,07fh,003h,01fh,008h,000h,087h,0e0h,0f0h,0f0h,0ffh,0f0h	; 4fbb  ................
	defb 0f0h,0e0h,007h,000h,002h,001h,084h,003h,002h,022h,022h,004h,032h,081h,002h,005h	; 4fcb  ........."".2...
	defb 000h,002h,040h,084h,050h,020h,022h,022h,004h,0a5h,083h,0a0h,080h,080h,004h,000h	; 4fdb  ..@.P ""........
	defb 081h,002h,003h,007h,005h,00fh,002h,001h,081h,000h,004h,080h,081h,0a0h,003h,0f0h	; 4feb  ................
	defb 005h,0f8h,002h,0c0h,002h,000h,081h,001h,003h,000h,085h,007h,01ch,000h,01ch,007h	; 4ffb  ................
	defb 003h,000h,081h,001h,003h,000h,08dh,0f8h,078h,000h,000h,0fch,000h,07fh,000h,0fch	; 500b  ........x.......
	defb 000h,000h,078h,0f8h,006h,000h,087h,007h,00fh,00fh,0ffh,00fh,00fh,007h,008h,000h	; 501b  ..x.............
	defb 003h,0f8h,003h,0feh,003h,0f8h,005h,000h,002h,001h,00ah,000h,002h,001h,002h,000h	; 502b  ................
	defb 002h,080h,00ah,000h,002h,080h,086h,000h,003h,006h,006h,007h,003h,006h,001h,08ah	; 503b  ................
	defb 003h,007h,006h,006h,003h,0c0h,060h,060h,0e0h,0c0h,006h,080h,085h,0c0h,0e0h,060h	; 504b  ......``.......`
	defb 060h,0c0h,003h,000h,082h,018h,010h,017h,000h,082h,004h,00ch,004h,000h,087h,01ch	; 505b  `...............
	defb 026h,02eh,03eh,01dh,003h,008h,00eh,000h,088h,080h,0c0h,0e0h,05ch,03eh,03ah,032h	; 506b  &.>.........\>:2
	defb 01ch,008h,000h,002h,060h,00eh,000h,002h,006h,00ch,000h,086h,070h,0f8h,09fh,09fh	; 507b  ....`.......p...
	defb 0f8h,070h,00ah,000h,086h,00eh,01fh,0f9h,0f9h,01fh,00eh,011h,000h,082h,020h,030h	; 508b  .p............ 0
	defb 005h,000h,082h,018h,008h,012h,000h,088h,001h,003h,007h,03ah,07ch,05ch,04ch,038h	; 509b  ...........:|\L8
	defb 003h,000h,087h,038h,064h,074h,07ch,0b8h,0c0h,080h,00dh,000h,084h,002h,001h,001h	; 50ab  ...8dt|.........
	defb 002h,00ch,000h,084h,040h,080h,080h,040h,00ah,000h,088h,009h,007h,005h,00eh,00eh	; 50bb  ....@..@........
	defb 005h,007h,009h,008h,000h,088h,090h,0e0h,0a0h,070h,070h,0a0h,0e0h,090h,004h,000h	; 50cb  .........pp.....
	defb 088h,080h,0bch,0b7h,0b6h,0b6h,0f2h,01ch,003h,009h,000h,083h,003h,0c3h,0fbh,003h	; 50db  ................
	defb 0dbh,086h,01bh,0c3h,07bh,00bh,003h,003h,003h,001h,084h,000h,0c0h,0c3h,0dfh,003h	; 50eb  ....{...........
	defb 0dbh,086h,0d8h,0c3h,0deh,0d0h,0c0h,0c0h,003h,080h,089h,001h,03dh,0edh,06dh,06dh	; 50fb  ............=.mm
	defb 061h,04fh,038h,0c0h,00ch,000h,082h,003h,01eh,003h,0b6h,084h,0b0h,087h,0fch,0c0h	; 510b  aO8.............
	defb 003h,000h,002h,003h,082h,00bh,07bh,003h,0dbh,085h,0c3h,01bh,0fbh,0c3h,003h,003h	; 511b  ......{.........
	defb 001h,085h,000h,0c0h,0c0h,0d0h,0deh,003h,0dbh,085h,0c3h,0d8h,0dfh,0c3h,0c0h,003h	; 512b  ................
	defb 080h,005h,000h,082h,0c0h,078h,003h,06dh,0b1h,00dh,0e1h,03fh,003h,000h,000h,046h	; 513b  .....x.m...?...F
	defb 067h,078h,05eh,05eh,062h,062h,05eh,05eh,062h,062h,036h,01ah,00fh,006h,003h,0c4h	; 514b  gx^^bb^^bb6.....
	defb 0cch,03ch,0f4h,0f4h,08ch,08ch,0d8h,0f4h,08ch,08ch,0d8h,0b0h,0e0h,0c0h,080h,000h	; 515b  .<..............
	defb 000h,020h,033h,03dh,021h,001h,00dh,01dh,00dh,005h,004h,001h,003h,000h,089h,004h	; 516b  . 3=!...........
	defb 0cch,09ch,084h,080h,0b0h,0b8h,0b0h,0a0h,004h,080h,004h,000h,002h,007h,005h,03fh	; 517b  ...............?
	defb 002h,01fh,082h,00fh,003h,005h,000h,081h,020h,006h,0fch,002h,0f8h,082h,0f0h,0c0h	; 518b  ........ .......
	defb 008h,000h,004h,003h,081h,001h,00ah,000h,081h,080h,004h,0c0h,081h,080h,006h,000h	; 519b  ................
	defb 09eh,00ch,01ch,034h,064h,04ch,0fch,0ech,0ech,0fch,04ch,064h,034h,01ch,00ch,000h	; 51ab  ...4dL....Ld4...
	defb 000h,030h,038h,02ch,026h,032h,03fh,037h,037h,03fh,032h,026h,02ch,038h,030h,006h	; 51bb  .08,&2?77?2&,80.
	defb 000h,006h,001h,016h,000h,09eh,006h,00eh,01ah,032h,026h,06eh,07ah,07ah,06eh,026h	; 51cb  .........2&nzzn&
	defb 032h,01ah,00eh,006h,000h,000h,0c0h,0e0h,0b0h,098h,0c8h,0ech,0bch,0bch,0ech,0c8h	; 51db  2...............
	defb 098h,0b0h,0e0h,0c0h,007h,000h,084h,003h,00fh,00fh,003h,00ah,000h,088h,010h,0f0h	; 51eb  ................
	defb 0d0h,050h,050h,0d0h,0f0h,010h,00ah,000h,084h,001h,003h,003h,001h,00ch,000h,084h	; 51fb  .PP.............
	defb 080h,0c0h,0c0h,080h,006h,000h,085h,082h,0d6h,0bah,0bah,07ch,009h,038h,081h,010h	; 520b  ...........|.8..
	defb 021h,000h,085h,082h,0d5h,0bah,0bah,07ch,009h,038h,0c4h,010h,000h,000h,040h,031h	; 521b  !......|.8....@1
	defb 018h,00fh,016h,00bh,007h,003h,00dh,033h,006h,008h,014h,008h,000h,000h,042h,004h	; 522b  .......3......B.
	defb 09ch,0b0h,0f4h,0b8h,0f0h,058h,0e5h,060h,030h,018h,088h,004h,042h,080h,044h,032h	; 523b  .....X.`0...B.D2
	defb 03fh,01eh,00bh,013h,024h,01eh,022h,044h,009h,006h,018h,030h,040h,082h,084h,0c8h	; 524b  ?...$."D...0@...
	defb 05ch,058h,030h,09ch,00fh,07ch,030h,0dch,0c8h,0d4h,045h,042h,001h,000h,080h,003h	; 525b  \X0..|0...EB....
	defb 000h,087h,001h,004h,011h,002h,000h,001h,008h,008h,000h,0abh,080h,004h,000h,040h	; 526b  ...............@
	defb 068h,0c0h,000h,004h,000h,080h,000h,000h,001h,018h,030h,000h,046h,004h,0c0h,080h	; 527b  h.........0.F...
	defb 004h,00eh,006h,042h,0c8h,060h,003h,087h,001h,018h,00ch,044h,000h,060h,031h,003h	; 528b  ...B.`.....D.`1.
	defb 000h,018h,030h,000h,004h,00ch,018h,006h,000h,081h,0c4h,005h,04ah,081h,044h,009h	; 529b  ..0.........J.D.
	defb 000h,081h,044h,005h,0aah,081h,044h,004h,000h,09eh,003h,00fh,01fh,034h,012h,00ah	; 52ab  ..D...D......4..
	defb 005h,000h,000h,002h,005h,006h,000h,001h,000h,000h,0c0h,0f0h,0f8h,02ch,048h,050h	; 52bb  .............,HP
	defb 0a0h,000h,000h,040h,0a0h,060h,000h,080h,009h,000h,082h,01bh,007h,005h,00fh,082h	; 52cb  ...@.`..........
	defb 007h,01eh,007h,000h,082h,0d8h,0e0h,005h,0f0h,082h,0e0h,078h,003h,000h,08bh,004h	; 52db  ...........x....
	defb 01ah,012h,012h,006h,01ch,011h,015h,015h,011h,03fh,00bh,000h,003h,054h,082h,024h	; 52eb  .........?...T.$
	defb 0dch,005h,000h,081h,03ch,003h,036h,002h,03ch,005h,03fh,00bh,000h,005h,0fch,006h	; 52fb  ....<.6.<.?.....
	defb 000h,088h,008h,00fh,00bh,00ah,00ah,00bh,00fh,008h,00ah,000h,084h,0c0h,0f0h,0f0h	; 530b  ................
	defb 0c0h,00ah,000h,088h,003h,007h,00dh,00bh,00fh,00fh,007h,003h,008h,000h,082h,0c0h	; 531b  ................
	defb 060h,004h,0f0h,082h,0e0h,0c0h,004h,000h,000h	; 532b  `........

; ======================================================================
; CODIGO 0x5334..0x535f  (43 bytes)
; ======================================================================


RECORRE_OBJETOS:		; Los siete huecos de 0xE200, de 16 bytes cada uno
	ld b,007h		;5334   ; los siete huecos de objeto
	ld hl,0e200h		;5336
HUECO_SIGUIENTE:		; Guarda el hueco en 0xE310 y llama a su rutina
	ld (0e310h),hl		;5339   ; la rutina de turno espera el hueco en 0xE310
	ld a,(hl)			;533c   ; hueco vacio, nada que hacer
	and a			;533d
	jr z,HUECO_MAS_16		;533e
	push bc			;5340
	call RUTINA_DE_OBJETO		;5341   ; y si no, a su rutina
	pop bc			;5344
HUECO_MAS_16:		; Salta al hueco siguiente
	ld hl,(0e310h)		;5345
	ld de,00010h		;5348   ; 16 bytes por hueco
	add hl,de			;534b
	djnz HUECO_SIGUIENTE		;534c
	ret			;534e
RUTINA_DE_OBJETO:		; Salta a la rutina del hueco (su byte +1) con push bc y ret
	inc l			;534f   ; el byte +1 dice que rutina lo maneja
	ld a,(hl)			;5350
	ld de,0535fh		;5351   ; la tabla de las 21 rutinas
	add a,a			;5354   ; dos bytes por rutina
	call SUMA_A_DE		;5355
	ex de,hl			;5358
	ld c,(hl)			;5359
	inc hl			;535a
	ld b,(hl)			;535b
	ex de,hl			;535c
	push bc			;535d   ; el push bc y el ret hacen de salto indirecto sin gastar registros
	ret			;535e

; ----------------------------------------------------------------------
; DATOS tabla_rutinas_objeto: Las 21 rutinas de objeto, indexadas por el byte
;   +1 del hueco
;   0x535f..0x5389  (42 bytes)
DATA_tabla_rutinas_objeto:
	defw 05389h,05390h,053e2h,05441h,05423h,05461h,05465h	; 535f
	defw 05504h,05505h,05505h,05594h,05594h,05599h,05599h	; 536d
	defw 055c7h,055c7h,05612h,05669h,05504h,056b1h,057e1h	; 537b

; ======================================================================
; CODIGO 0x5389..0x53ca  (65 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; LAS RUTINAS DE OBJETO. Una por tipo; 0x534F las llama por la tabla.
; ----------------------------------------------------------------------
OBJETO_TIPO_0:		; Deriva hacia la derecha, mas fuerte cuanto mas lejos esta el avion
	ld b,000h		;5389   ; B a 0 deja el signo positivo: acelera hacia la derecha
	ld de,053cah		;538b   ; y la tabla positiva de 0x53CA
	jr CUENTA_Y_PERSIGUE		;538e
OBJETO_TIPO_1:		; Lo mismo, pero hacia la izquierda
	ld b,0ffh		;5390   ; B a 0xFF es el signo negativo: acelera hacia la izquierda
	ld de,053d6h		;5392   ; con la tabla en negativo de 0x53D6
CUENTA_Y_PERSIGUE:		; No empieza a derivar hasta el fotograma 0x10
	inc l			;5395   ; byte +2: la cuenta de pasos
	inc (hl)			;5396
	ld a,(hl)			;5397
	cp 010h		;5398   ; los dieciseis primeros fotogramas va derecho
	ret c			;539a
	dec l			;539b
PERSIGUE_X:		; Acelera la columna del objeto segun lo lejos que este el avion
	ld a,00ah		;539c   ; de +1 a +11: la columna del objeto
	add a,l			;539e
	ld l,a			;539f
	ld a,(0e182h)		;53a0   ; 0xE182 es la columna del avion
	sub (hl)			;53a3
	jr nc,ELIGE_VELOCIDAD		;53a4   ; lo que interesa es la distancia, sin signo
	neg		;53a6
ELIGE_VELOCIDAD:		; De la distancia saca el indice de la tabla de velocidad
	rra			;53a8   ; los cuatro rra dejan la distancia partida por 16
	rra			;53a9
	rra			;53aa
	rra			;53ab
	and 00fh		;53ac
	call SUMA_A_DE		;53ae   ; asi que la tabla se indexa por lo lejos que esta el avion
	ex de,hl			;53b1
	ld c,(hl)			;53b2
	ex de,hl			;53b3
	ld a,0fbh		;53b4   ; 0xFB es -5: de la columna (+11) a la velocidad lateral (+6)
	add a,l			;53b6
	ld l,a			;53b7
SUMA_VELOCIDAD:		; Suma la velocidad a la posicion de 16 bits, con tope
	ld a,(hl)			;53b8   ; suma la velocidad nueva a la que ya llevaba, en 16 bits
	add a,c			;53b9
	ld (hl),a			;53ba
	ld c,a			;53bb
	inc l			;53bc
	ld a,(hl)			;53bd
	adc a,b			;53be
	ld b,a			;53bf
	rl c		;53c0   ; el bit alto de la parte baja redondea...
	adc a,a			;53c2
	add a,005h		;53c3   ; ...y el resultado tiene que caber entre -5 y 4
	cp 00ah		;53c5
	ret nc			;53c7   ; pasado el tope, la parte alta se queda como estaba: eso limita la velocidad
	ld (hl),b			;53c8
	ret			;53c9

; ----------------------------------------------------------------------
; DATOS aceleracion_lateral_derecha: Cuanto acelera hacia la derecha segun la
;   distancia (0 a 11) al avion; va a los bytes +6/+7 del hueco
;   0x53ca..0x53d6  (12 bytes)
DATA_aceleracion_lateral_derecha:
	defb 001h,001h,002h,002h,003h,003h,004h,004h,005h,005h,006h,006h	; 53ca  ............

; ----------------------------------------------------------------------
; DATOS aceleracion_lateral_izquierda: La misma tabla en negativo, para los
;   que derivan hacia la izquierda
;   0x53d6..0x53e2  (12 bytes)
DATA_aceleracion_lateral_izquierda:
	defb 0ffh,0ffh,0feh,0feh,0fdh,0fdh,0fch,0fch,0fbh,0fbh,0fah,0fah	; 53d6  ............

; ======================================================================
; CODIGO 0x53e2..0x5449  (103 bytes)
; ======================================================================


OBJETO_TIPO_2:		; Deriva despacio y, con el avion a tiro, se lanza en picado
	ld a,00ah		;53e2   ; de +1 a +11: la columna
	add a,l			;53e4
	ld l,a			;53e5
	ld a,(0e182h)		;53e6   ; la distancia al avion, ahora CON signo
	sub (hl)			;53e9
	ld bc,00080h		;53ea   ; 0x0080 es medio pixel por fotograma hacia un lado...
	jr nc,TIPO_2_DECIDE		;53ed
	ld bc,0ff80h		;53ef   ; ...o hacia el otro
TIPO_2_DECIDE:		; Cerca del avion se transforma; lejos, sigue derivando
	dec l			;53f2
	dec l			;53f3
	dec l			;53f4
	dec l			;53f5
	add a,00ah		;53f6   ; con el avion a menos de diez columnas, se lanza
	cp 014h		;53f8
	jr c,TIPO_2_SE_TRANSFORMA		;53fa
	ld (hl),b			;53fc   ; y si no, sigue derivando despacio
	dec l			;53fd
	ld (hl),c			;53fe
	ld a,006h		;53ff
	add a,l			;5401
	ld l,a			;5402
	ld c,010h		;5403   ; patrones 0x10 y 0x14, cambiando cada dos fotogramas
	ld b,084h		;5405
	jp PATRON_ANIMADO		;5407
TIPO_2_SE_TRANSFORMA:		; Se vuelve del tipo 0x12 con patrones 0x10 y 0x14
	xor a			;540a   ; nada de velocidad lateral: cae en vertical
	ld (hl),a			;540b
	dec l			;540c
	ld (hl),a			;540d
	dec l			;540e
	ld (hl),003h		;540f   ; byte +5: velocidad de caida 3, que es picar de verdad
	dec l			;5411
	ld (hl),a			;5412
	dec l			;5413
	dec l			;5414
	dec l			;5415
	ld (hl),012h		;5416   ; y se cambia por la rutina 0x12, la del kamikaze
	ld a,00bh		;5418
	add a,l			;541a
	ld l,a			;541b
	ld (hl),010h		;541c   ; patrones 0x10 y 0x14 para el picado
	inc hl			;541e
	inc hl			;541f
	ld (hl),014h		;5420
	ret			;5422
OBJETO_TIPO_4:		; Acelera hacia la izquierda y en el paso 0x40 da la vuelta
	ld bc,0ff0ch		;5423   ; acelera hacia la izquierda...
	ld de,05449h		;5426   ; ...con la tabla de 0x5449
CUENTA_Y_CAE:		; Cuenta pasos y elige la aceleracion lateral que toca
	inc l			;5429   ; byte +2: el paso
	inc (hl)			;542a
	ld a,(hl)			;542b
	cp 008h		;542c   ; los ocho primeros pasos va derecho
	ret c			;542e
	cp 040h		;542f   ; y al llegar al paso 0x40 da la vuelta
	jr nc,DA_LA_VUELTA		;5431
	dec l			;5433
	jp PERSIGUE_X		;5434
DA_LA_VUELTA:		; Invierte el signo de la velocidad
	ld a,b			;5437   ; el complemento del signo: lo que iba a la izquierda va a la derecha
	cpl			;5438
	ld b,a			;5439
	inc l			;543a   ; de +2 a +6, la velocidad lateral
	inc l			;543b
	inc l			;543c
	inc l			;543d
	jp SUMA_VELOCIDAD		;543e
OBJETO_TIPO_3:		; El mismo, arrancando hacia la derecha
	ld de,05455h		;5441   ; el tipo 3 es el mismo, con la tabla al reves...
	ld bc,000f4h		;5444   ; ...y arrancando hacia la derecha
	jr CUENTA_Y_CAE		;5447

; ----------------------------------------------------------------------
; DATOS aceleracion_izquierda_tipo_4: Cuanto acelera hacia la izquierda el
;   tipo 4, segun la distancia (0 a 11) al avion
;   0x5449..0x5455  (12 bytes)
DATA_aceleracion_izquierda_tipo_4:
	defb 0feh,0fch,0fah,0f8h,0f6h,0f4h,0f2h,0f0h,0eeh,0eeh,0eeh,0eeh	; 5449  ............

; ----------------------------------------------------------------------
; DATOS aceleracion_derecha_tipo_3: La misma hacia el otro lado, para el tipo
;   3
;   0x5455..0x5461  (12 bytes)
DATA_aceleracion_derecha_tipo_3:
	defb 002h,004h,006h,008h,00ah,00ch,00eh,010h,012h,012h,012h,012h	; 5455  ............

; ======================================================================
; CODIGO 0x5461..0x54c4  (99 bytes)
; ======================================================================


OBJETO_TIPO_5:		; Da vueltas empezando por el indice 0
	ld c,000h		;5461   ; el tipo 5 empieza la vuelta por el paso 0
	jr GIRA		;5463
OBJETO_TIPO_6:		; Da vueltas empezando por el indice 6
	ld c,006h		;5465   ; y el tipo 6 por el 6, o sea media vuelta despues
GIRA:		; Recorre la tabla de giro, mas deprisa si esta el gigante
	ld b,008h		;5467   ; la vuelta no arranca hasta el paso 8
	ld a,(0e140h)		;5469   ; con el gigante delante arranca dos pasos antes...
	cp 002h		;546c
	jr nz,GIRA_CUENTA		;546e
	ld b,006h		;5470
	set 3,c		;5472   ; ...y gira al reves: el bit 3 le da la vuelta al sentido
GIRA_CUENTA:		; Un paso de giro cada 16 fotogramas
	inc l			;5474   ; byte +2: el paso del giro
	ld a,(0e003h)		;5475   ; un paso de giro cada 16 fotogramas
	and 00fh		;5478
	jr nz,GIRA_INDICE		;547a
	inc (hl)			;547c
GIRA_INDICE:		; Del paso saca el indice de la tabla de giro
	ld a,(hl)			;547d   ; el giro dura catorce pasos desde el paso B
	sub b			;547e
	cp 00eh		;547f
	jr nc,PATRON_GIRA		;5481
	ld b,a			;5483
	ld a,c			;5484   ; con el indice 0 o el 14 el giro va hacia delante...
	dec a			;5485
	cp 00dh		;5486
	ld a,b			;5488
	jr nc,GIRA_APLICA		;5489
	neg		;548b   ; ...y con el 6 o el 8, hacia atras
GIRA_APLICA:		; Suma los dos incrementos de 16 bits a la posicion
	add a,c			;548d   ; dieciseis posiciones en la vuelta
	and 00fh		;548e
	add a,a			;5490   ; cuatro bytes por posicion: dos incrementos de 16 bits
	add a,a			;5491
	ld de,054c4h		;5492
	call SUMA_A_DE		;5495
	ld b,002h		;5498   ; uno para la fila y otro para la columna
	inc l			;549a
GIRA_SUMA:		; Un incremento de 16 bits
	inc l			;549b   ; bytes +4/+5 la primera vuelta, +6/+7 la segunda
	ld a,(de)			;549c   ; la parte baja del incremento
	add a,(hl)			;549d
	ld (hl),a			;549e
	inc l			;549f
	inc de			;54a0
	ld a,(de)			;54a1   ; y la alta, con el acarreo
	adc a,(hl)			;54a2
	ld (hl),a			;54a3
	inc de			;54a4   ; cuatro bytes por posicion de la vuelta: dos incrementos
	djnz GIRA_SUMA		;54a5
PATRON_GIRA:		; Elige el patron y suena
	ld hl,(0e310h)		;54a7   ; los patrones estan en +12
	ld de,0000ch		;54aa
	add hl,de			;54ad
	ld c,030h		;54ae   ; los cuatro patrones del giro arrancan en 0x30
	ld b,003h		;54b0   ; 3 es el zumbido de este bicho
PATRON_ANIMADO:		; Patron que cambia cada dos fotogramas, y su pareja
	ld a,(0e003h)		;54b2   ; cambia de patron cada dos fotogramas, cuatro en total
	and 006h		;54b5
	add a,a			;54b7
	add a,a			;54b8
	add a,c			;54b9   ; C es el primer patron de los cuatro
	ld (hl),a			;54ba
	inc l			;54bb   ; de +12 a +14: el patron de la segunda ficha
	inc l			;54bc
	add a,004h		;54bd   ; que va cuatro mas alla
	ld (hl),a			;54bf
	ld a,b			;54c0
	jp SUENA_SI_CAMBIA		;54c1

; ----------------------------------------------------------------------
; DATOS tabla_giro: Dieciseis parejas de incrementos de 16 bits: la vuelta
;   completa
;   0x54c4..0x5504  (64 bytes)
DATA_tabla_giro:
	defw 0fffeh,00005h	; 54c4
	defw 0fffch,00004h	; 54c8
	defw 0fffbh,00002h	; 54cc
	defw 0fffah,00000h	; 54d0
	defw 0fffbh,0fffeh	; 54d4
	defw 0fffch,0fffch	; 54d8
	defw 0fffeh,0fffbh	; 54dc
	defw 00000h,0fffah	; 54e0
	defw 00002h,0fffbh	; 54e4
	defw 00004h,0fffch	; 54e8
	defw 00005h,0fffeh	; 54ec
	defw 00006h,00000h	; 54f0
	defw 00005h,00002h	; 54f4
	defw 00004h,00004h	; 54f8
	defw 00002h,00005h	; 54fc
	defw 00000h,00006h	; 5500

; ======================================================================
; CODIGO 0x5504..0x55fc  (248 bytes)
; ======================================================================


OBJETO_NADA:		; Los tipos 7 y 18 no hacen nada
	ret			;5504
OBJETO_TIPO_8:		; El disparo grande: rebota en los bordes de la pantalla
	ld a,005h		;5505   ; LEE_PUNTERO deja HL en +7 y DE con la velocidad lateral de +6/+7
	call LEE_PUNTERO		;5507
	inc l			;550a   ; de +7 a +11: la columna
	inc l			;550b
	inc l			;550c
	inc l			;550d
	ld a,(hl)			;550e
	cp 010h		;550f   ; pegado al borde izquierdo, rebota hacia la derecha
	jr nc,TIPO_8_BORDE_BAJO		;5511
	ld de,000a0h		;5513
TIPO_8_BORDE_BAJO:		; Por abajo se manda hacia arriba
	cp 0a0h		;5516   ; y pegado al derecho, hacia la izquierda
	jr c,TIPO_8_GUARDA		;5518
	ld de,0ff60h		;551a
TIPO_8_GUARDA:		; Deja la velocidad nueva
	dec l			;551d
	dec l			;551e
	dec l			;551f
	dec l			;5520
	ld (hl),d			;5521   ; velocidad lateral nueva, bytes +7 y +6
	dec l			;5522
	ld (hl),e			;5523
	ld de,00006h		;5524   ; de +6 a +12, los patrones
	add hl,de			;5527
	ld a,(0e003h)		;5528   ; el bit 3 del contador cambia el dibujo cada ocho fotogramas
	bit 3,a		;552b
	ld de,05c58h		;552d   ; una pareja de patrones...
	jr nz,TIPO_8_PATRON		;5530
	ld de,06460h		;5532   ; ...o la otra; van juntos en un solo ld de
TIPO_8_PATRON:		; Los patrones salen de 0x5C58 o de 0x6460 segun el fotograma
	ld (hl),e			;5535   ; +12 el primero y +14 el segundo
	inc l			;5536
	inc l			;5537
	ld (hl),d			;5538
	ld de,0fff4h		;5539   ; 0xFFF4 es -12: de vuelta al byte +2
	add hl,de			;553c
	ld a,(hl)			;553d
	ld c,a			;553e
	and 00ch		;553f   ; bits 2 y 3 del estado: alguna de las dos piezas esta explotando
	ld a,047h		;5541   ; sin explosion, solo zumba
	jp z,SUENA_SI_CAMBIA		;5543
	ld a,l			;5546   ; el nibble alto del byte bajo del hueco es el numero de hueco (0 a 6)
	rra			;5547
	rra			;5548
	rra			;5549
	rra			;554a
	and 00fh		;554b
	exx			;554d
	ld hl,0e1c6h		;554e   ; 0xE1C6 lleva una cuenta por hueco, que es la que dura la explosion
	call SUMA_A_HL		;5551
	dec (hl)			;5554   ; un fotograma menos de explosion
	ld a,(hl)			;5555
	exx			;5556
	ld de,0000ah		;5557   ; de +2 a +12
	add hl,de			;555a
	cp 008h		;555b   ; la explosion cambia de dibujo a mitad de cuenta
	ld de,00694h		;555d   ; patron 0x94 y color 6...
	jr nc,TIPO_8_PIEZA_A		;5560
	ld de,00fa0h		;5562   ; ...o patron 0xA0 y color 15
TIPO_8_PIEZA_A:		; La primera pieza del disparo
	bit 2,c		;5565   ; bit 2: la primera pieza esta explotando
	jr z,TIPO_8_PIEZA_B		;5567
	ld (hl),e			;5569
	inc l			;556a
	ld (hl),d			;556b
	dec l			;556c
TIPO_8_PIEZA_B:		; La segunda pieza
	inc l			;556d
	inc l			;556e
	bit 3,c		;556f   ; bit 3: la segunda
	jr z,TIPO_8_CUENTA		;5571
	ld (hl),e			;5573
	inc l			;5574
	ld (hl),d			;5575
	dec l			;5576
TIPO_8_CUENTA:		; Al acabarse la cuenta, apaga las piezas
	inc l			;5577   ; mientras quede cuenta no se apaga nada
	and a			;5578
	ret nz			;5579
	bit 3,c		;557a   ; agotada la cuenta, el color a cero borra la pieza
	jr z,TIPO_8_APAGA_A		;557c
	ld (hl),000h		;557e
TIPO_8_APAGA_A:		; Apaga la primera pieza
	dec l			;5580
	dec l			;5581
	bit 2,c		;5582   ; y lo mismo con la otra
	jr z,TIPO_8_FIN		;5584
	ld (hl),000h		;5586
TIPO_8_FIN:		; Sin piezas vivas, el hueco se libera
	ld a,003h		;5588   ; bits 0 y 1: piezas que siguen vivas
	and c			;558a   ; sin ninguna, el hueco queda libre
	jp z,APAGA_HUECO		;558b
	ld de,0fff5h		;558e   ; y si queda alguna, el estado se queda solo con esos dos bits
	add hl,de			;5591
	ld (hl),a			;5592
	ret			;5593
OBJETO_TIPO_10:		; Solo suena
	ld a,081h		;5594   ; 0x81 es el zumbido de este objeto
	jp SUENA_SI_CAMBIA		;5596
OBJETO_TIPO_12:		; Se mueve a un lado u otro segun donde este
	ld a,(0e003h)		;5599   ; el bit 0 del contador da un vaiven de un pixel
	bit 0,a		;559c
	ld c,000h		;559e
	jr nz,TIPO_12_DERECHA		;55a0
	dec c			;55a2
TIPO_12_DERECHA:		; Pasado 0x60 tira a la derecha
	ld a,008h		;55a3   ; de +1 a +9: la fila
	add a,l			;55a5
	ld l,a			;55a6
	ld a,(hl)			;55a7
	sub 028h		;55a8   ; las dos restas parten la pantalla: por debajo de 0x60 no tira a la derecha...
	sub 038h		;55aa
	jr nc,TIPO_12_IZQUIERDA		;55ac
	ld c,000h		;55ae
TIPO_12_IZQUIERDA:		; Antes de 0x18 tira a la izquierda
	sub 018h		;55b0   ; ...y por debajo de 0x18 tira a la izquierda
	sub 088h		;55b2
	jr nc,TIPO_12_GUARDA		;55b4
	ld c,0ffh		;55b6
TIPO_12_GUARDA:		; Deja el sentido y el patron
	ld a,004h		;55b8   ; de +9 a +13: el color de la primera ficha
	add a,l			;55ba
	ld l,a			;55bb
	ld a,001h		;55bc   ; color 1 o 0 segun el sentido
	and c			;55be
	ld (hl),a			;55bf
	inc l			;55c0
	inc l			;55c1
	ld a,00fh		;55c2   ; y color 15 o 0 en la segunda: el bicho parpadea de lado a lado
	and c			;55c4
	ld (hl),a			;55c5
	ret			;55c6
OBJETO_TIPO_14:		; Alterna cuatro parejas de patron cada cuatro fotogramas
	ld a,(0e003h)		;55c7   ; solo se toca cada cuatro fotogramas
	and 003h		;55ca
	ret nz			;55cc
	ld e,a			;55cd
	inc l			;55ce   ; byte +2, que aqui es el contador de la animacion
	ld a,(hl)			;55cf
	inc (hl)			;55d0
	ex de,hl			;55d1
	rra			;55d2   ; los cinco rra dejan los bits 6 y 7 de la cuenta: la pareja cambia cada 256 fotogramas
	rra			;55d3
	rra			;55d4
	rra			;55d5
	rra			;55d6
	and 00eh		;55d7
	ld hl,055fch		;55d9   ; las cuatro parejas de 0x55FC
	call SUMA_A_HL		;55dc
	ld c,(hl)			;55df
	inc hl			;55e0
	ld b,(hl)			;55e1
	ld a,(0e321h)		;55e2   ; solo la oleada 9 usa la tabla...
	cp 009h		;55e5
	jr z,TIPO_14_GUARDA		;55e7
	ld bc,07c80h		;55e9   ; ...los demas van siempre con la pareja fija 0x7C/0x80
TIPO_14_GUARDA:		; Reparte la pareja entre las dos fichas
	ex de,hl			;55ec
	inc l			;55ed   ; byte +4: la parte baja de la velocidad de caida
	inc l			;55ee
	ld (hl),c			;55ef
	ld a,008h		;55f0   ; byte +12: el patron de la primera ficha
	add a,l			;55f2
	ld l,a			;55f3
	ld (hl),b			;55f4
	inc l			;55f5   ; y el +14 va cuatro patrones mas alla
	inc l			;55f6
	ld a,b			;55f7
	add a,004h		;55f8
	ld (hl),a			;55fa
	ret			;55fb

; ----------------------------------------------------------------------
; DATOS tabla_pareja_oleada_9: Cuatro parejas que 0x55C7 alterna; fuera de la
;   oleada 9 siempre usa la fija 0x80/0x7C
;   0x55fc..0x5604  (8 bytes)
DATA_tabla_pareja_oleada_9:
	defb 080h,07ch	; 55fc
	defb 000h,074h	; 55fe
	defb 080h,07ch	; 5600
	defb 000h,074h	; 5602

; ======================================================================
; CODIGO 0x5604..0x58ff  (763 bytes)
; ======================================================================


SUENA_SI_ES_TRES:		; Con B igual a tres, pide el sonido 0x85
	ld a,b			;5604   ; el 3 es el zumbido del bicho que gira
	cp 003h		;5605
	ret nz			;5607
	ld a,085h		;5608   ; 0x85 es el otro aviso
SUENA_SI_CAMBIA:		; Pide el sonido A salvo que el canal C ya lo este tocando
	ld hl,0e032h		;560a   ; no se vuelve a pedir un sonido que el canal C ya esta tocando
	cp (hl)			;560d
	ret z			;560e
	jp PIDE_SONIDO		;560f
OBJETO_TIPO_16:		; Las dos piezas de una explosion en marcha
	inc l			;5612   ; byte +2: el estado
	ld a,(hl)			;5613
	ld b,a			;5614
	and 00ch		;5615   ; bits 2 y 3: hay alguna pieza explotando
	jr z,SUENA_SI_ES_TRES		;5617
	ld de,0000ah		;5619   ; de +2 a +12: los patrones
	add hl,de			;561c
	ex de,hl			;561d
	ld a,e			;561e   ; el nibble alto da el numero de hueco
	rra			;561f
	rra			;5620
	rra			;5621
	rra			;5622
	and 00fh		;5623
	ld hl,0e1c6h		;5625   ; y con el, la cuenta de explosion de este hueco
	call SUMA_A_HL		;5628
	dec (hl)			;562b
	ld a,(hl)			;562c
	ex de,hl			;562d
	push af			;562e
	cp 008h		;562f   ; a mitad de cuenta cambia el dibujo de la explosion
	ld c,098h		;5631   ; patron 0x98 al final...
	jr nc,TIPO_16_PIEZA_A		;5633
	ld c,0a0h		;5635   ; ...y 0xA0 al principio
TIPO_16_PIEZA_A:		; Patron y color de la primera pieza
	bit 2,b		;5637   ; bit 2: primera pieza
	jr z,TIPO_16_PIEZA_B		;5639
	ld (hl),c			;563b
	inc hl			;563c
	ld (hl),00fh		;563d   ; color 15 para la explosion
	dec hl			;563f
TIPO_16_PIEZA_B:		; Patron y color de la segunda
	inc hl			;5640
	inc hl			;5641
	bit 3,b		;5642   ; bit 3: segunda pieza
	jr z,TIPO_16_CUENTA		;5644
	ld (hl),c			;5646
	inc hl			;5647
	ld (hl),00fh		;5648
	dec hl			;564a
TIPO_16_CUENTA:		; Al llegar a cero se apagan las piezas
	pop af			;564b   ; agotada la cuenta se apagan
	and a			;564c
	ret nz			;564d
	inc hl			;564e
	bit 3,b		;564f
	jr z,TIPO_16_APAGA_A		;5651
	ld (hl),000h		;5653   ; color a cero, que es borrar
TIPO_16_APAGA_A:		; Apaga la primera pieza
	dec hl			;5655
	dec hl			;5656
	bit 2,b		;5657
	jr z,TIPO_16_FIN		;5659
	ld (hl),000h		;565b
TIPO_16_FIN:		; Sin piezas vivas, el hueco se apaga del todo
	ld a,b			;565d   ; bits 0 y 1: lo que quede vivo
	and 003h		;565e
	jp z,APAGA_HUECO		;5660   ; sin nada vivo, el hueco se libera
	ld de,0fff5h		;5663   ; 0xFFF5 es -11: vuelta al byte +2
	add hl,de			;5666
	ld (hl),a			;5667
	ret			;5668
OBJETO_TIPO_17:		; A los 0x40 pasos se convierte en el tipo 0x13
	dec hl			;5669   ; IX se queda el hueco entero para leerlo por indice
	push hl			;566a
	pop ix		;566b
	inc l			;566d
	inc l			;566e
	inc (hl)			;566f   ; byte +2: el paso
	ld a,(hl)			;5670
	cp 040h		;5671   ; a los 64 pasos se parte en dos
	ret nz			;5673
	dec l			;5674
	ld (hl),013h		;5675   ; la rutina 0x13 son las dos piezas que persiguen al avion
	ld a,(0e182h)		;5677   ; mira a que lado queda el avion
	sub (ix+00bh)		;567a
	ld bc,00140h		;567d   ; 0x140 son 320 hacia la derecha...
	jr nc,TIPO_17_MONTA		;5680
	ld bc,0fec0h		;5682   ; ...y 0xFEC0 los mismos 320 hacia la izquierda
TIPO_17_MONTA:		; Rellena el hueco del tipo 0x13 apuntando al avion
	inc l			;5685
	ld (hl),001h		;5686   ; el hueco cambia de forma: +2 es la primera pieza viva
	inc l			;5688
	ld e,(ix+009h)		;5689   ; +3 la fila de la primera pieza, heredada del bicho
	ld (hl),e			;568c
	inc l			;568d
	ld (hl),c			;568e   ; +4/+5 la velocidad lateral, hacia el avion
	inc l			;568f
	ld (hl),b			;5690
	inc l			;5691
	inc l			;5692
	ld d,(ix+00bh)		;5693   ; +7 la columna, ocho pixeles a la derecha del bicho
	ld a,008h		;5696
	add a,d			;5698
	ld (hl),a			;5699
	inc l			;569a
	ld (hl),08ch		;569b   ; +8 y +9: patron 0x8C y color 11
	inc l			;569d
	ld (hl),00bh		;569e
	inc l			;56a0
	ld a,(0e1b7h)		;56a1   ; byte +10: la cuenta atras hasta el disparo
	ld (hl),a			;56a4
	inc l			;56a5
	ld (hl),00bh		;56a6   ; +11 marca viva la segunda pieza
	inc l			;56a8
	ld (hl),e			;56a9   ; +12 y +13: la fila y la columna de la segunda
	inc l			;56aa
	ld (hl),d			;56ab
	ld a,006h		;56ac   ; 0x06 es el estallido del bicho al partirse
	jp PIDE_SONIDO		;56ae
OBJETO_TIPO_19:		; Las dos piezas del bicho que persigue al avion
	ld de,0e182h		;56b1   ; las dos piezas van a por la columna del avion
	push de			;56b4
	call PIEZA_QUE_PERSIGUE		;56b5
	pop de			;56b8
	call SEGUNDA_PIEZA		;56b9
	ld hl,(0e310h)		;56bc   ; con las dos piezas apagadas...
	xor a			;56bf
	inc l			;56c0
	inc l			;56c1
	or (hl)			;56c2   ; +2 la primera y +11 la segunda
	ld de,00009h		;56c3
	add hl,de			;56c6
	or (hl)			;56c7
	ret nz			;56c8
	ld de,0fff5h		;56c9
	add hl,de			;56cc
	ld (hl),000h		;56cd   ; ...el hueco queda libre
	ld hl,0e194h		;56cf   ; y un objeto vivo menos
	dec (hl)			;56d2
	ret			;56d3
PIEZA_QUE_PERSIGUE:		; Mueve la primera pieza hacia la columna del avion
	inc l			;56d4   ; +2 a cero: esta pieza ya no esta
	ld a,(hl)			;56d5
	and a			;56d6
	ret z			;56d7
	exx			;56d8
	ld b,a			;56d9   ; B prima se guarda si la pieza esta viva o explotando
	exx			;56da
	inc l			;56db   ; byte +3: la fila, que baja dos pixeles por fotograma
	inc (hl)			;56dc
	inc (hl)			;56dd
	ld a,(hl)			;56de
	cp 0c0h		;56df   ; pasada la fila 0xC0 la pieza se ha ido
	exx			;56e1
	ld c,000h		;56e2
	jr c,PIEZA_SENTIDO		;56e4
	ld c,001h		;56e6
PIEZA_SENTIDO:		; Diez pixeles hacia el avion, en el sentido que toque
	exx			;56e8
	inc l			;56e9   ; de +3 a +7: la columna
	inc l			;56ea
	inc l			;56eb
	inc l			;56ec
	ld a,(de)			;56ed   ; 0xE182 es la columna del avion
	ld bc,0000ah		;56ee   ; diez pixeles hacia el avion, sea el lado que sea
	sub (hl)			;56f1
	jr nc,PIEZA_SUMA		;56f2
	ld bc,0fff6h		;56f4
PIEZA_SUMA:		; Suma el desvio a la posicion de 16 bits
	dec l			;56f7   ; de +7 a +4: la velocidad lateral acumulada
	dec l			;56f8
	dec l			;56f9
	ld a,c			;56fa
	add a,(hl)			;56fb
	ld (hl),a			;56fc
	ld c,a			;56fd
	inc l			;56fe
	ld a,b			;56ff
	adc a,(hl)			;5700
	ld b,(hl)			;5701
	add a,004h		;5702   ; la velocidad se queda entre -4 y 3
	cp 008h		;5704
	jr nc,PIEZA_FILA		;5706
	sub 004h		;5708
	ld b,a			;570a
	ld (hl),a			;570b
PIEZA_FILA:		; Baja la fila y elige el patron segun donde este
	inc l			;570c   ; bytes +6 y +7: la columna, en 16 bits
	ld a,c			;570d
	add a,(hl)			;570e
	ld (hl),a			;570f
	inc l			;5710
	ld a,b			;5711
	adc a,(hl)			;5712
	ld (hl),a			;5713
	sub 008h		;5714   ; fuera de la franja de 8 a 0xB0 el color se pone a cero y la pieza no se ve
	inc l			;5716
	inc l			;5717
	cp 0a8h		;5718
	ld a,00bh		;571a
	jr c,PIEZA_GUARDA_PATRON		;571c
	xor a			;571e
PIEZA_GUARDA_PATRON:		; Deja el patron de la pieza
	ld (hl),a			;571f   ; byte +9: el color
	ex af,af'			;5720
	dec l			;5721
	dec l			;5722
	exx			;5723
	ld a,b			;5724
	exx			;5725
	cp 002h		;5726   ; el valor 2 en +2 quiere decir que le han dado
	jr nz,PIEZA_FIN		;5728
	ld a,l			;572a   ; otra vez el numero de hueco, para su cuenta de explosion
	ex de,hl			;572b
	rra			;572c
	rra			;572d
	rra			;572e
	rra			;572f
	and 00fh		;5730
	ld hl,0e1c6h		;5732
	call SUMA_A_HL		;5735
	dec (hl)			;5738   ; agotada la cuenta, la pieza muere
	jr nz,PIEZA_MUERE		;5739
	exx			;573b
	ld c,001h		;573c   ; la marca de muerta viaja en C prima
	exx			;573e
	ld (hl),001h		;573f
PIEZA_MUERE:		; La pieza esta explotando: patrones de explosion
	ld a,(hl)			;5741   ; la explosion cambia de dibujo a mitad de cuenta
	cp 008h		;5742
	ld c,098h		;5744   ; patron 0x98 al final y 0xA0 al principio
	jr nc,PIEZA_EXPLOSION		;5746
	ld c,0a0h		;5748
PIEZA_EXPLOSION:		; Patron y color de la explosion
	ex de,hl			;574a   ; byte +8: el patron de la explosion
	inc l			;574b
	ld (hl),c			;574c
	inc l			;574d
	ex af,af'			;574e   ; si la pieza estaba a la vista, la explosion va en blanco
	and a			;574f
	jr z,PIEZA_COLOR		;5750
	ld a,00fh		;5752
PIEZA_COLOR:		; Color de la pieza que explota
	ld (hl),a			;5754
PIEZA_FIN:		; Si la pieza ha muerto, se apaga su ficha
	exx			;5755   ; C prima distinto de cero: la pieza ha muerto
	ld a,c			;5756
	exx			;5757
	and a			;5758
	ret z			;5759
	ld hl,(0e310h)		;575a
	inc l			;575d   ; +2 a cero: fuera
	inc l			;575e
	ld (hl),000h		;575f
	ld a,l			;5761   ; el numero de hueco por ocho da su ficha de sprite
	and 0f0h		;5762
	rra			;5764
	ld hl,0e0d4h		;5765
	call SUMA_A_HL		;5768
	ld (hl),0c3h		;576b   ; fila 0xC3: la ficha se va de la pantalla
	ret			;576d
SEGUNDA_PIEZA:		; La segunda pieza del bicho, que sigue a la primera
	ld hl,(0e310h)		;576e   ; la segunda pieza empieza en el byte +11
	ld a,00bh		;5771
	add a,l			;5773
	ld l,a			;5774
	ld a,(hl)			;5775   ; +11 a cero: la segunda pieza ya no esta
	and a			;5776
	ret z			;5777
	exx			;5778
	ld c,000h		;5779   ; C prima marca la muerte y B prima si esta explotando
	ld b,a			;577b
	exx			;577c
	inc l			;577d   ; byte +12: la fila, dos pixeles por fotograma
	inc (hl)			;577e
	inc (hl)			;577f
	ld a,(hl)			;5780
	cp 0c0h		;5781   ; pasada la 0xC0 se ha ido por abajo
	jr c,SEGUNDA_MUEVE		;5783
	exx			;5785
	ld c,001h		;5786
	exx			;5788
SEGUNDA_MUEVE:		; Un pixel hacia la columna del avion, uno de cada dos
	inc l			;5789   ; byte +13: la columna
	ld a,(0e003h)		;578a   ; esta pieza solo se mueve de lado uno de cada dos fotogramas: es mas lenta que la primera
	rra			;578d
	jr c,SEGUNDA_MIRA_MUERTE		;578e
	ld a,(de)			;5790   ; un pixel hacia la columna del avion
	sub (hl)			;5791
	ld a,001h		;5792
	jr nc,SEGUNDA_APLICA		;5794
	ld a,0ffh		;5796
SEGUNDA_APLICA:		; Suma el pixel a la columna de la segunda pieza
	add a,(hl)			;5798
	ld (hl),a			;5799
SEGUNDA_MIRA_MUERTE:		; Si esta explotando, patrones de explosion
	exx			;579a
	ld a,b			;579b
	cp 002h		;579c   ; el valor 2 en +11 quiere decir que le han dado
	exx			;579e
	jr nz,SEGUNDA_FIN		;579f
	inc l			;57a1
	ld a,l			;57a2   ; el numero de hueco, para su cuenta de explosion
	ex de,hl			;57a3
	rra			;57a4
	rra			;57a5
	rra			;57a6
	rra			;57a7
	and 00fh		;57a8
	ld hl,0e1c6h		;57aa
	call SUMA_A_HL		;57ad
	dec (hl)			;57b0   ; agotada la cuenta, muere
	jr nz,SEGUNDA_EXPLOSION		;57b1
	exx			;57b3
	ld c,001h		;57b4
	exx			;57b6
	ld (hl),001h		;57b7
SEGUNDA_EXPLOSION:		; Patron de explosion segun la cuenta
	ld a,(hl)			;57b9   ; patron 0x98 al final de la cuenta y 0xA0 al principio
	cp 008h		;57ba
	ld c,098h		;57bc
	jr nc,SEGUNDA_COLOR		;57be
	ld c,0a0h		;57c0
SEGUNDA_COLOR:		; Patron y color de la explosion
	ex de,hl			;57c2
	ld (hl),c			;57c3   ; bytes +14 y +15: patron y color de la explosion
	inc l			;57c4
	ld (hl),00fh		;57c5
SEGUNDA_FIN:		; Al morir, apaga su ficha de sprite
	exx			;57c7
	ld a,c			;57c8   ; C prima distinto de cero: la pieza ha muerto
	and a			;57c9
	ret z			;57ca
	ld hl,(0e310h)		;57cb
	ld de,0000bh		;57ce
	add hl,de			;57d1
	ld (hl),000h		;57d2   ; +11 a cero: fuera
	ld a,l			;57d4
	and 0f0h		;57d5   ; el numero de hueco por ocho da su ficha, y esta va en la segunda (0xE0D8)
	rra			;57d7
	ld hl,0e0d8h		;57d8
	call SUMA_A_HL		;57db
	ld (hl),0c3h		;57de   ; fila 0xC3: fuera de la pantalla
	ret			;57e0
OBJETO_TIPO_20:		; La explosion del bicho grande, que se apaga sola
	ld a,l			;57e1   ; el numero de hueco da su cuenta de explosion
	exx			;57e2
	rra			;57e3
	rra			;57e4
	rra			;57e5
	rra			;57e6
	and 00fh		;57e7
	ld hl,0e1c6h		;57e9
	call SUMA_A_HL		;57ec
	dec (hl)			;57ef   ; agotada la cuenta, el hueco queda libre
	jp z,APAGA_HUECO		;57f0
	ld a,(hl)			;57f3
	exx			;57f4
	dec l			;57f5   ; byte +0: el tipo, que aqui elige la pareja de patrones
	ld c,(hl)			;57f6
	ld de,00009h		;57f7   ; de +0 a +9
	add hl,de			;57fa
	cp 008h		;57fb   ; a mitad de cuenta cambia el dibujo
	ld de,09894h		;57fd   ; patrones 0x94 y 0x98...
	jr nc,EXPLOSION_PATRON		;5800
	ld de,0a09ch		;5802   ; ...o 0x9C y 0xA0
EXPLOSION_PATRON:		; Patrones de la explosion segun la cuenta
	ld a,c			;5805
	sub 010h		;5806   ; el tipo 16 lleva su propia pareja de patrones
	jr c,EXPLOSION_GUARDA		;5808
	ld de,0fcfch		;580a   ; 0xFC en las dos fichas...
	jr nz,EXPLOSION_GUARDA		;580d
	ld de,0a4fch		;580f   ; ...y 0xFC con 0xA4 para el tipo 17
EXPLOSION_GUARDA:		; Deja los dos patrones y sus colores
	ld a,003h		;5812   ; de +9 a +12
	add a,l			;5814
	ld l,a			;5815
	ld (hl),e			;5816
	inc hl			;5817
	ld (hl),006h		;5818   ; color 6 la primera ficha y 15 la segunda
	inc hl			;581a
	ld (hl),d			;581b
	inc hl			;581c
	ld (hl),00fh		;581d
	ret			;581f
SUBE_ESCENA:		; Suma uno (en BCD) al numero de escena y lo repinta
	push hl			;5820   ; la escena es un byte BCD, asi que el daa detras de la suma
	push de			;5821
	ld hl,0e051h		;5822
	ld a,(hl)			;5825
	add a,001h		;5826
	daa			;5828
	ld (hl),a			;5829
	call PINTA_ESCENA		;582a   ; y se repinta en el panel
	pop de			;582d
	pop hl			;582e
	ret			;582f
PINTA_FONDO:		; Dibuja el fondo entero en la posicion actual
	ld de,(0e1b8h)		;5830   ; dibuja el fondo entero sin mover la posicion
	ld a,e			;5834
	jr DIVIDE_ENTRE_OCHO		;5835

; ----------------------------------------------------------------------
; EL FONDO. Se redibuja entero una vez cada 16 fotogramas.
; ----------------------------------------------------------------------
PASO_DE_FONDO:		; Avanza la posicion en la fase y redibuja el fondo
	ld a,(0e140h)		;5837   ; el fondo se congela mientras el gigante esta en pantalla
	and 003h		;583a
	cp 002h		;583c
	ret z			;583e
	ld a,(0e003h)		;583f   ; solo uno de cada 16 fotogramas
	and 00fh		;5842
	ret nz			;5844
	ld hl,0e1b9h		;5845   ; 0xE1B8/B9 es la posicion en la fase
	ld d,(hl)			;5848
	dec hl			;5849
	ld e,(hl)			;584a
	ld a,e			;584b   ; al desbordar el byte bajo de la posicion, suma una escena
	inc a			;584c
	call z,SUBE_ESCENA		;584d
	inc de			;5850   ; una fila mas de fase
	ex de,hl			;5851
	ld bc,00780h		;5852   ; la fase mide 0x780 filas; al pasarse vuelve a cero y sube la dificultad
	and a			;5855
	push hl			;5856
	sbc hl,bc		;5857
	pop hl			;5859
	jr c,GUARDA_POSICION		;585a
	ld hl,00000h		;585c   ; pasado el final, vuelta a la fila cero
	ld a,(0e1d3h)		;585f   ; y una vuelta mas de dificultad...
	inc a			;5862
	cp 002h		;5863   ; ...que topa en 2: de la tercera vuelta en adelante ya no sube
	jr c,VUELTA_A_LA_FASE		;5865
	ld a,002h		;5867
VUELTA_A_LA_FASE:		; La fase vuelve a empezar y sube la dificultad
	ld (0e1d3h),a		;5869
	call SUBE_ESCENA		;586c   ; la vuelta cuenta como escena nueva
GUARDA_POSICION:		; Deja la posicion y el desplazamiento fino
	ex de,hl			;586f   ; posicion nueva
	ld (hl),e			;5870
	inc hl			;5871
	ld (hl),d			;5872
	inc hl			;5873
	ld a,(hl)			;5874   ; 0xE1BA es el desplazamiento fino: 0,2,4...14, o sea 2*(posicion y 7)
	add a,002h		;5875
	cp 010h		;5877   ; pasado el 14 vuelve a cero, que es cuando se cambia de tira
	jr c,GUARDA_FINO		;5879
	xor a			;587b
GUARDA_FINO:		; Deja el desplazamiento fino, de 0 a 14
	ld (hl),a			;587c
	dec hl			;587d
	ld d,(hl)			;587e   ; y ahora se recupera la posicion entera para partirla entre ocho
	dec hl			;587f
	ld a,(hl)			;5880
DIVIDE_ENTRE_OCHO:		; De la posicion saca el indice del mapa
	srl d		;5881   ; el indice del mapa es la posicion dividida entre ocho
	rra			;5883
	srl d		;5884
	rra			;5886
	srl d		;5887
	rra			;5889
	ld (0e1d1h),a		;588a   ; 0xE1D1 se queda el indice del mapa
	ld e,a			;588d
	ld hl,058ffh		;588e   ; cuatro codigos de tira, guardados de 0xE1BE hacia abajo
	add hl,de			;5891
	ld de,0e1beh		;5892   ; cuatro codigos, guardados de 0xE1BE hacia abajo
	ld (0e310h),de		;5895
	ld b,004h		;5899   ; con cuatro tiras sobran para llenar las 24 filas
COPIA_CODIGOS:		; Los cuatro codigos de tira, de 0xE1BE hacia abajo
	ld a,(hl)			;589b   ; el mapa se lee hacia delante y se guarda hacia atras
	ld (de),a			;589c
	inc hl			;589d
	dec de			;589e
	djnz COPIA_CODIGOS		;589f
	call SIGUIENTE_TIRA		;58a1   ; la primera tira, la de mas abajo
	exx			;58a4
	ld b,018h		;58a5   ; 24 filas de pantalla
	exx			;58a7
	ld a,(0e1bah)		;58a8   ; el desplazamiento fino elige cual de las ocho copias de la tira se usa
	call LEE_PUNTERO		;58ab
	ld hl,03ae1h		;58ae   ; empieza por la fila de ABAJO, 0x3AE1, y va subiendo
	ld a,(00006h)		;58b1   ; 0x0006 tiene el puerto de datos del VDP
	ld c,a			;58b4
FILA_NUEVA:		; Prepara el VDP para escribir esta fila
	call PREPARA_ESCRITURA		;58b5
TIRA_PASO:		; Un byte de mando del guion de la tira
	ld a,(de)			;58b8   ; un byte de mando del guion de la tira
	inc de			;58b9
	ld b,a			;58ba
	and a			;58bb
	jp p,TIRA_MIRA_FIN		;58bc   ; sin el bit 7 es un cero (fin de fila) o una repeticion
	inc a			;58bf   ; 0xFF acaba la tira
	jr z,CAMBIA_DE_TIRA		;58c0
	res 7,b		;58c2   ; y el resto es copiar (n y 0x7F) celdas tal cual
TIRA_COPIA:		; Copia B celdas tal cual
	ld a,(de)			;58c4   ; las celdas van derechas al puerto
	out (c),a		;58c5
	inc de			;58c7
	djnz TIRA_COPIA		;58c8
	jr TIRA_PASO		;58ca
TIRA_MIRA_FIN:		; Un cero acaba la fila
	jr z,SUBE_UNA_FILA		;58cc   ; el cero cierra la fila y sube una
	ld a,(de)			;58ce
	inc de			;58cf
TIRA_REPITE:		; Repite B veces la misma celda
	out (c),a		;58d0   ; la misma celda B veces, con el nop de respiro del VDP
	nop			;58d2
	djnz TIRA_REPITE		;58d3
	jr TIRA_PASO		;58d5
SUBE_UNA_FILA:		; Resta 0x20 a la direccion de VRAM: una fila mas arriba
	exx			;58d7   ; 24 filas y para
	dec b			;58d8
	ret z			;58d9
	exx			;58da
	ld a,l			;58db   ; 0x20 es una fila; restarlo sube una
	sub 020h		;58dc
	ld l,a			;58de
	jr nc,FILA_NUEVA		;58df
	dec h			;58e1
	jr FILA_NUEVA		;58e2
CAMBIA_DE_TIRA:		; Coge la siguiente tira del mapa, y eso cierra la fila
	push hl			;58e4   ; cambiar de tira tambien cierra la fila
	call SIGUIENTE_TIRA		;58e5
	ld e,(hl)			;58e8   ; y arranca el guion de la tira nueva
	inc hl			;58e9
	ld d,(hl)			;58ea
	pop hl			;58eb
	jr SUBE_UNA_FILA		;58ec
SIGUIENTE_TIRA:		; Coge el siguiente codigo de tira y devuelve su subtabla
	ld hl,(0e310h)		;58ee   ; 0xE310 lleva el puntero al codigo de tira que toca
	ld a,(hl)			;58f1
	dec hl			;58f2   ; y va bajando: los codigos se guardaron del reves
	ld (0e310h),hl		;58f3
	add a,a			;58f6   ; dos bytes por tipo de tira
	ld hl,059f3h		;58f7   ; 0x59F3 son los veinte punteros, uno por tipo
	call LEE_PUNTERO		;58fa
	ex de,hl			;58fd
	ret			;58fe

; ----------------------------------------------------------------------
; DATOS mapa_de_la_fase: EL MAPA: 244 codigos de tira (0 a 19), uno por cada
;   ocho filas de la fase
;   0x58ff..0x59f3  (244 bytes)
DATA_mapa_de_la_fase:
	defb 011h,00dh,00ch,009h,009h,00ah,009h,009h,00ah,009h,00ah,009h,00ah,009h,009h,00ah	; 58ff  ................
	defb 009h,00ah,009h,009h,00ah,009h,00ah,009h,009h,00ah,009h,00ah,009h,009h,00bh,003h	; 590f  ................
	defb 005h,004h,003h,005h,004h,003h,004h,005h,004h,003h,005h,004h,003h,005h,004h,003h	; 591f  ................
	defb 004h,003h,005h,004h,003h,005h,004h,003h,004h,003h,005h,004h,003h,004h,005h,00eh	; 592f  ................
	defb 011h,011h,011h,011h,011h,011h,011h,011h,011h,011h,012h,011h,011h,011h,011h,011h	; 593f  ................
	defb 00dh,00ch,009h,00ah,009h,009h,00ah,009h,00ah,009h,009h,00ah,009h,00ah,009h,009h	; 594f  ................
	defb 00ah,009h,00ah,009h,009h,00ah,009h,009h,00ah,009h,00ah,009h,009h,00ah,009h,00ah	; 595f  ................
	defb 009h,009h,00ah,009h,00ah,009h,00bh,00fh,011h,011h,011h,011h,011h,011h,011h,011h	; 596f  ................
	defb 011h,011h,011h,011h,011h,011h,011h,011h,011h,006h,007h,008h,007h,008h,007h,008h	; 597f  ................
	defb 007h,008h,007h,008h,007h,008h,007h,008h,007h,008h,007h,008h,007h,008h,010h,011h	; 598f  ................
	defb 011h,011h,011h,011h,011h,011h,011h,011h,011h,011h,011h,011h,011h,011h,011h,011h	; 599f  ................
	defb 011h,011h,011h,011h,011h,011h,011h,011h,011h,011h,011h,011h,011h,011h,011h,011h	; 59af  ................
	defb 000h,001h,001h,001h,001h,001h,001h,001h,001h,001h,001h,001h,001h,001h,001h,001h	; 59bf  ................
	defb 001h,001h,001h,001h,001h,001h,001h,001h,001h,001h,001h,001h,001h,002h,011h,011h	; 59cf  ................
	defb 011h,011h,011h,011h,011h,011h,011h,011h,011h,011h,013h,011h,011h,011h,011h,011h	; 59df  ................
	defb 011h,00dh,00ch,009h	; 59ef

; ----------------------------------------------------------------------
; DATOS tabla_tipos_de_tira: Un puntero por tipo de tira (20), a su subtabla
;   de ocho variantes
;   0x59f3..0x5a1b  (40 bytes)
DATA_tabla_tipos_de_tira:
	defw 05a1bh,05a2bh,05a3bh,05a4bh	; 59f3  -> DATA_subtablas_de_tira 0x5a2b 0x5a3b 0x5a4b
	defw 05a5bh,05a6bh,05a7bh,05a8bh	; 59fb
	defw 05a9bh,05aabh,05abbh,05acbh	; 5a03
	defw 05adbh,05aebh,05afbh,05b0bh	; 5a0b
	defw 05b1bh,05b2bh,05b3bh,05b4bh	; 5a13

; ----------------------------------------------------------------------
; DATOS subtablas_de_tira: Veinte subtablas de ocho punteros: la misma tira
;   empezada 0 a 7 filas mas abajo
;   0x5a1b..0x5b5b  (320 bytes)
DATA_subtablas_de_tira:
	defw 05b5bh,05b69h,05b74h,05b87h,05b98h,05bb0h,05bc6h,05bdfh	; 5a1b
	defw 05bf8h,05c11h,05c2ah,05c43h,05c5ch,05c75h,05c8eh,05ca7h	; 5a2b
	defw 05cc0h,05cd9h,05cf2h,05d0bh,05d24h,05d3dh,05d4ah,05d54h	; 5a3b
	defw 05d57h,05d65h,05d73h,05d87h,05d96h,05da3h,05db0h,05dc1h	; 5a4b
	defw 05dd2h,05ddfh,05dedh,05dfch,05e09h,05e1bh,05e2ch,05e39h	; 5a5b
	defw 05e49h,05e57h,05e67h,05e77h,05e8ch,05e9dh,05eb0h,05ec0h	; 5a6b
	defw 05ecfh,05ed6h,05eddh,05eech,05effh,05f0ch,05f21h,05f30h	; 5a7b
	defw 05f45h,05f57h,05f6ch,05f78h,05f89h,05f99h,05fa5h,05fafh	; 5a8b
	defw 05fbah,05fc5h,05fdeh,05fefh,06006h,0601ah,06031h,0603fh	; 5a9b
	defw 06042h,06050h,06069h,06082h,0609bh,060b4h,060cdh,060e6h	; 5aab
	defw 060ffh,0610fh,06128h,06141h,0615ah,06173h,0618ch,061a5h	; 5abb
	defw 061bah,061c5h,061deh,061f7h,0620dh,06224h,0623dh,06252h	; 5acb
	defw 0625dh,06264h,0626bh,06273h,06280h,06294h,062a9h,062bfh	; 5adb
	defw 062d8h,062e1h,062ech,062f6h,06301h,0630fh,0631ch,06328h	; 5aeb
	defw 0632dh,0633fh,0634fh,06363h,06375h,0638ah,0639dh,063a7h	; 5afb
	defw 063afh,063b2h,063b5h,063b8h,063c3h,063cch,063d9h,063dch	; 5b0b
	defw 063dfh,063e6h,063f5h,063fch,0640bh,06414h,06421h,06424h	; 5b1b
	defw 06427h,06432h,06440h,0644bh,06457h,06464h,0646eh,06479h	; 5b2b
	defw 06489h,06496h,064afh,064c2h,064d8h,064f0h,06503h,06514h	; 5b3b
	defw 06527h,0653bh,06554h,0656dh,06586h,0659fh,065b8h,065d1h	; 5b4b

; ----------------------------------------------------------------------
; DATOS guiones_de_tira: Los 160 guiones comprimidos del fondo: 0x00 acaba
;   fila, el bit 7 copia tal cual, de 1 a 0x7F repite, 0xFF acaba la tira
;   0x5b5b..0x65e0  (2693 bytes)
DATA_guiones_de_tira:
	defb 082h,00bh,04ch,004h,005h,083h,04ah,00bh,04ch,00dh,005h,001h,04ah,000h,00ch,00bh	; 5b5b  ..L...J.L...J...
	defb 081h,04ch,005h,005h,081h,04ah,004h,00bh,000h,005h,00bh,083h,046h,00ch,048h,005h	; 5b6b  .L...J......F.H.
	defb 00bh,084h,04ch,005h,005h,04ah,004h,00bh,082h,046h,00ch,000h,004h,00bh,086h,046h	; 5b7b  ..L..J...F.....F
	defb 00ch,043h,045h,00ch,048h,009h,00bh,084h,046h,00ch,044h,045h,000h,08eh,00bh,00bh	; 5b8b  .CE.H...F.DE....
	defb 046h,00ch,042h,041h,045h,040h,00ch,042h,041h,043h,00ch,048h,004h,00bh,085h,046h	; 5b9b  F.BAE@.BAC.H...F
	defb 00ch,045h,041h,042h,000h,08dh,00bh,00bh,00ch,044h,045h,043h,040h,044h,045h,041h	; 5bab  .EAB.....DEC@DEA
	defb 044h,045h,041h,006h,00ch,084h,043h,041h,045h,041h,000h,097h,00bh,046h,00ch,045h	; 5bbb  DEA...CAEA...F.E
	defb 00ch,045h,042h,044h,045h,041h,045h,040h,00ch,040h,00ch,044h,043h,041h,00ch,040h	; 5bcb  .EBDEAE@.@.DCA.@
	defb 00ch,040h,042h,000h,097h,046h,00ch,042h,043h,044h,00ch,041h,040h,040h,045h,041h	; 5bdb  .@B..F.BCD.A@@EA
	defb 044h,045h,041h,041h,043h,040h,045h,041h,045h,041h,045h,041h,0ffh,097h,041h,043h	; 5beb  DEAAC@EAEAEA..AC
	defb 041h,043h,045h,040h,043h,040h,045h,040h,00ch,040h,040h,045h,040h,042h,045h,040h	; 5bfb  ACE@C@E@.@@E@BE@
	defb 040h,045h,040h,042h,041h,000h,097h,00ch,044h,043h,040h,040h,041h,044h,043h,041h	; 5c0b  @E@BA...DC@@ADCA
	defb 041h,045h,041h,041h,044h,043h,044h,042h,044h,041h,043h,041h,044h,045h,000h,097h	; 5c1b  AEAADCDBDACADE..
	defb 040h,045h,040h,041h,041h,044h,043h,045h,040h,041h,040h,042h,044h,043h,045h,044h	; 5c2b  @E@AADCE@A@BDCED
	defb 00ch,042h,045h,041h,044h,045h,041h,000h,097h,041h,041h,040h,043h,042h,041h,045h	; 5c3b  .BEADEA..AA@CBAE
	defb 00ch,041h,045h,041h,044h,043h,045h,042h,044h,045h,041h,043h,045h,041h,045h,042h	; 5c4b  .AEADCEBDEACEAEB
	defb 000h,097h,040h,00ch,043h,041h,044h,045h,041h,045h,040h,041h,044h,045h,040h,041h	; 5c5b  ..@.CADEAE@ADE@A
	defb 045h,041h,045h,040h,045h,041h,045h,041h,044h,000h,097h,045h,040h,045h,043h,044h	; 5c6b  EAE@EAEAD..E@ECD
	defb 00ch,042h,045h,041h,044h,041h,045h,040h,042h,00ch,045h,041h,044h,041h,040h,040h	; 5c7b  .BEADAE@B.EADA@@
	defb 042h,042h,000h,097h,041h,045h,00ch,042h,044h,045h,041h,043h,045h,041h,045h,041h	; 5c8b  BB..AE.BDEACEAEA
	defb 045h,040h,00ch,040h,042h,041h,00ch,043h,041h,041h,040h,000h,097h,00ch,040h,041h	; 5c9b  E@.@BA.CAA@...@A
	defb 045h,041h,045h,040h,045h,041h,045h,040h,042h,041h,045h,045h,041h,041h,044h,045h	; 5cab  EAE@EAE@BAEEAADE
	defb 044h,045h,041h,045h,0ffh,097h,00bh,047h,040h,041h,045h,041h,044h,041h,040h,040h	; 5cbb  DEAE...G@AEADA@@
	defb 045h,042h,044h,00ch,042h,045h,041h,042h,045h,044h,00ch,042h,045h,000h,097h,04bh	; 5ccb  EBD.BEABED.BE..K
	defb 00bh,00ch,040h,040h,042h,041h,00ch,043h,041h,045h,041h,044h,045h,041h,043h,040h	; 5cdb  ..@@BA.CAEADEAC@
	defb 045h,041h,044h,045h,041h,043h,000h,097h,005h,00bh,047h,00ch,040h,041h,044h,045h	; 5ceb  EADEAC....G.@ADE
	defb 044h,00ch,00ch,00ch,040h,045h,040h,045h,041h,041h,045h,041h,045h,040h,044h,000h	; 5cfb  D...@E@EAAEAE@D.
	defb 097h,005h,04bh,00bh,00bh,047h,00ch,00ch,00ch,049h,00bh,00bh,00bh,047h,00ch,044h	; 5d0b  ..K..G...I...G.D
	defb 041h,040h,042h,044h,045h,041h,043h,00ch,000h,097h,005h,005h,005h,04bh,00bh,00bh	; 5d1b  A@BDEAC......K..
	defb 00bh,00bh,00bh,04dh,005h,005h,04bh,00bh,00bh,047h,00ch,00ch,040h,045h,043h,00ch	; 5d2b  ...M..K..G..@EC.
	defb 049h,000h,00eh,005h,089h,04bh,00bh,00bh,047h,00ch,00ch,049h,00bh,00bh,000h,00fh	; 5d3b  I....K..G..I....
	defb 005h,081h,04bh,005h,00bh,082h,04dh,005h,000h,017h,005h,0ffh,005h,009h,088h,04fh	; 5d4b  ..K...M........O
	defb 008h,006h,060h,006h,006h,057h,008h,00ah,009h,000h,005h,009h,088h,008h,053h,006h	; 5d5b  ..`..W........S.
	defb 056h,006h,057h,008h,051h,00ah,009h,000h,08ch,009h,009h,052h,009h,04fh,008h,006h	; 5d6b  V.W.Q......R.O..
	defb 056h,006h,057h,008h,051h,005h,009h,081h,052h,005h,009h,000h,004h,009h,087h,008h	; 5d7b  V.W.Q...R.......
	defb 053h,05dh,05ah,006h,055h,051h,00bh,009h,081h,052h,000h,004h,009h,087h,008h,006h	; 5d8b  S]Z.UQ...R......
	defb 05eh,05ah,006h,055h,050h,00ch,009h,000h,004h,009h,087h,04eh,054h,05eh,059h,006h	; 5d9b  ^Z.UP......NT^Y.
	defb 061h,008h,00ch,009h,000h,005h,009h,087h,008h,006h,05eh,05ah,006h,061h,050h,004h	; 5dab  a.........^Z.aP.
	defb 009h,081h,052h,006h,009h,000h,08dh,009h,009h,052h,009h,009h,04eh,054h,05ch,05ah	; 5dbb  ..R......R..NT\Z
	defb 006h,006h,061h,050h,00ah,009h,0ffh,006h,009h,087h,008h,006h,05eh,059h,006h,057h	; 5dcb  ..aP........^Y.W
	defb 008h,00ah,009h,000h,006h,009h,088h,04eh,054h,006h,05fh,059h,061h,008h,050h,009h	; 5ddb  .......NT._Ya.P.
	defb 009h,000h,005h,009h,089h,052h,009h,008h,054h,05eh,05eh,05ah,061h,008h,009h,009h	; 5deb  .....R..T^^Za...
	defb 000h,007h,009h,087h,04eh,008h,006h,05eh,05ah,006h,055h,009h,009h,000h,007h,009h	; 5dfb  ....N..^Z.U.....
	defb 087h,04fh,053h,006h,060h,05ah,057h,051h,005h,009h,084h,052h,009h,009h,009h,000h	; 5e0b  .OS.`ZWQ...R....
	defb 08dh,009h,009h,009h,052h,009h,009h,04fh,008h,006h,056h,006h,057h,008h,00ah,009h	; 5e1b  ....R..O..V.W...
	defb 000h,006h,009h,087h,008h,053h,006h,056h,006h,055h,051h,00ah,009h,000h,006h,009h	; 5e2b  .....S.V.UQ.....
	defb 08ah,008h,006h,056h,006h,006h,061h,050h,009h,009h,052h,007h,009h,0ffh,005h,009h	; 5e3b  ...V..aP..R.....
	defb 088h,04fh,053h,060h,05ah,006h,006h,057h,051h,00ah,009h,000h,08ch,009h,009h,009h	; 5e4b  .OS`Z..WQ.......
	defb 04fh,008h,053h,060h,006h,006h,006h,057h,051h,00bh,009h,000h,08ch,009h,009h,04fh	; 5e5b  O.S`...WQ......O
	defb 053h,006h,05dh,006h,006h,006h,006h,061h,050h,00bh,009h,000h,08ch,009h,009h,04eh	; 5e6b  S.]....aP......N
	defb 054h,05eh,059h,006h,006h,006h,006h,006h,055h,007h,009h,084h,052h,009h,009h,009h	; 5e7b  T^Y.....U...R...
	defb 000h,08dh,009h,009h,009h,04eh,054h,05ch,059h,05bh,006h,006h,006h,061h,050h,00ah	; 5e8b  .....NT\Y[...aP.
	defb 009h,000h,004h,009h,08dh,008h,054h,05fh,05eh,05ah,006h,006h,006h,055h,009h,009h	; 5e9b  ......T_^Z...U..
	defb 009h,052h,006h,009h,000h,004h,009h,08ah,04eh,008h,054h,05dh,059h,006h,006h,006h	; 5eab  .R......N.T]Y...
	defb 061h,050h,009h,009h,000h,005h,009h,089h,04eh,008h,006h,05ch,058h,006h,006h,057h	; 5ebb  aP......N..\X..W
	defb 051h,009h,009h,0ffh,012h,005h,081h,0a1h,004h,00ah,000h,00eh,005h,081h,0a1h,008h	; 5ecb  Q...............
	defb 00ah,000h,004h,00ah,081h,0a2h,007h,005h,081h,0a1h,004h,00ah,004h,06dh,002h,00ah	; 5edb  .............m..
	defb 000h,006h,00ah,085h,0a2h,005h,005h,005h,0a1h,005h,00ah,087h,062h,071h,069h,069h	; 5eeb  ............bqii
	defb 070h,06eh,00ah,000h,081h,06fh,00fh,00ah,087h,062h,066h,071h,070h,065h,06eh,00ah	; 5efb  pn...o...bfqpen.
	defb 000h,089h,00ah,00ah,06bh,00ah,00ah,06fh,00ah,00ah,06bh,007h,00ah,087h,062h,066h	; 5f0b  ....k..o..k...bf
	defb 064h,067h,065h,06eh,00ah,000h,00ah,00ah,081h,06fh,005h,00ah,087h,062h,064h,068h	; 5f1b  dgen.....o...bdh
	defb 068h,067h,06eh,00ah,000h,08ch,06fh,00ah,06fh,00ah,00ah,06fh,00ah,06bh,00ah,00ah	; 5f2b  hgn...o.o..o.k..
	defb 00ah,06bh,005h,00ah,004h,063h,082h,00ah,00ah,0ffh,08ah,00ah,00ah,00ah,06fh,00ah	; 5f3b  .k...c........o.
	defb 00ah,00ah,06fh,00ah,06fh,004h,00ah,002h,06fh,007h,00ah,000h,005h,00ah,085h,06fh	; 5f4b  ..o.o...o......o
	defb 00ah,00ah,00ah,06fh,004h,00ah,089h,06fh,00ah,00ah,00ah,06fh,00ah,00ah,00ah,06fh	; 5f5b  ...o...o...o...o
	defb 000h,083h,00ah,00ah,06fh,005h,00ah,082h,06dh,06dh,00dh,00ah,000h,007h,00ah,084h	; 5f6b  ....o...mm......
	defb 062h,071h,070h,06eh,005h,00ah,081h,06ch,004h,00ah,082h,06fh,00ah,000h,004h,00ah	; 5f7b  bqpn...l...o....
	defb 08ah,06fh,00ah,00ah,062h,064h,067h,06eh,00ah,00ah,06ch,009h,00ah,000h,008h,00ah	; 5f8b  .o..bdgn..l.....
	defb 082h,063h,063h,007h,00ah,081h,06ch,005h,00ah,000h,086h,00ah,06fh,00ah,00ah,00ah	; 5f9b  .cc...l.....o...
	defb 06fh,011h,00ah,000h,010h,00ah,087h,06ch,00ah,00ah,00ah,06fh,00ah,00ah,0ffh,002h	; 5fab  o......l...o....
	defb 00ah,004h,06dh,006h,00ah,081h,06fh,00ah,00ah,000h,097h,00ah,062h,071h,069h,069h	; 5fbb  ..m...o.....bqii
	defb 070h,06eh,00ah,00ah,00ah,00ah,06fh,00ah,00ah,06ch,00ah,06fh,00ah,06fh,00ah,00ah	; 5fcb  pn....o..l.o.o..
	defb 06fh,00ah,000h,087h,00ah,062h,066h,071h,070h,065h,06eh,00bh,00ah,085h,06fh,00ah	; 5fdb  o....bfqpen...o.
	defb 00ah,00ah,06fh,000h,087h,00ah,062h,066h,064h,067h,065h,06eh,005h,00ah,08bh,06dh	; 5feb  ..o...bfdgen...m
	defb 06dh,00ah,00ah,06ch,00ah,06ch,00ah,06fh,00ah,06fh,000h,090h,00ah,062h,064h,068h	; 5ffb  m..l.l.o.o...bdh
	defb 068h,067h,06eh,00ah,00ah,06fh,00ah,062h,071h,070h,06eh,06fh,007h,00ah,000h,002h	; 600b  hgn..o.bqpno....
	defb 00ah,004h,063h,091h,00ah,00ah,06fh,00ah,00ah,062h,064h,067h,06eh,00ah,06fh,00ah	; 601b  ..c...o..bdgn.o.
	defb 00ah,06fh,00ah,06fh,00ah,000h,00ch,00ah,002h,063h,003h,00ah,086h,06fh,00ah,00ah	; 602b  .o.o.....c...o..
	defb 06fh,00ah,06fh,000h,017h,00ah,0ffh,085h,005h,007h,088h,089h,086h,00eh,007h,084h	; 603b  o.o.............
	defb 08eh,007h,007h,007h,000h,097h,086h,007h,088h,089h,086h,007h,087h,088h,089h,08ch	; 604b  ................
	defb 089h,005h,089h,086h,089h,005h,007h,08dh,005h,088h,088h,089h,005h,000h,097h,007h	; 605b  ................
	defb 007h,08eh,007h,007h,007h,087h,088h,089h,08ah,087h,087h,089h,005h,089h,086h,08fh	; 606b  ................
	defb 08dh,08ch,08ch,08ch,087h,087h,000h,097h,089h,007h,086h,086h,087h,007h,005h,088h	; 607b  ................
	defb 089h,086h,08dh,086h,005h,086h,089h,005h,007h,086h,08ah,08ah,08ah,087h,086h,000h	; 608b  ................
	defb 097h,08dh,007h,086h,08ch,086h,007h,086h,087h,087h,087h,08dh,08dh,086h,08dh,08dh	; 609b  ................
	defb 005h,007h,086h,089h,086h,089h,005h,089h,000h,097h,005h,007h,08dh,08ah,086h,007h	; 60ab  ................
	defb 088h,089h,086h,086h,005h,08dh,087h,087h,089h,086h,007h,005h,088h,088h,089h,005h	; 60bb  ................
	defb 086h,000h,097h,087h,007h,088h,089h,086h,08fh,005h,088h,088h,089h,086h,087h,087h	; 60cb  ................
	defb 087h,089h,005h,007h,086h,088h,088h,089h,086h,005h,000h,097h,08dh,007h,08dh,088h	; 60db  ................
	defb 089h,007h,086h,005h,088h,088h,089h,005h,086h,005h,086h,086h,007h,086h,089h,086h	; 60eb  ................
	defb 086h,089h,086h,0ffh,085h,08dh,007h,08dh,088h,089h,007h,007h,081h,08eh,008h,007h	; 60fb  ................
	defb 082h,08eh,007h,000h,097h,087h,007h,08ch,08ch,08ch,007h,082h,083h,089h,087h,08ch	; 610b  ................
	defb 086h,088h,089h,086h,007h,086h,087h,087h,087h,005h,087h,087h,000h,097h,087h,08fh	; 611b  ................
	defb 08bh,08bh,08bh,007h,086h,082h,083h,089h,08ah,005h,088h,089h,086h,007h,086h,089h	; 612b  ................
	defb 086h,08dh,08dh,005h,089h,000h,097h,005h,007h,08bh,08bh,08bh,007h,089h,086h,082h	; 613b  ................
	defb 083h,089h,087h,087h,08dh,086h,007h,086h,086h,086h,005h,08dh,086h,089h,000h,097h	; 614b  ................
	defb 086h,007h,08ah,08ah,08ah,007h,089h,005h,089h,082h,083h,086h,086h,08dh,086h,007h	; 615b  ................
	defb 007h,007h,083h,086h,005h,08dh,005h,000h,097h,005h,007h,086h,08dh,086h,007h,086h	; 616b  ................
	defb 089h,08dh,08dh,082h,007h,007h,083h,086h,007h,086h,089h,082h,083h,086h,088h,089h	; 617b  ................
	defb 000h,097h,086h,007h,005h,08dh,086h,08fh,086h,089h,08dh,087h,087h,087h,086h,082h	; 618b  ................
	defb 083h,08fh,086h,089h,08dh,007h,086h,088h,089h,000h,006h,007h,091h,005h,086h,086h	; 619b  ................
	defb 087h,087h,08dh,08dh,086h,082h,007h,086h,087h,08dh,007h,08dh,087h,087h,0ffh,005h	; 61ab  ................
	defb 007h,081h,08eh,00ah,007h,081h,08eh,006h,007h,000h,097h,088h,089h,086h,086h,086h	; 61bb  ................
	defb 08dh,087h,007h,005h,086h,08dh,087h,089h,086h,007h,08dh,005h,089h,086h,08dh,084h	; 61cb  ................
	defb 085h,08dh,000h,097h,088h,088h,089h,087h,087h,08dh,08dh,007h,087h,087h,087h,086h	; 61db  ................
	defb 086h,086h,007h,086h,087h,08dh,086h,084h,085h,08dh,08dh,000h,08ch,088h,088h,089h	; 61eb  ................
	defb 086h,08dh,086h,007h,007h,08dh,007h,007h,08eh,006h,007h,085h,084h,085h,08dh,087h	; 61fb  ................
	defb 087h,000h,082h,007h,08eh,005h,007h,090h,082h,083h,007h,08dh,089h,086h,007h,086h	; 620b  ................
	defb 092h,005h,007h,08eh,007h,007h,007h,086h,000h,097h,007h,005h,092h,092h,092h,005h	; 621b  ................
	defb 007h,08dh,082h,007h,086h,089h,087h,007h,094h,009h,090h,092h,092h,092h,005h,007h	; 622b  ................
	defb 007h,000h,088h,092h,093h,009h,009h,009h,091h,007h,08eh,006h,007h,082h,094h,009h	; 623b  ................
	defb 004h,009h,083h,090h,092h,092h,000h,005h,009h,081h,090h,008h,092h,081h,093h,008h	; 624b  ................
	defb 009h,0ffh,00eh,00bh,081h,098h,008h,00bh,000h,00bh,00bh,081h,099h,00bh,00bh,000h	; 625b  ................
	defb 013h,00bh,084h,098h,00bh,00bh,00bh,000h,085h,095h,095h,096h,00bh,097h,009h,095h	; 626b  ................
	defb 081h,096h,008h,00bh,000h,088h,007h,007h,005h,095h,005h,007h,007h,08eh,006h,007h	; 627b  ................
	defb 081h,094h,005h,00bh,083h,097h,095h,095h,000h,081h,08dh,005h,007h,089h,086h,089h	; 628b  ................
	defb 08dh,08dh,005h,086h,086h,007h,005h,005h,095h,083h,086h,007h,007h,000h,090h,086h	; 629b  ................
	defb 007h,08dh,08dh,086h,08fh,086h,089h,08dh,087h,087h,087h,086h,007h,007h,08eh,006h	; 62ab  ................
	defb 007h,081h,089h,000h,097h,08dh,007h,087h,087h,087h,007h,005h,086h,086h,087h,087h	; 62bb  ................
	defb 08dh,08dh,007h,087h,087h,086h,08dh,08dh,086h,086h,087h,087h,0ffh,085h,005h,005h	; 62cb  ................
	defb 04ah,00bh,04ch,012h,005h,000h,087h,005h,04ah,00bh,00bh,00bh,00bh,04ch,010h,005h	; 62db  J.L.....J....L..
	defb 000h,00ah,00bh,081h,04ch,00ah,005h,082h,04ah,00bh,000h,00ch,00bh,081h,04ch,007h	; 62eb  ....L...J.....L.
	defb 005h,083h,04ah,00bh,00bh,000h,083h,00bh,097h,096h,00bh,00bh,084h,04ch,005h,005h	; 62fb  ..J..........L..
	defb 04ah,005h,00bh,000h,089h,00bh,091h,08dh,096h,00bh,00bh,098h,00bh,099h,00eh,00bh	; 630b  J...............
	defb 000h,088h,099h,090h,092h,093h,00bh,098h,00bh,099h,00fh,00bh,000h,004h,099h,013h	; 631b  ................
	defb 00bh,0ffh,006h,009h,088h,008h,053h,006h,060h,006h,060h,059h,09ch,004h,009h,081h	; 632b  ......S.`.`Y....
	defb 052h,004h,009h,000h,006h,009h,08ah,008h,006h,05eh,058h,057h,054h,060h,059h,09ch	; 633b  R........^XWT`Y.
	defb 009h,007h,009h,000h,006h,009h,08bh,008h,006h,05ch,058h,055h,008h,054h,05ch,05eh	; 634b  .........\XU.T\^
	defb 059h,09ch,004h,009h,082h,052h,009h,000h,006h,009h,08ch,04eh,054h,006h,05eh,061h	; 635b  Y....R.....NT.^a
	defb 050h,04eh,008h,054h,05eh,059h,09ch,005h,009h,000h,004h,009h,08fh,052h,009h,009h	; 636b  PN.T^Y.......R..
	defb 04eh,054h,05dh,059h,051h,009h,009h,04eh,054h,060h,005h,09ah,004h,009h,000h,008h	; 637b  NT]YQ..NT`......
	defb 009h,08fh,04eh,054h,060h,09ah,009h,052h,009h,09bh,005h,005h,005h,09ah,009h,009h	; 638b  ..NT`..R........
	defb 009h,000h,006h,009h,081h,09bh,00eh,005h,082h,09ah,009h,000h,082h,009h,09bh,014h	; 639b  ................
	defb 005h,081h,09ah,0ffh,017h,009h,000h,017h,009h,000h,017h,009h,000h,083h,009h,009h	; 63ab  ................
	defb 09eh,004h,005h,081h,09dh,00fh,009h,000h,081h,09eh,008h,005h,081h,09dh,00dh,009h	; 63bb  ................
	defb 000h,00ch,005h,081h,09dh,005h,009h,085h,09eh,005h,005h,09dh,009h,000h,017h,005h	; 63cb  ................
	defb 000h,017h,005h,0ffh,00eh,00ah,081h,06fh,008h,00ah,000h,082h,00ah,06fh,006h,00ah	; 63db  .......o.....o..
	defb 081h,06fh,00ah,00ah,084h,06fh,00ah,00ah,00ah,000h,011h,00ah,081h,06fh,005h,00ah	; 63eb  .o...o.......o..
	defb 000h,083h,00ah,00ah,0a0h,004h,005h,081h,09fh,004h,00ah,081h,06fh,00ah,00ah,000h	; 63fb  ............o...
	defb 081h,0a0h,008h,005h,081h,09fh,00dh,00ah,000h,00ch,005h,081h,09fh,005h,00ah,085h	; 640b  ................
	defb 0a0h,005h,005h,09fh,00ah,000h,017h,005h,000h,017h,005h,0ffh,006h,005h,081h,0a3h	; 641b  ................
	defb 007h,005h,081h,0a3h,008h,005h,000h,009h,005h,081h,0a3h,007h,005h,086h,0a3h,005h	; 642b  ................
	defb 005h,005h,0a3h,005h,000h,081h,0a3h,00bh,005h,081h,0a3h,009h,005h,081h,0a3h,000h	; 643b  ................
	defb 009h,005h,081h,0a3h,009h,005h,084h,0a3h,005h,005h,005h,000h,085h,0a3h,005h,005h	; 644b  ................
	defb 005h,0a3h,009h,005h,081h,0a3h,008h,005h,000h,00dh,005h,081h,0a3h,007h,005h,082h	; 645b  ................
	defb 0a3h,005h,000h,006h,005h,081h,0a3h,00bh,005h,081h,0a3h,004h,005h,000h,084h,005h	; 646b  ................
	defb 005h,005h,0a3h,007h,005h,085h,0a3h,005h,005h,005h,0a3h,007h,005h,0ffh,008h,005h	; 647b  ................
	defb 087h,0b1h,0d9h,0d5h,0d6h,0d9h,0ech,0b4h,008h,005h,000h,097h,005h,005h,0a3h,005h	; 648b  ................
	defb 005h,005h,005h,0b1h,0b6h,0c1h,0ddh,0deh,0c2h,0bdh,0ech,0b4h,005h,0a3h,005h,005h	; 649b  ................
	defb 0a3h,005h,005h,000h,005h,005h,08bh,0a3h,005h,00fh,0b9h,0b2h,0e5h,0e6h,0b2h,0c0h	; 64ab  ................
	defb 0dah,004h,006h,005h,081h,0a3h,000h,081h,0a3h,006h,005h,090h,0d3h,0e0h,0bbh,0c7h	; 64bb  ................
	defb 0c8h,0e4h,0e1h,0d7h,004h,005h,005h,005h,0a3h,005h,005h,005h,000h,090h,005h,005h	; 64cb  ................
	defb 005h,0a3h,005h,005h,005h,0d4h,0dfh,0e3h,0c5h,0c6h,0c3h,0c4h,0d8h,004h,004h,005h	; 64db  ................
	defb 083h,0a3h,005h,005h,000h,007h,005h,089h,00fh,0b8h,0b2h,0e2h,0bah,0b2h,0bfh,0dah	; 64eb  ................
	defb 004h,004h,005h,083h,0a3h,005h,005h,000h,005h,005h,08bh,0a3h,005h,0b0h,0b5h,0beh	; 64fb  ................
	defb 0dbh,0dch,0b7h,0bch,0ebh,0b3h,007h,005h,000h,08fh,005h,005h,0a3h,005h,005h,005h	; 650b  ................
	defb 005h,005h,0b0h,00fh,0d1h,0d2h,00fh,0ebh,0b3h,008h,005h,0ffh,088h,005h,005h,0b6h	; 651b  ................
	defb 0b7h,001h,0bfh,0c1h,0dah,008h,005h,087h,0b6h,0b7h,001h,0bfh,0c1h,0dah,005h,000h	; 652b  ................
	defb 097h,005h,0b5h,0d1h,0d3h,001h,0d4h,0d2h,0c0h,0dch,005h,005h,0a3h,005h,0a3h,005h	; 653b  ................
	defb 0b5h,0d1h,0d3h,001h,0d4h,0d2h,0c0h,0dch,000h,097h,005h,0b3h,0cfh,0c6h,0b9h,0c7h	; 654b  ................
	defb 0d0h,0b4h,0d9h,0eah,0ebh,0ebh,0ebh,0eah,0e6h,0b3h,0cfh,0c6h,0b9h,0c7h,0d0h,0b4h	; 655b  ................
	defb 0e8h,000h,097h,005h,001h,001h,0bah,0deh,0bbh,001h,001h,001h,0dfh,0e2h,0e9h,0e2h	; 656b  ................
	defb 0e0h,001h,001h,001h,0bah,0deh,0bbh,001h,001h,004h,000h,097h,005h,0b2h,0cdh,0c4h	; 657b  ................
	defb 0b8h,0c5h,0ceh,0beh,0d7h,0d6h,0d6h,0d6h,0d6h,0d6h,0d8h,0b2h,0cdh,0c4h,0b8h,0c5h	; 658b  ................
	defb 0ceh,0beh,0e7h,000h,097h,005h,0b1h,0c9h,0cah,001h,0cbh,0cch,0bdh,0ddh,0a3h,005h	; 659b  ................
	defb 005h,005h,005h,005h,0b1h,0c9h,0cah,001h,0cbh,0cch,0bdh,0ddh,000h,097h,005h,005h	; 65ab  ................
	defb 0b0h,0c2h,0c8h,0c3h,0bch,0dbh,005h,005h,005h,005h,005h,005h,005h,005h,0b0h,0c2h	; 65bb  ................
	defb 0c8h,0c3h,0bch,0dbh,005h,000h,083h,005h,005h,0a3h,007h,005h,085h,0a3h,005h,005h	; 65cb  ................
	defb 005h,0a3h,008h,005h,0ffh	; 65db

; ======================================================================
; CODIGO 0x65e0..0x68f3  (787 bytes)
; ======================================================================


PASO_DISPAROS_MUEVE:		; Mueve los nueve disparos enemigos
	ld hl,0e270h		;65e0   ; los nueve disparos enemigos viven en 0xE270, 16 bytes cada uno
	ld b,009h		;65e3
DISPARO_PASO:		; Un disparo: suma su velocidad de 16 bits
	ld (0e310h),hl		;65e5
	ld a,(hl)			;65e8   ; byte +0 a cero: disparo apagado
	and a			;65e9
	jr z,DISPARO_SIGUIENTE		;65ea
	exx			;65ec
	ld bc,008a8h		;65ed   ; topes de la columna: de 8 a 0xB0
	cp 002h		;65f0   ; el disparo de tipo 2 (el que sale de un objeto) usa una franja mas estrecha
	jr nz,DISPARO_TOPES		;65f2
	ld bc,01490h		;65f4
DISPARO_TOPES:		; Los topes cambian si el disparo es del tipo 2
	exx			;65f7
	inc a			;65f8   ; el tipo 0xFF no se mueve solo: lo recoloca su objeto cada fotograma
	jr z,DISPARO_SIGUIENTE		;65f9
	inc l			;65fb   ; HL a las velocidades (+1) y DE a las posiciones (+5)
	ld e,l			;65fc
	ld d,h			;65fd
	inc e			;65fe
	inc e			;65ff
	inc e			;6600
	inc e			;6601
	ld a,(de)			;6602
	add a,(hl)			;6603   ; bytes +5/+6: la fila, en 16 bits
	ld (de),a			;6604
	inc l			;6605
	inc e			;6606
	ld a,(de)			;6607
	adc a,(hl)			;6608
	ld (de),a			;6609
	cp 0c0h		;660a   ; pasada la fila 0xC0 el disparo se ha ido por abajo
	call nc,APAGA_DISPARO		;660c
	inc l			;660f
	inc e			;6610
	ld a,(de)			;6611
	add a,(hl)			;6612   ; bytes +7/+8: la columna
	ld (de),a			;6613
	inc l			;6614
	inc de			;6615
	ld a,(de)			;6616
	adc a,(hl)			;6617
	ld (de),a			;6618
	exx			;6619
	sub b			;661a   ; fuera de la franja, se apaga
	cp c			;661b
	exx			;661c
	call nc,APAGA_DISPARO		;661d
DISPARO_SIGUIENTE:		; Salta al disparo siguiente
	ld hl,(0e310h)		;6620
	ld de,00010h		;6623   ; 16 bytes por disparo
	add hl,de			;6626
	djnz DISPARO_PASO		;6627
	ret			;6629
APAGA_DISPARO:		; Vacia el disparo y apaga su ficha de sprite
	exx			;662a
	ld hl,(0e310h)		;662b
	ld (hl),000h		;662e   ; byte +0 a cero: el hueco de disparo queda libre
	ld a,l			;6630   ; del hueco saca su ficha: 0xE10C es la ficha 23, la primera de los disparos
	sub 070h		;6631
	rra			;6633
	rra			;6634
	and 03ch		;6635
	ld hl,0e10ch		;6637
	call SUMA_A_HL		;663a
	ld (hl),0c3h		;663d   ; fila 0xC3: la ficha se va de la pantalla
	exx			;663f
	ret			;6640
PASO_DISPAROS:		; Un paso de los disparos enemigos
	ld hl,0e270h		;6641   ; los nueve disparos a sus nueve fichas
	ld de,0e10ch		;6644
	ld b,009h		;6647
DISPARO_A_SPRITES:		; Vuelca un disparo a su ficha
	ld a,(hl)			;6649   ; disparo apagado, ficha sin tocar
	and a			;664a
	jr z,DISPARO_VACIO		;664b
	ld a,006h		;664d   ; de +0 a +6: la fila
	add a,l			;664f
	ld l,a			;6650
	ld a,(hl)			;6651
	ld (de),a			;6652
	inc l			;6653
	inc l			;6654
	inc de			;6655
	ld a,(hl)			;6656   ; +8 la columna, +9 el patron y +10 el color
	ld (de),a			;6657
	inc l			;6658
	inc de			;6659
	ld a,(hl)			;665a
	ld (de),a			;665b
	inc l			;665c
	inc de			;665d
	ld a,(hl)			;665e
	ld (de),a			;665f
	inc de			;6660
	ld a,006h		;6661   ; seis bytes hasta el +0 del disparo siguiente
DISPARO_AVANZA:		; Suma A a L para pasar al disparo siguiente
	add a,l			;6663
	ld l,a			;6664
	djnz DISPARO_A_SPRITES		;6665
	ret			;6667
DISPARO_VACIO:		; Salta cuatro bytes de ficha y pasa al siguiente
	inc de			;6668   ; el hueco vacio se salta, pero la ficha se deja como estaba
	inc de			;6669
	inc de			;666a
	inc de			;666b
	ld a,010h		;666c   ; y son 16 bytes de salto, no 6
	jr DISPARO_AVANZA		;666e
REPARTE_CADA_60:		; Cada 60 fotogramas reparte un disparo mas
	ld hl,0e1c1h		;6670   ; 0xE1C1 cuenta los 60 fotogramas
	dec (hl)			;6673
	ret nz			;6674
	ld (hl),03ch		;6675   ; y se recarga con 0x3C
	exx			;6677
	ld hl,0e1d2h		;6678   ; 0xE1D2 sube uno cada vez
	inc (hl)			;667b
REPARTE_CHOQUES:		; Recorre los huecos buscando quien puede disparar
	ld a,(hl)			;667c
	cp 013h		;667d   ; pasado el 19 ya no se reparte nada
	ret nc			;667f
	rra			;6680   ; el bit 0 decide entre las dos parejas de topes
	ld bc,0fe00h		;6681
	jr c,$+4		;6684   ; el jr c cae en el ultimo byte del ld bc de 0x6686, que se ejecuta como un inc bc: BC queda en 0xFE01 en vez de 0xFE00
	ld bc,00300h		;6686
	exx			;6689
	ld hl,0e200h		;668a   ; los siete huecos de objeto
	ld b,007h		;668d
REPARTE_HUECO:		; Mira si este hueco puede soltar el disparo
	push bc			;668f
	ld a,(hl)			;6690   ; hueco vacio, nada que soltar
	and a			;6691
	ld (0e310h),hl		;6692
	call nz,SUELTA_DISPARO		;6695
	ld hl,(0e310h)		;6698
	ld de,00010h		;669b   ; 16 bytes al siguiente
	add hl,de			;669e
	pop bc			;669f
	djnz REPARTE_HUECO		;66a0
	ret			;66a2
SUELTA_DISPARO:		; Monta un disparo enemigo desde este hueco
	inc hl			;66a3   ; byte +1: la rutina
	ld de,00800h		;66a4   ; 0x0800 es hacia abajo...
	ld a,(hl)			;66a7
	cp 00bh		;66a8
	jr nz,DISPARO_DESDE		;66aa
	ld de,0f800h		;66ac   ; ...y la rutina 0x0B dispara hacia arriba
DISPARO_DESDE:		; Coge la posicion del hueco que dispara
	ld a,008h		;66af   ; de +1 a +9: la fila
	add a,l			;66b1
	ld l,a			;66b2
	ld c,(hl)			;66b3
	inc hl			;66b4
	inc hl			;66b5
	ld b,(hl)			;66b6   ; y +11 la columna
	ld a,l			;66b7   ; el numero de hueco elige el hueco de disparo: el mismo numero
	and 0f0h		;66b8
	ld hl,0e270h		;66ba
	add a,l			;66bd
	ld l,a			;66be
	ld (hl),002h		;66bf   ; byte +0 a 2: disparo salido de un objeto
	inc hl			;66c1
	exx			;66c2
	ld a,c			;66c3
	exx			;66c4
	ld (hl),a			;66c5   ; bytes +1/+2: velocidad de fila, la que traia en BC prima
	inc hl			;66c6
	exx			;66c7
	ld a,b			;66c8
	exx			;66c9
	ld (hl),a			;66ca
	inc hl			;66cb
	ld (hl),e			;66cc   ; bytes +3/+4: velocidad de columna
	inc hl			;66cd
	ld (hl),d			;66ce
	inc hl			;66cf
	inc hl			;66d0
	ld (hl),c			;66d1   ; byte +6: la fila de salida
	inc hl			;66d2
	inc hl			;66d3
	ld (hl),b			;66d4   ; byte +8: la columna
	inc hl			;66d5
	ld (hl),088h		;66d6   ; patron 0x88 y color 15, que es el disparo enemigo
	inc hl			;66d8
	ld (hl),00fh		;66d9
	ret			;66db
REPONE_CUENTA:		; Repone la cuenta atras del hueco
	ld de,(0e310h)		;66dc   ; byte +0: el tipo del hueco
	ld a,(de)			;66e0
	cp 012h		;66e1   ; los tipos por debajo de 0x12 miran su tanda
	jr c,BUSCA_EN_LA_TANDA		;66e3
	ld a,(0e1d6h)		;66e5   ; el gigante 1 dispara mas despacio (0x20) que el 2 (0x18)
	dec a			;66e8
	ld b,020h		;66e9
	jr z,CUENTA_POR_DIFICULTAD		;66eb
	ld b,018h		;66ed
CUENTA_POR_DIFICULTAD:		; La cuenta baja con la dificultad de 0xE1D3
	ld a,(0e1d3h)		;66ef   ; la dificultad acorta la cuenta: dos fotogramas menos por vuelta
	add a,a			;66f2
	sub b			;66f3
	neg		;66f4   ; la cuenta que queda es 0x20 (o 0x18) menos el doble de la dificultad
	ld (hl),a			;66f6
	ret			;66f7
BUSCA_EN_LA_TANDA:		; Busca el tipo del hueco entre las dos tandas
	ex de,hl			;66f8   ; 0xE321 son las dos tandas de la oleada, seis bytes cada una
	ld hl,0e321h		;66f9
	ld b,002h		;66fc
TANDA_PASO:		; Compara con la tanda y salta seis bytes a la siguiente
	cp (hl)			;66fe   ; si el tipo esta en la tanda, coge la espera siguiente de su secuencia
	jr z,SIGUIENTE_DE_LA_LISTA		;66ff
	ex af,af'			;6701
	ld a,006h		;6702   ; seis bytes a la otra tanda
	add a,l			;6704
	ld l,a			;6705
	ex af,af'			;6706
	djnz TANDA_PASO		;6707
	xor a			;6709   ; fuera de las dos tandas, la cuenta se queda a cero y este hueco no vuelve a disparar
	ex de,hl			;670a
	ld (hl),a			;670b
	ret			;670c
SIGUIENTE_DE_LA_LISTA:		; Avanza dentro de una secuencia; con 0xFF vuelve al principio
	push de			;670d
	ld a,004h		;670e   ; byte +4 de la tanda: la secuencia de esperas entre disparos
	add a,l			;6710
	ld l,a			;6711
	ld a,(0e1d3h)		;6712   ; la dificultad corre la secuencia
	add a,(hl)			;6715
	add a,a			;6716
	ld de,0770fh		;6717   ; 0x770F es la tabla de secuencias
	push hl			;671a
	ex de,hl			;671b
	call LEE_PUNTERO		;671c
	pop hl			;671f
	inc l			;6720   ; y el +5 es el paso dentro de ella
	ld a,(hl)			;6721
	ex de,hl			;6722
	ld c,(hl)			;6723
	call SUMA_A_HL		;6724   ; avanza un paso
	ld a,(hl)			;6727
	ex de,hl			;6728
	cp 0ffh		;6729   ; 0xFF acaba la secuencia y la devuelve al principio
	jr nz,GUARDA_DE_LA_LISTA		;672b
	ld a,c			;672d
	ld (hl),000h		;672e
GUARDA_DE_LA_LISTA:		; Deja el enemigo que toca en el hueco
	pop hl			;6730
	ld (hl),a			;6731
	ret			;6732
RECORRE_GIGANTE:		; Recorre las piezas del gigante buscando disparo
	ld b,004h		;6733   ; el gigante 1 lleva cuatro piezas...
	ld a,(0e1d6h)		;6735
	dec a			;6738
	jr z,PIEZAS_DEL_GIGANTE		;6739
	ld b,002h		;673b   ; ...y el 2 solo dos
PIEZAS_DEL_GIGANTE:		; Cuatro piezas o dos, segun cual sea el gigante
	ld hl,0e150h		;673d   ; las piezas del gigante son 0xE150, ocho bytes cada una
	ld de,00008h		;6740
	jr HUECO_DISPARA		;6743
RECORRE_HUECOS_DISPARO:		; Recorre los siete huecos buscando quien dispara
	ld b,007h		;6745   ; los siete huecos de objeto, de 16 bytes
	ld de,00010h		;6747
	ld hl,0e200h		;674a
HUECO_DISPARA:		; Mira la cuenta atras de disparo de este hueco
	ld (0e310h),hl		;674d   ; 0xE310 lleva el hueco y 0xE318 su tipo
	ld a,(hl)			;6750
	ld (0e318h),a		;6751
	and a			;6754   ; hueco vacio, nada que disparar
	jr z,HUECO_DISPARO_SIGUIENTE		;6755
	cp 010h		;6757   ; los tipos 0x10 y 0x11 no disparan
	jr z,HUECO_DISPARO_SIGUIENTE		;6759
	cp 011h		;675b
	jr z,HUECO_DISPARO_SIGUIENTE		;675d
	cp 00bh		;675f   ; la cuenta esta en +3 de normal...
	ld c,003h		;6761
	jr nz,CUENTA_TIPO_ALTO		;6763
	ld c,00ah		;6765   ; ...en +10 para el tipo 0x0B...
CUENTA_TIPO_ALTO:		; Los tipos de 0x12 en adelante llevan la cuenta en mas uno
	cp 012h		;6767   ; ...y en +1 de los tipos 0x12 en adelante
	jr c,MIRA_LA_CUENTA		;6769
	ld c,001h		;676b
MIRA_LA_CUENTA:		; Baja la cuenta atras; al llegar a cero, dispara
	ld a,c			;676d   ; el byte de la cuenta
	add a,l			;676e
	ld l,a			;676f
	ld a,(hl)			;6770
	and a			;6771   ; con la cuenta a cero este hueco ya no dispara
	jr z,HUECO_DISPARO_SIGUIENTE		;6772
	dec (hl)			;6774   ; al llegar a cero, suelta el disparo
	jr z,PREPARA_DISPARO		;6775
HUECO_DISPARO_SIGUIENTE:		; Salta al hueco siguiente
	ld hl,(0e310h)		;6777
	add hl,de			;677a   ; el salto ya viene en DE: 16 para los huecos y 8 para las piezas del gigante
	djnz HUECO_DISPARA		;677b
	ret			;677d
PREPARA_DISPARO:		; Calcula el octante del avion respecto del que dispara
	call REPONE_CUENTA		;677e   ; recarga la cuenta para el proximo disparo
	call ORIGEN_DEL_DISPARO		;6781   ; mira de que punto sale el disparo
	ld a,e			;6784
	sub 009h		;6785   ; fuera de la franja de filas 9 a 0xA8 no se dispara
	cp 09fh		;6787
	ret nc			;6789
	ld hl,00000h		;678a   ; 0xE316 y 0xE317 son los signos de la fila y de la columna
	ld (0e316h),hl		;678d
	ld hl,(0e181h)		;6790   ; la posicion del avion
	ld a,l			;6793
	sub e			;6794   ; diferencia de filas...
	jr nc,DISTANCIA_FILA		;6795
	neg		;6797   ; ...y si el avion esta mas arriba, se le da la vuelta y se marca el signo
	ld c,a			;6799
	ld a,001h		;679a
	ld (0e316h),a		;679c
	ld a,c			;679f
DISTANCIA_FILA:		; De la diferencia de filas saca tres bits
	rra			;67a0   ; los cinco rra dejan la distancia partida por 32: tres bits
	rra			;67a1
	rra			;67a2
	rra			;67a3
	rra			;67a4
	and 007h		;67a5
	ld b,a			;67a7
	ld a,h			;67a8   ; lo mismo con las columnas
	sub d			;67a9
	jr nc,DISTANCIA_COLUMNA		;67aa
	neg		;67ac
	ld e,a			;67ae
	ld a,001h		;67af
	ld (0e317h),a		;67b1
	ld a,e			;67b4
DISTANCIA_COLUMNA:		; De la diferencia de columnas, otros tres
	rra			;67b5
	rra			;67b6
	rra			;67b7
	rra			;67b8
	rra			;67b9
	and 007h		;67ba
	ld c,a			;67bc
	ld hl,0e270h		;67bd   ; los nueve disparos
	ld e,009h		;67c0
	ld a,(0e321h)		;67c2   ; en la oleada 0x0A solo se pueden usar cinco de los nueve
	ld hl,0e270h		;67c5
	cp 00ah		;67c8
	jr nz,BUSCA_DISPARO_LIBRE		;67ca
	ld e,005h		;67cc
BUSCA_DISPARO_LIBRE:		; Busca un disparo libre entre los nueve de 0xE270
	ld a,(hl)			;67ce   ; disparo libre es el que tiene el tipo a cero
	and a			;67cf
	jr z,ELIGE_DIRECCION		;67d0
	ld a,010h		;67d2   ; 16 bytes al siguiente
	add a,l			;67d4
	ld l,a			;67d5
	dec e			;67d6
	jr nz,BUSCA_DISPARO_LIBRE		;67d7
	ret			;67d9
ELIGE_DIRECCION:		; Elige la direccion del disparo enemigo hacia el avion
	ld (0e314h),hl		;67da   ; 0xE314 se queda el disparo elegido
	ld a,b			;67dd   ; seis columnas por fila en la tabla de 0x68F3
	add a,a			;67de
	add a,a			;67df
	add a,b			;67e0
	add a,b			;67e1
	add a,c			;67e2
	ld de,068f3h		;67e3   ; la tabla dice que direccion tomar segun el octante
	call SUMA_A_DE		;67e6
	ld a,(de)			;67e9
	cp 009h		;67ea   ; 0xFF (o cualquiera de 9 en adelante) es que desde ahi no se dispara
	ret nc			;67ec
	ld c,a			;67ed
	ld a,r		;67ee   ; toma tres bits del registro R para desviar la punteria
	and 003h		;67f0
	rra			;67f2
	jr nc,SUMA_DESVIO		;67f3
	ld a,001h		;67f5   ; tras el rra de arriba el acarreo esta siempre puesto, asi que el jr nc nunca salta y el ld a,0xFF se ejecuta siempre
	rra			;67f7
	jr nc,$+3		;67f8
	ld a,0ffh		;67fa
SUMA_DESVIO:		; Suma el desvio de la punteria a la direccion elegida
	add a,c			;67fc   ; el desvio se suma a la direccion...
	cp 009h		;67fd   ; ...y si se sale de las nueve, se queda la de la tabla
	jr c,MONTA_DISPARO		;67ff
	ld a,c			;6801
MONTA_DISPARO:		; Coge la direccion de la tabla de senos y arma el disparo
	ld hl,06917h		;6802   ; la tabla de direcciones de 0x6917
	add a,a			;6805   ; cuatro bytes por direccion: dos velocidades de 16 bits
	add a,a			;6806
	call LEE_PUNTERO		;6807
	inc hl			;680a
	ld c,(hl)			;680b   ; la segunda palabra es la velocidad de columna
	inc hl			;680c
	ld b,(hl)			;680d
	ld a,(0e316h)		;680e   ; con el signo puesto, la fila va hacia arriba
	and a			;6811
	call nz,NIEGA_DE		;6812
	ld a,(0e318h)		;6815   ; los tipos 0x12 en adelante caen medio pixel mas por fotograma
	cp 012h		;6818
	jr c,GUARDA_DISPARO		;681a
	ld hl,00080h		;681c
	add hl,de			;681f
	ex de,hl			;6820
GUARDA_DISPARO:		; Rellena el hueco de disparo con posicion y velocidad
	ld hl,(0e314h)		;6821
	ld (hl),001h		;6824   ; byte +0 a 1: disparo normal
	inc hl			;6826
	ld (hl),e			;6827   ; bytes +1/+2: la velocidad de fila
	inc hl			;6828
	ld (hl),d			;6829
	inc hl			;682a
	ld e,c			;682b
	ld d,b			;682c
	ld a,(0e317h)		;682d   ; y el signo de la columna
	and a			;6830
	call nz,NIEGA_DE		;6831
	ld (hl),e			;6834   ; bytes +3/+4: la velocidad de columna
	inc hl			;6835
	ld (hl),d			;6836
	inc hl			;6837
	inc hl			;6838
	ld de,(0e312h)		;6839   ; 0xE312 trae el punto de salida
	ld a,e			;683d
	ld (hl),a			;683e   ; byte +6 la fila y +8 la columna
	inc hl			;683f
	inc hl			;6840
	ld (hl),d			;6841
	inc hl			;6842
	ld (hl),088h		;6843   ; patron 0x88 y color 15
	inc hl			;6845
	ld (hl),00fh		;6846
	ld a,(0e318h)		;6848   ; los tipos 5 y 9 avisan al disparar
	cp 005h		;684b
	jr z,SUENA_DISPARO		;684d
	cp 009h		;684f
	ret nz			;6851
SUENA_DISPARO:		; Los tipos 5 y 9 disparan con sonido propio
	ld a,089h		;6852   ; 0x89 es ese aviso
	jp PIDE_SONIDO		;6854
NIEGA_DE:		; DE pasa a valer menos DE, para disparar hacia el otro lado
	ld a,e			;6857   ; el complemento a dos, byte a byte
	cpl			;6858
	ld e,a			;6859
	ld a,d			;685a
	cpl			;685b
	ld d,a			;685c
	inc de			;685d
	ret			;685e
ORIGEN_POR_TABLA:		; Origen del disparo leido de la plantilla del hueco
	ld a,004h		;685f   ; la plantilla del hueco lleva el desvio del origen en +4/+5
	call LEE_PUNTERO		;6861
	jr GUARDA_ORIGEN		;6864
ORIGEN_DEL_DISPARO:		; De donde sale el disparo, segun el tipo del hueco
	ld hl,(0e310h)		;6866   ; byte +0: el tipo del hueco
	ld a,(hl)			;6869
	ld c,000h		;686a
	cp 009h		;686c   ; los tipos 9, 10 y 11 tienen su propia manera de elegir el punto
	jr z,ORIGEN_TIPO_9		;686e
	cp 00ah		;6870
	jr z,ORIGEN_TIPO_10		;6872
	cp 00bh		;6874
	jr z,ORIGEN_TIPO_11		;6876
	cp 012h		;6878   ; y los de 0x12 en adelante lo sacan de su plantilla
	jr nc,ORIGEN_POR_TABLA		;687a
	cp 006h		;687c   ; el tipo 6 mide el doble de ancho: el disparo sale ocho pixeles a la derecha
	jr nz,ORIGEN_NORMAL		;687e
	ld c,008h		;6880
ORIGEN_NORMAL:		; El caso general: la fila y la columna del hueco
	ld de,00009h		;6882   ; de +0 a +9: la fila
	add hl,de			;6885
	ld e,(hl)			;6886
	inc hl			;6887
	inc hl			;6888
	ld a,(hl)			;6889   ; y +11 la columna
	add a,c			;688a
	ld d,a			;688b
GUARDA_ORIGEN:		; Deja el origen en 0xE312
	ld (0e312h),de		;688c   ; 0xE312 se queda el punto de salida
	ret			;6890
ORIGEN_TIPO_9:		; El tipo 9 solo dispara con el patron 0x74
	call ORIGEN_NORMAL		;6891   ; el punto sale igual que en el caso general...
	inc hl			;6894
	ld a,(hl)			;6895   ; ...pero el tipo 9 solo dispara con el patron 0x74
	cp 074h		;6896
	ret z			;6898
	pop hl			;6899   ; con cualquier otro patron se tira el retorno y no se dispara
	ret			;689a
ORIGEN_TIPO_10:		; El tipo 10 dispara desde una pieza o desde la otra
	inc l			;689b   ; byte +2: que piezas del tipo 10 siguen vivas
	inc l			;689c
	ld a,(hl)			;689d
	dec l			;689e
	dec l			;689f
	and 003h		;68a0
	cp 003h		;68a2   ; con las dos vivas, el registro R elige
	jr z,ORIGEN_AL_AZAR		;68a4
	rra			;68a6   ; bit 0: solo la primera
	jr c,ORIGEN_NORMAL		;68a7
	rra			;68a9   ; bit 1: solo la segunda
	jr c,ORIGEN_MAS_64		;68aa
	pop hl			;68ac   ; sin ninguna viva, se tira el retorno
	ret			;68ad
ORIGEN_MAS_64:		; La segunda pieza esta 0x40 pixeles mas abajo
	call ORIGEN_NORMAL		;68ae
	ld a,040h		;68b1   ; la segunda pieza va 0x40 pixeles a la derecha
	add a,d			;68b3
	ld d,a			;68b4
	jr GUARDA_ORIGEN		;68b5
ORIGEN_AL_AZAR:		; Con las dos piezas vivas, elige una con el registro R
	ld a,r		;68b7   ; el bit 0 de R elige pieza
	rra			;68b9
	jr c,ORIGEN_MAS_64		;68ba
	jr ORIGEN_NORMAL		;68bc
ORIGEN_TIPO_11:		; El tipo 11 dispara desde una de las dos piezas del 0x13
	ld hl,(0e310h)		;68be   ; byte +1: la rutina
	inc l			;68c1
	ld a,(hl)			;68c2
	dec l			;68c3
	cp 013h		;68c4   ; si aun no se ha partido en dos, el caso general
	jr nz,ORIGEN_NORMAL		;68c6
	ld a,r		;68c8   ; el bit 0 de R elige cual de las dos piezas dispara
	rra			;68ca
	jr c,ORIGEN_TIPO_11_B		;68cb
	ld de,0000bh		;68cd   ; byte +11: la segunda pieza, con su fila y su columna
	add hl,de			;68d0
	ld a,(hl)			;68d1
	inc l			;68d2
	ld e,(hl)			;68d3
	inc l			;68d4
	ld d,(hl)			;68d5
	cp 001h		;68d6   ; y solo dispara si esta viva
	jr z,GUARDA_ORIGEN		;68d8
	pop de			;68da   ; si no, se tira el retorno
	ret			;68db
ORIGEN_TIPO_11_B:		; La otra pieza del tipo 0x13
	inc l			;68dc   ; byte +2: la primera pieza
	inc l			;68dd
	ld a,(hl)			;68de
	inc l			;68df
	ld e,(hl)			;68e0
	inc l			;68e1
	inc l			;68e2
	inc l			;68e3
	inc l			;68e4
	ld d,(hl)			;68e5
	cp 001h		;68e6   ; tambien tiene que estar viva
	jr z,GUARDA_ORIGEN		;68e8
	pop de			;68ea
	ret			;68eb
LEE_PUNTERO:		; DE = la palabra que hay en HL + A
	call SUMA_A_HL		;68ec
	ld e,(hl)			;68ef
	inc hl			;68f0
	ld d,(hl)			;68f1
	ret			;68f2

; ----------------------------------------------------------------------
; DATOS tabla_direccion_disparo: Seis por seis: que direccion toma el disparo
;   segun donde este el avion (0xFF = no dispara)
;   0x68f3..0x6917  (36 bytes)
DATA_tabla_direccion_disparo:
	defb 0ffh,0ffh,000h,000h,000h,000h	; 68f3
	defb 0ffh,004h,003h,002h,002h,001h	; 68f9
	defb 008h,005h,004h,004h,003h,003h	; 68ff
	defb 008h,006h,005h,004h,003h,003h	; 6905
	defb 008h,006h,005h,005h,004h,004h	; 690b
	defb 008h,007h,007h,005h,004h,004h	; 6911

; ----------------------------------------------------------------------
; DATOS tabla_seno_disparo: Nueve direcciones, cuatro bytes cada una:
;   velocidad de fila y velocidad de columna, un cuarto de vuelta con radio
;   320. OJO: las entradas 3 y 5 estan INTERCAMBIADAS respecto de la tabla de
;   senos que forman las otras siete
;   0x6917..0x693b  (36 bytes)
DATA_tabla_seno_disparo:
	defw 00000h,00140h	; 6917
	defw 0003eh,00139h	; 691b
	defw 0007ah,00127h	; 691f
	defw 0010ah,000b1h	; 6923
	defw 000e2h,000e2h	; 6927
	defw 000b1h,0010ah	; 692b
	defw 00127h,0007ah	; 692f
	defw 00139h,0003eh	; 6933
	defw 00140h,00000h	; 6937

; ======================================================================
; CODIGO 0x693b..0x6bb3  (632 bytes)
; ======================================================================


HAY_CHOQUE:		; Prueba de choque contra la caja de 0xE1C4/0xE1C5
	exx			;693b   ; entra con BC y DE: la posicion de cada uno de los dos que se prueban
	ld hl,0e1c2h		;693c   ; 0xE1C2/C3 es la caja de uno y 0xE1C4/C5 la del otro
	xor a			;693f
	sub (hl)			;6940   ; suma de las dos anchuras: el margen dentro del que hay choque
	sub (hl)			;6941
	inc hl			;6942
	add a,(hl)			;6943
	inc hl			;6944
	sub (hl)			;6945
	sub (hl)			;6946
	inc hl			;6947
	add a,(hl)			;6948
	exx			;6949
	ld i,a		;694a   ; el registro I hace de guardarropa: con el modo de interrupcion 1 nadie mas lo usa
	ld a,d			;694c   ; diferencia de filas
	sub b			;694d
	exx			;694e
	ld d,a			;694f
	xor a			;6950
	add a,(hl)			;6951   ; y el desplazamiento que centra la comparacion
	dec hl			;6952
	sub (hl)			;6953
	dec hl			;6954
	dec hl			;6955
	sub (hl)			;6956
	ld c,a			;6957
	add a,d			;6958
	ld d,a			;6959
	ld a,i		;695a   ; si la diferencia se sale del margen, no hay choque...
	cp d			;695c
	exx			;695d
	ccf			;695e   ; ...y el ccf devuelve el acarreo al derecho: puesto quiere decir que chocan
	ret nc			;695f
	exx			;6960
	ld d,a			;6961   ; el mismo margen vale para las columnas
	exx			;6962
	ld a,e			;6963   ; diferencia de columnas
	sub c			;6964
	exx			;6965
	add a,c			;6966
	cp d			;6967   ; y la misma prueba: si cabe, hay choque
	exx			;6968
	ret			;6969
PREPARA_CAJA_AVION:		; Deja en 0xE1C2 la caja del avion y su posicion
	ld a,(0e1cfh)		;696a   ; con el avion ya muerto no se prueba nada
	and a			;696d
	ret nz			;696e
	ld hl,01003h		;696f   ; la caja del avion: de +3 a +13
	ld (0e1c2h),hl		;6972
	ld hl,01006h		;6975   ; y la del otro, mientras nadie la cambie: de +6 a +10
	ld (0e1c4h),hl		;6978
	ld hl,0e181h		;697b   ; BC sale con la fila y la columna del avion
	ld c,(hl)			;697e
	inc hl			;697f
	ld b,(hl)			;6980
	xor a			;6981
	ret			;6982
TOCADO_EL_GIGANTE:		; Una pieza del gigante encajada: puntos y sonido
	ld hl,(0e310h)		;6983   ; byte +0 de la pieza: sube uno por cada impacto
	inc (hl)			;6986
	ld a,(hl)			;6987
	push af			;6988
	call MARCA_EXPLOSION		;6989   ; y arranca su explosion
	ld a,(0e1d6h)		;698c   ; el gigante 1 tiene la ultima pieza en 0x14...
	ld c,014h		;698f
	dec a			;6991
	jr z,MIRA_SI_ERA_LA_ULTIMA		;6992
	ld c,017h		;6994   ; ...y el gigante 2 en 0x17
MIRA_SI_ERA_LA_ULTIMA:		; Solo la ultima pieza da los mil puntos
	pop af			;6996   ; mientras no sea la ultima, solo suena
	cp c			;6997
	ld a,00ah		;6998   ; 0x0A es el golpe sin romper
	jp nz,PIDE_SONIDO		;699a
	ld hl,0e143h		;699d   ; 0xE143 son las piezas que quedan por romper
	dec (hl)			;69a0
	jr nz,$+6		;69a1   ; el jr nz cae en el 03 del ld (hl),3 de aqui abajo, que se ejecuta suelto como un inc bc. Otro byte ahorrado
	dec l			;69a3
	dec l			;69a4
	dec l			;69a5
	ld (hl),003h		;69a6   ; rota la ultima pieza: el gigante se abre
	ld a,050h		;69a8   ; 0x50 es el estallido de la pieza
	call PIDE_SONIDO		;69aa
	ld de,01000h		;69ad   ; mil puntos por pieza
	call SUMA_PUNTOS		;69b0
	ld a,(0e143h)		;69b3   ; con todas las piezas rotas...
	and a			;69b6
	ret nz			;69b7
	ld de,05000h		;69b8   ; ...cinco mil puntos mas...
	call SUMA_PUNTOS		;69bb
	ld a,(0e1d6h)		;69be
	dec a			;69c1
	ret z			;69c2
	ld de,05000h		;69c3   ; ...y otros cinco mil si es el gigante 2
	jp SUMA_PUNTOS		;69c6
APAGA_BALA_Y_PUNTUA:		; Apaga la bala y cobra la pieza del gigante
	call APAGA_LA_BALA		;69c9   ; la bala se gasta en el impacto
	jr TOCADO_EL_GIGANTE		;69cc
CHOQUES_BALAS_GIGANTE:		; Las tres balas contra las piezas del gigante
	ld b,003h		;69ce   ; las tres balas del avion
	ld hl,0e0b8h		;69d0
	xor a			;69d3
	ld (0e1cdh),a		;69d4   ; 0xE1CD lleva el numero de bala
BALA_CONTRA_GIGANTE:		; Una bala, si esta viva
	push bc			;69d7
	push hl			;69d8
	ld c,(hl)			;69d9   ; C es la fila de la bala
	ld a,c			;69da
	cp 0c3h		;69db   ; de 0xC3 para arriba la bala esta apagada
	jr nc,BALA_SIGUIENTE		;69dd
	inc l			;69df
	ld b,(hl)			;69e0   ; B la columna y el byte siguiente el patron
	inc l			;69e1
	ld a,(hl)			;69e2
	ld de,01007h		;69e3   ; la bala normal (patron 8) tiene una caja de dos pixeles...
	cp 008h		;69e6
	jr z,CAJA_DE_LA_BALA		;69e8
	ld e,002h		;69ea   ; ...y la mejorada, de doce: acierta mucho mas facil
CAJA_DE_LA_BALA:		; La caja de la bala depende de su patron
	ld (0e1c2h),de		;69ec   ; 0xE1C2/C3 es la caja de la bala
	call BALA_CONTRA_PIEZAS		;69f0
BALA_SIGUIENTE:		; Pasa a la bala siguiente
	ld hl,0e1cdh		;69f3
	inc (hl)			;69f6   ; una bala mas probada
	pop hl			;69f7
	pop bc			;69f8
	inc l			;69f9   ; cuatro bytes a la ficha siguiente
	inc l			;69fa
	inc l			;69fb
	inc l			;69fc
	djnz BALA_CONTRA_GIGANTE		;69fd
	ret			;69ff
BALA_CONTRA_PIEZAS:		; Prueba la bala contra las cuatro (o dos) piezas
	ld hl,0e150h		;6a00   ; las piezas del gigante empiezan en 0xE150
	exx			;6a03
	ld a,(0e1d6h)		;6a04   ; cuatro piezas el gigante 1 y dos el 2
	ld b,004h		;6a07
	dec a			;6a09
	jr z,PIEZA_PASO		;6a0a
	ld b,002h		;6a0c
PIEZA_PASO:		; Una pieza del gigante
	push bc			;6a0e
	exx			;6a0f
	ld (0e310h),hl		;6a10   ; 0xE310 lleva la pieza de turno
	ld a,(hl)			;6a13   ; pieza a cero: no esta
	and a			;6a14
	jr z,PIEZA_SIGUIENTE		;6a15
	cp 017h		;6a17   ; y con 0x17 ya esta rota
	jr z,PIEZA_SIGUIENTE		;6a19
	inc l			;6a1b   ; bytes +4 y +5 de la pieza: su fila y su columna
	inc l			;6a1c
	inc l			;6a1d
	inc l			;6a1e
	ld e,(hl)			;6a1f
	inc l			;6a20
	ld d,(hl)			;6a21
	call HAY_CHOQUE		;6a22   ; y a probar el choque
	call c,APAGA_BALA_Y_PUNTUA		;6a25
PIEZA_SIGUIENTE:		; Ocho bytes mas alla esta la pieza siguiente
	ld hl,(0e310h)		;6a28
	ld de,00008h		;6a2b   ; ocho bytes por pieza
	add hl,de			;6a2e
	exx			;6a2f
	pop bc			;6a30
	djnz PIEZA_PASO		;6a31
	ret			;6a33
CHOQUES_AVION_DISPAROS:		; El avion contra los nueve disparos enemigos
	call PREPARA_CAJA_AVION		;6a34   ; la caja del avion, y de paso mira si esta vivo
	ret nz			;6a37
	ld hl,0e270h		;6a38   ; los nueve disparos enemigos
	exx			;6a3b
	ld b,009h		;6a3c
DISPARO_CONTRA_AVION:		; Un disparo enemigo contra el avion
	exx			;6a3e
	ld (0e310h),hl		;6a3f
	ld a,(hl)			;6a42   ; disparo apagado, nada que probar
	and a			;6a43
	jr z,DISPARO_CONTRA_SIGUIENTE		;6a44
	ld a,006h		;6a46   ; bytes +6 y +8: la fila y la columna del disparo
	add a,l			;6a48
	ld l,a			;6a49
	ld e,(hl)			;6a4a
	inc l			;6a4b
	inc l			;6a4c
	ld d,(hl)			;6a4d
	call HAY_CHOQUE		;6a4e   ; prueba el choque con la caja del avion
	jr c,AVION_TOCADO_POR_DISPARO		;6a51
DISPARO_CONTRA_SIGUIENTE:		; Pasa al disparo siguiente
	ld hl,(0e310h)		;6a53
	ld de,00010h		;6a56   ; 16 bytes al disparo siguiente
	add hl,de			;6a59
	exx			;6a5a
	djnz DISPARO_CONTRA_AVION		;6a5b
	ret			;6a5d
AVION_TOCADO_POR_DISPARO:		; El disparo acierta: se apaga y el avion muere
	ld hl,(0e310h)		;6a5e   ; byte +0 del disparo
	ld a,(hl)			;6a61
	inc a			;6a62   ; el disparo fijo (0xFF) no se apaga al tocar
	jr nz,APAGA_EL_DISPARO		;6a63
	ld de,0000ah		;6a65   ; byte +10 del hueco: mira si el objeto que lo cuelga sigue ahi
	add hl,de			;6a68
	ld a,(hl)			;6a69
	and a			;6a6a
	jr z,DISPARO_CONTRA_SIGUIENTE		;6a6b
APAGA_EL_DISPARO:		; Quita el disparo que ha acertado
	call APAGA_DISPARO		;6a6d   ; el disparo que ha acertado se apaga
MATA_AL_AVION:		; Arranca la explosion del avion, o suma un aviso
	ld hl,(0e310h)		;6a70
	ld a,(hl)			;6a73
	cp 010h		;6a74   ; el tipo 0x10 atraviesa el avion sin hacerle nada
	ret z			;6a76
	cp 011h		;6a77   ; y el 0x11 no mata: solo mejora el disparo
	jr z,AVISO_SIN_MUERTE		;6a79
	ld hl,0e1cfh		;6a7b   ; 0xE1CF a 1: el avion esta muriendo
	ld (hl),001h		;6a7e
	inc hl			;6a80
	ld (hl),080h		;6a81   ; 0x80 fotogramas de explosion
	ld a,05ch		;6a83   ; 0x5C es el estallido del avion
	call PIDE_SONIDO		;6a85
	ld a,001h		;6a88
	ld (0e1ddh),a		;6a8a   ; 0xE1DD a 1 corta los avisos de sonido de los objetos
	ret			;6a8d
AVISO_SIN_MUERTE:		; El tipo 0x11 solo sube 0xE1D5 hasta dos
	ld hl,0e1d5h		;6a8e   ; 0xE1D5 es la mejora del disparo
	ld a,(hl)			;6a91
	inc a			;6a92   ; no pasa de 2, que es el tope
	cp 003h		;6a93
	ret nc			;6a95
	ld (hl),a			;6a96
	ld a,08fh		;6a97   ; 0x8F es el aviso de recogida
	jp PIDE_SONIDO		;6a99
CHOQUES_AVION_OBJETOS:		; El avion contra los siete objetos
	call PREPARA_CAJA_AVION		;6a9c   ; la caja del avion
	ret nz			;6a9f
	ld hl,0e200h		;6aa0   ; los siete huecos de objeto
	exx			;6aa3
	ld b,007h		;6aa4
OBJETO_CONTRA_AVION:		; Un objeto contra el avion, con su caja de choque
	push bc			;6aa6
	exx			;6aa7
	push bc			;6aa8
	ld (0e310h),hl		;6aa9   ; 0xE310 lleva el hueco de turno
	ld a,(hl)			;6aac   ; el tipo por dos, que es el indice de la tabla de cajas
	add a,a			;6aad
	ld e,a			;6aae
	jr z,OBJETO_CONTRA_SIGUIENTE		;6aaf
	inc hl			;6ab1
	ld a,(hl)			;6ab2
	cp 013h		;6ab3   ; la rutina 0x13 lleva dos piezas y se prueba aparte
	jr z,CHOCA_CON_EL_0X13		;6ab5
	cp 014h		;6ab7   ; y la 0x14 no choca con nadie
	jr z,OBJETO_CONTRA_SIGUIENTE		;6ab9
	ld a,e			;6abb
	ld de,00008h		;6abc   ; bytes +8 y +11: la fila y la columna del objeto
	add hl,de			;6abf
	ld e,(hl)			;6ac0
	inc l			;6ac1
	inc l			;6ac2
	ld d,(hl)			;6ac3
	ld hl,06bb1h		;6ac4   ; la base es 0x6BB1, dos bytes antes de la tabla: el indice es 2*tipo
	call SUMA_A_HL		;6ac7
	ld a,(hl)			;6aca
	ld (0e1c4h),a		;6acb   ; 0xE1C4/C5 se queda la caja de este tipo
	inc hl			;6ace
	ld a,(hl)			;6acf
	ld (0e1c5h),a		;6ad0
	call HAY_CHOQUE		;6ad3   ; y a probar
	jr c,CHOCA_CON_EL_OBJETO		;6ad6
OBJETO_CONTRA_SIGUIENTE:		; Pasa al objeto siguiente
	ld hl,(0e310h)		;6ad8
	ld de,00010h		;6adb   ; 16 bytes al hueco siguiente
	add hl,de			;6ade
	pop bc			;6adf
	exx			;6ae0
	pop bc			;6ae1
	djnz OBJETO_CONTRA_AVION		;6ae2
	ret			;6ae4
CHOCA_CON_EL_0X13:		; El tipo 0x13 tiene dos piezas y se prueban aparte
	xor a			;6ae5   ; 0xE1CE dira si el objeto ha muerto en el golpe
	ld (0e1ceh),a		;6ae6
	call CHOQUE_DOS_PIEZAS		;6ae9
	jr MIRA_SI_MURIO		;6aec
CHOCA_CON_EL_OBJETO:		; El objeto ha encajado el golpe
	call OBJETO_ENCAJA		;6aee
MIRA_SI_MURIO:		; Si el objeto ha muerto, el avion tambien
	ld a,(0e1ceh)		;6af1   ; si el objeto ha muerto, el avion se lo lleva por delante
	and a			;6af4
	jr z,OBJETO_CONTRA_SIGUIENTE		;6af5
	call MATA_AL_AVION		;6af7
	jr OBJETO_CONTRA_SIGUIENTE		;6afa
CHOQUES_BALAS_OBJETOS:		; Las tres balas contra los siete objetos
	ld b,003h		;6afc   ; las tres balas
	ld hl,0e0b8h		;6afe
	xor a			;6b01
	ld (0e1cdh),a		;6b02   ; 0xE1CD lleva el numero de bala
BALA_CONTRA_OBJETOS:		; Una bala, si esta viva
	push bc			;6b05
	push hl			;6b06
	ld c,(hl)			;6b07
	ld a,c			;6b08
	cp 0c3h		;6b09   ; de 0xC3 para arriba la bala esta apagada
	jr nc,BALA_SIGUIENTE_2		;6b0b
	inc l			;6b0d
	ld b,(hl)			;6b0e
	inc l			;6b0f
	ld a,(hl)			;6b10
	ld de,01007h		;6b11   ; la bala normal tiene caja de dos pixeles y la mejorada de doce
	cp 008h		;6b14
	jr z,CAJA_DE_LA_BALA_2		;6b16
	ld e,002h		;6b18
CAJA_DE_LA_BALA_2:		; La caja de la bala depende de su patron
	ld (0e1c2h),de		;6b1a   ; 0xE1C2/C3 es la caja de la bala
	call PRUEBA_LOS_SIETE		;6b1e
BALA_SIGUIENTE_2:		; Pasa a la bala siguiente
	ld hl,0e1cdh		;6b21
	inc (hl)			;6b24
	pop hl			;6b25
	pop bc			;6b26
	inc l			;6b27   ; cuatro bytes a la ficha siguiente
	inc l			;6b28
	inc l			;6b29
	inc l			;6b2a
	djnz BALA_CONTRA_OBJETOS		;6b2b
	ret			;6b2d
PRUEBA_LOS_SIETE:		; Recorre los siete huecos con esta bala
	ld a,c			;6b2e   ; la fila 0xE0 tambien es bala apagada
	cp 0e0h		;6b2f
	ret z			;6b31
	ld hl,0e200h		;6b32   ; los siete huecos
	exx			;6b35
	ld b,007h		;6b36
RECORRE_CHOQUES:		; Mira si algun objeto choca con el avion o con sus balas
	push bc			;6b38
	exx			;6b39
	push bc			;6b3a
	ld (0e310h),hl		;6b3b   ; 0xE310 lleva el hueco
	ld a,(hl)			;6b3e
	sub 010h		;6b3f   ; los tipos 0x10 y 0x11 no se pueden derribar
	cp 002h		;6b41
	jr c,CHOQUE_SIGUIENTE		;6b43
	inc hl			;6b45
	ld a,(hl)			;6b46
	cp 013h		;6b47   ; la rutina 0x13 se prueba pieza a pieza
	jr z,CHOQUE_CON_EL_0X13		;6b49
	dec hl			;6b4b
	ld a,(hl)			;6b4c
	add a,a			;6b4d   ; el tipo por dos: el indice de la tabla de cajas
	jr z,CHOQUE_SIGUIENTE		;6b4e
	ld de,06bb1h		;6b50   ; la base es 0x6BB1, dos bytes antes de la tabla: el indice es 2*tipo
	call SUMA_A_DE		;6b53
	ld a,(de)			;6b56
	inc de			;6b57
	ld (0e1c4h),a		;6b58   ; 0xE1C4/C5 se queda la caja
	ld a,(de)			;6b5b
	ld (0e1c5h),a		;6b5c
	inc hl			;6b5f
	ld a,(hl)			;6b60
	cp 014h		;6b61   ; la rutina 0x14 no encaja balas
	jr z,CHOQUE_SIGUIENTE		;6b63
	ld a,008h		;6b65   ; bytes +8 y +11: la fila y la columna
	add a,l			;6b67
	ld l,a			;6b68
	ld e,(hl)			;6b69
	inc hl			;6b6a
	inc hl			;6b6b
	ld d,(hl)			;6b6c
	call HAY_CHOQUE		;6b6d   ; y a probar
	call c,OBJETO_ENCAJA		;6b70
CHOQUE_SIGUIENTE:		; Salta al hueco siguiente
	ld hl,(0e310h)		;6b73
	ld a,010h		;6b76   ; 16 bytes al siguiente
	add a,l			;6b78
	ld l,a			;6b79
	pop bc			;6b7a
	exx			;6b7b
	pop bc			;6b7c
	djnz RECORRE_CHOQUES		;6b7d
	ret			;6b7f
CHOQUE_CON_EL_0X13:		; El tipo 0x13 se prueba pieza a pieza
	call CHOQUE_DOS_PIEZAS		;6b80
	jr CHOQUE_SIGUIENTE		;6b83
CHOQUE_DOS_PIEZAS:		; Las dos piezas del tipo 0x13 contra la bala
	ld de,00a00h		;6b85   ; las dos piezas usan una caja fija de 0x0A
	ld (0e1c4h),de		;6b88
	inc l			;6b8c   ; byte +2: bit 0, la primera pieza esta viva
	ld a,(hl)			;6b8d
	rra			;6b8e
	jr nc,CHOQUE_PIEZA_B		;6b8f
	inc l			;6b91   ; su fila en +3 y su columna en +7
	ld e,(hl)			;6b92
	inc l			;6b93
	inc l			;6b94
	inc l			;6b95
	inc l			;6b96
	ld d,(hl)			;6b97
	call HAY_CHOQUE		;6b98   ; prueba el choque
	jp c,GOLPE_AL_TIPO_17		;6b9b
CHOQUE_PIEZA_B:		; La segunda pieza del tipo 0x13
	ld hl,(0e310h)		;6b9e
	ld de,0000bh		;6ba1   ; byte +11: bit 0, la segunda pieza
	add hl,de			;6ba4
	ld a,(hl)			;6ba5
	rra			;6ba6
	ret nc			;6ba7
	inc l			;6ba8   ; con su fila en +12 y su columna en +13
	ld e,(hl)			;6ba9
	inc l			;6baa
	ld d,(hl)			;6bab
	call HAY_CHOQUE		;6bac
	jp c,GOLPE_AL_TIPO_11		;6baf
	ret			;6bb2

; ----------------------------------------------------------------------
; DATOS tabla_caja_de_choque: La caja de choque de cada tipo de objeto (base
;   0x6BB1, tipos 1 a 17): el primer byte es el borde de arriba (que vale
;   tambien para la izquierda) y el segundo la SUMA de los dos bordes, asi que
;   restando sale el de abajo. La misma pareja se usa para las filas y para
;   las columnas
;   0x6bb3..0x6bd5  (34 bytes)
DATA_tabla_caja_de_choque:
	defb 002h,010h	; 6bb3
	defb 002h,010h	; 6bb5
	defb 002h,010h	; 6bb7
	defb 001h,010h	; 6bb9
	defb 004h,010h	; 6bbb
	defb 001h,020h	; 6bbd
	defb 001h,010h	; 6bbf
	defb 001h,010h	; 6bc1
	defb 001h,010h	; 6bc3
	defb 001h,050h	; 6bc5
	defb 001h,010h	; 6bc7
	defb 001h,020h	; 6bc9
	defb 001h,010h	; 6bcb
	defb 001h,010h	; 6bcd
	defb 001h,010h	; 6bcf
	defb 001h,010h	; 6bd1
	defb 001h,010h	; 6bd3

; ======================================================================
; CODIGO 0x6bd5..0x6d2c  (343 bytes)
; ======================================================================


OBJETO_ENCAJA:		; Reparte el golpe segun el tipo del objeto
	xor a			;6bd5   ; 0xE1CE dira si el golpe ha matado al objeto
	ld (0e1ceh),a		;6bd6
	ld hl,(0e310h)		;6bd9
	ld a,(hl)			;6bdc   ; byte +0: el tipo
	cp 006h		;6bdd   ; el tipo 6 tiene dos mitades
	jp z,GOLPE_AL_TIPO_6		;6bdf
	cp 00ah		;6be2   ; el 10 tambien, y ademas arrastra un disparo fijo
	jp z,GOLPE_AL_TIPO_10		;6be4
	cp 007h		;6be7   ; el tipo 7 aguanta el golpe
	jr z,SOLO_SUENA		;6be9
	cp 009h		;6beb   ; y el 9 solo se rompe en un fotograma concreto
	jr z,GOLPE_AL_TIPO_9		;6bed
	inc hl			;6bef
	cp 010h		;6bf0   ; los tipos 0x10 y 0x11 (los premios) explotan sin mas
	jr nc,OBJETO_A_EXPLOSION		;6bf2
	cp 00dh		;6bf4   ; y los del 0x0D al 0x0F son los de la tanda, que avisan antes
	jp nc,GOLPE_CON_AVISO		;6bf6
OBJETO_A_EXPLOSION:		; El objeto pasa al tipo 0x14: explota
	ld (hl),014h		;6bf9   ; byte +1 a 0x14: la rutina que solo hace de explosion
EXPLOTA:		; Cuenta de explosion, sonido y puntos
	ld a,l			;6bfb   ; el nibble alto da el numero de hueco
	rra			;6bfc
	rra			;6bfd
	rra			;6bfe
	rra			;6bff
	and 00fh		;6c00
	ld hl,0e1c6h		;6c02   ; 0xE1C6 mas el numero de hueco es su cuenta de explosion
	call SUMA_A_HL		;6c05
	ld (hl),010h		;6c08   ; 0x10 fotogramas de explosion
	ld hl,(0e310h)		;6c0a
	ld a,(hl)			;6c0d
	cp 011h		;6c0e   ; el premio de la mejora (0x11) se cobra sin ruido
	jr z,COBRA_EL_OBJETO		;6c10
	cp 010h		;6c12   ; el premio de los puntos (0x10) suena distinto
	ld a,00ah		;6c14
	jr nz,SONIDO_DE_EXPLOSION		;6c16
	ld a,08eh		;6c18   ; 0x8E es el aviso de premio recogido
SONIDO_DE_EXPLOSION:		; El sonido depende del tipo
	call PIDE_SONIDO		;6c1a
COBRA_EL_OBJETO:		; Lo que valia, de la tabla de 0x6D62
	ld hl,(0e310h)		;6c1d
	ld a,(hl)			;6c20   ; byte +0: el tipo
	inc l			;6c21
	inc l			;6c22
	ld b,(hl)			;6c23   ; y +2, que en el tipo 5 dice que premio suelta
	ld c,000h		;6c24
	cp 005h		;6c26   ; solo el tipo 5 deja algo detras
	jr nz,MIRA_SI_PUNTUA		;6c28
	djnz TIPO_5_CUENTA		;6c2a   ; con el +2 en 1 deja el premio de puntos...
	inc c			;6c2c
TIPO_5_CUENTA:		; Con el +2 en 2 el premio es la mejora del disparo
	djnz TIPO_5_GUARDA		;6c2d   ; ...con el 2 deja la mejora del disparo...
	ld c,002h		;6c2f
TIPO_5_GUARDA:		; Deja en +2 cual de las dos explosiones toca
	ld (hl),c			;6c31   ; ...y con cualquier otro valor no deja nada
MIRA_SI_PUNTUA:		; Solo los tipos por debajo de 0x12 dan puntos
	cp 012h		;6c32   ; los tipos 0x12 en adelante no dan puntos
	jr nc,MARCA_MUERTE		;6c34
	add a,a			;6c36   ; dos bytes por tipo
	ld hl,06d60h		;6c37   ; la base es 0x6D60, dos bytes antes de la tabla: el indice es 2*tipo
	call LEE_PUNTERO		;6c3a
	call SUMA_PUNTOS		;6c3d   ; y se cobran, en BCD
MARCA_MUERTE:		; Deja 0xE1CE a uno: ha muerto algo
	ld a,001h		;6c40   ; 0xE1CE a uno: ha muerto algo
	ld (0e1ceh),a		;6c42
APAGA_LA_BALA:		; Apaga la bala que ha acertado
	ld hl,0e0b8h		;6c45   ; 0xE0B8 es la primera bala
	ld a,(0e1cdh)		;6c48   ; 0xE1CD dice cual de las tres
	add a,a			;6c4b   ; cuatro bytes por ficha
	add a,a			;6c4c
	add a,l			;6c4d
	ld l,a			;6c4e
	ld (hl),0e0h		;6c4f   ; fila 0xE0: la bala se apaga al acertar
	ret			;6c51
SOLO_SUENA:		; El objeto no muere: solo suena el golpe
	ld a,00dh		;6c52   ; 0x0D es el golpe que no rompe
	call PIDE_SONIDO		;6c54
	jr MARCA_MUERTE		;6c57
GOLPE_AL_TIPO_9:		; El tipo 9 solo muere con el patron 0x74
	ld a,00ch		;6c59   ; de +1 a +13: el patron
	add a,l			;6c5b
	ld l,a			;6c5c
	ld a,(hl)			;6c5d
	cp 074h		;6c5e   ; el tipo 9 solo se rompe cuando lleva el patron 0x74
	jr nz,SOLO_SUENA		;6c60
	ld hl,(0e310h)		;6c62
	inc hl			;6c65
	jr OBJETO_A_EXPLOSION		;6c66
GOLPE_AL_TIPO_6:		; El tipo 6 tiene dos mitades que se rompen aparte
	exx			;6c68   ; la mitad de abajo del tipo 6 esta 0x10 pixeles mas alla
	ld b,010h		;6c69
	ld hl,01000h		;6c6b   ; con la caja 0x00/0x10
PRUEBA_DOS_MITADES:		; Prueba las dos mitades con sus cajas
	exx			;6c6e
	inc l			;6c6f   ; byte +2: que mitades siguen enteras
	inc l			;6c70
	ld a,(hl)			;6c71
	exx			;6c72
	ld (0e1c4h),hl		;6c73   ; 0xE1C4/C5 se queda la caja de la mitad
	exx			;6c76
	and 003h		;6c77   ; bits 0 y 1: mitad de arriba y mitad de abajo
	ret z			;6c79
	dec a			;6c7a   ; con el 1 solo queda la de arriba...
	jr z,MITAD_SOLA		;6c7b
	dec a			;6c7d   ; ...con el 2 solo la de abajo...
	jr z,MITAD_DE_ABAJO		;6c7e
	push bc			;6c80
	push de			;6c81
	call HAY_CHOQUE		;6c82   ; ...y con el 3 hay que probar las dos
	call c,ROMPE_MITAD_A		;6c85
	pop de			;6c88
	pop bc			;6c89
MITAD_DE_ABAJO:		; La mitad de abajo, desplazada
	exx			;6c8a
	ld a,b			;6c8b   ; la segunda mitad va desplazada
	exx			;6c8c
	add a,d			;6c8d
	ld d,a			;6c8e
	call HAY_CHOQUE		;6c8f   ; y se prueba en su sitio
	ret nc			;6c92
	ld hl,(0e310h)		;6c93
	inc l			;6c96
	inc l			;6c97
	res 1,(hl)		;6c98   ; baja el bit 1 (ya no esta) y sube el 3 (esta explotando)
	set 3,(hl)		;6c9a
	jp EXPLOTA		;6c9c
MITAD_SOLA:		; Con una sola mitad viva, se prueba esa
	call HAY_CHOQUE		;6c9f   ; la unica mitad que queda
	ret nc			;6ca2
ROMPE_MITAD_A:		; Marca la mitad de arriba como rota
	ld hl,(0e310h)		;6ca3
	inc l			;6ca6
	inc l			;6ca7
	res 0,(hl)		;6ca8   ; baja el bit 0 y sube el 2
	set 2,(hl)		;6caa
	jp EXPLOTA		;6cac
GOLPE_AL_TIPO_10:		; El tipo 10 se rompe igual, pero borra su rastro
	exx			;6caf   ; la segunda mitad del tipo 10 esta 0x40 pixeles mas alla
	ld b,040h		;6cb0
	ld hl,01004h		;6cb2   ; con la caja 0x04/0x10
	call PRUEBA_DOS_MITADES		;6cb5
	ld a,(0e1ceh)		;6cb8   ; si no ha muerto, no hay que borrar nada
	and a			;6cbb
	ret z			;6cbc
	ld a,(0e310h)		;6cbd   ; el numero de hueco
	and 0f0h		;6cc0
	push af			;6cc2
	ld hl,0e290h		;6cc3   ; y con el, su disparo fijo, que se libera
	add a,l			;6cc6
	ld l,a			;6cc7
	ld (hl),000h		;6cc8
	pop af			;6cca
	ld hl,0e114h		;6ccb   ; 0xE114 es la ficha de ese disparo
	rra			;6cce
	rra			;6ccf
	call SUMA_A_HL		;6cd0
	ld (hl),0c3h		;6cd3   ; fila 0xC3: fuera de la pantalla
	ret			;6cd5
GOLPE_AL_TIPO_17:		; El tipo 0x11 baja a estado dos y explota
	ld hl,(0e310h)		;6cd6
	inc l			;6cd9   ; byte +2 a 2: la primera pieza esta explotando
	inc l			;6cda
	ld (hl),002h		;6cdb
	jp EXPLOTA		;6cdd
GOLPE_AL_TIPO_11:		; El tipo 0x13 baja su segunda pieza a estado dos
	ld hl,(0e310h)		;6ce0
	ld de,0000bh		;6ce3   ; byte +11 a 2: la segunda pieza esta explotando
	add hl,de			;6ce6
	ld (hl),002h		;6ce7
	jp EXPLOTA		;6ce9
GOLPE_CON_AVISO:		; Los tipos 0x0D a 0x0F avisan antes de romperse
	call OBJETO_A_EXPLOSION		;6cec   ; el objeto explota como cualquier otro...
	ld hl,0e1dah		;6cef   ; ...pero ademas cuenta para la tanda
	inc (hl)			;6cf2
	ld a,(0e191h)		;6cf3   ; 0xE191 son los enemigos que quedan por salir
	and a			;6cf6
	ret nz			;6cf7
	ld a,(hl)			;6cf8
	cp 005h		;6cf9   ; tumbar los cinco de la tanda vale mil puntos
	ret nz			;6cfb
	ld de,01000h		;6cfc
	call SUMA_PUNTOS		;6cff
	ld hl,(0e310h)		;6d02   ; y el ultimo se convierte en el premio de tipo 0x10
	ld (hl),010h		;6d05
	ret			;6d07
ARRANCA_EXPLOSION:		; Pone el hueco en modo explosion
	inc l			;6d08   ; byte +2: cual de las dos explosiones toca
	inc l			;6d09
	ld a,(hl)			;6d0a
	dec l			;6d0b
	dec l			;6d0c
	dec a			;6d0d   ; con el +2 a cero no hay explosion: el hueco se vacia
	jp m,VACIA_HUECO		;6d0e
	ld b,a			;6d11
	add a,a			;6d12   ; cinco bytes por explosion
	add a,a			;6d13
	add a,b			;6d14
	ld de,06d2ch		;6d15
	call SUMA_A_DE		;6d18
	ld a,(de)			;6d1b   ; byte +0: el tipo del premio, 0x10 o 0x11
	ld (hl),a			;6d1c
	inc l			;6d1d
	inc de			;6d1e
	ld (hl),007h		;6d1f   ; byte +1 a 7: la rutina que no hace nada, o sea que solo cae
	ld a,00bh		;6d21   ; de +1 a +12
	add a,l			;6d23
	ld l,a			;6d24
	ex de,hl			;6d25
	ld bc,00004h		;6d26   ; y los cuatro bytes de patrones y colores
	ldir		;6d29
	ret			;6d2b

; ----------------------------------------------------------------------
; DATOS tabla_explosion: Dos explosiones de cinco bytes: el primer patron y
;   los cuatro de cola del hueco
;   0x6d2c..0x6d36  (10 bytes)
DATA_tabla_explosion:
	defb 010h,0a8h,00fh,0ach,001h	; 6d2c
	defb 011h,0b0h,001h,0b4h,00fh	; 6d31

; ======================================================================
; CODIGO 0x6d36..0x6d62  (44 bytes)
; ======================================================================


APAGA_HUECO:		; Vacia el hueco, salvo que sea el tipo 5, que deja premio
	ld hl,(0e310h)		;6d36   ; byte +0: el tipo
	ld a,(hl)			;6d39
	cp 00ah		;6d3a   ; el tipo 10 tiene que soltar antes su disparo fijo
	push af			;6d3c
	call z,MARCA_MUERTO		;6d3d
	pop af			;6d40
	cp 005h		;6d41   ; y el tipo 5 no se vacia: se convierte en el premio que le toque
	jr z,$-59		;6d43
VACIA_HUECO:		; Pone el hueco a cero y apaga sus dos fichas
	ld (hl),000h		;6d45   ; hueco libre
	ld de,0e194h		;6d47   ; un objeto vivo menos
	ld a,(de)			;6d4a
	dec a			;6d4b
	ld (de),a			;6d4c
	ld a,l			;6d4d   ; el nibble alto del hueco, partido por dos: ocho bytes por hueco
	rra			;6d4e
	and 078h		;6d4f
	ld hl,0e0d4h		;6d51   ; 0xE0D4 es la primera ficha de los objetos
	add a,l			;6d54
	ld l,a			;6d55
	jr nc,APAGA_DOS_FICHAS		;6d56   ; el acarreo sube de pagina
	inc h			;6d58
APAGA_DOS_FICHAS:		; Deja 0xC3 en las dos fichas de sprite del hueco
	ld (hl),0c3h		;6d59   ; las dos fichas del hueco, con la fila 0xC3, se van de la pantalla
	inc hl			;6d5b
	inc hl			;6d5c
	inc hl			;6d5d
	inc hl			;6d5e
	ld (hl),0c3h		;6d5f
	ret			;6d61

; ----------------------------------------------------------------------
; DATOS tabla_puntos_por_objeto: Lo que vale cada tipo, en BCD de 16 bits
;   (base 0x6D60, tipos 1 a 17)
;   0x6d62..0x6d84  (34 bytes)
DATA_tabla_puntos_por_objeto:
	defw 00050h,00080h	; 6d62
	defw 00080h,00050h	; 6d66
	defw 00020h,00070h	; 6d6a
	defw 00000h,00100h	; 6d6e
	defw 00100h,00050h	; 6d72
	defw 00100h,00000h	; 6d76
	defw 00050h,00080h	; 6d7a
	defw 00080h,01000h	; 6d7e
	defw 00000h	; 6d82

; ======================================================================
; CODIGO 0x6d84..0x6dca  (70 bytes)
; ======================================================================


CARGA_PAISAJE:		; Descomprime los caracteres del paisaje y sus colores
	ld de,06dcah		;6d84   ; el guion de los caracteres del paisaje...
	ld hl,02200h		;6d87   ; ...que van a 0x2200, o sea al caracter 0x40
	call DESC_TRES		;6d8a
	ld de,0702bh		;6d8d   ; y sus colores a 0x0200
	ld hl,00200h		;6d90
	jp DESC_TRES		;6d93
CARGA_GIGANTE:		; Carga los caracteres del enemigo grande que toque
	ld hl,0e1d9h		;6d96   ; 0xE1D9 dice por que paso va la carga
	ld a,(hl)			;6d99
	and a			;6d9a   ; con cero, espera al episodio 1 del gigante
	jr nz,CARGA_GIGANTE_PASO		;6d9b
	ld a,(0e140h)		;6d9d
	dec a			;6da0
	ret nz			;6da1
	ld (hl),001h		;6da2   ; y entonces arranca la carga
	ret			;6da4
CARGA_GIGANTE_PASO:		; Elige el juego de caracteres del gigante que toca
	dec a			;6da5   ; la carga se hace un fotograma despues, para no cargar con el fondo
	ret nz			;6da6
	inc (hl)			;6da7
	ld de,070deh		;6da8   ; los patrones del gigante 1...
	ld a,(0e1d6h)		;6dab
	dec a			;6dae
	jr z,CARGA_PATRONES_GIGANTE		;6daf
	ld de,07323h		;6db1   ; ...o los del gigante 2
CARGA_PATRONES_GIGANTE:		; Los patrones a 0x2580 en los tres tercios
	ld hl,02580h		;6db4   ; los caracteres del gigante van a 0x2580, o sea al 0xB0
	push af			;6db7
	call DESC_TRES		;6db8   ; en los tres tercios
	pop af			;6dbb
	ld de,07285h		;6dbc   ; los colores del gigante 1...
	jr z,CARGA_COLORES_GIGANTE		;6dbf
	ld de,074a7h		;6dc1   ; ...o los del 2
CARGA_COLORES_GIGANTE:		; Y sus colores a 0x0580
	ld hl,00580h		;6dc4   ; y van a 0x0580, la misma altura en la tabla de colores
	jp DESC_TRES		;6dc7

; ----------------------------------------------------------------------
; DATOS patrones_paisaje: Guion comprimido: 832 bytes (104 caracteres, del
;   0x40 al 0xA7) a 0x2200 en los tres tercios
;   0x6dca..0x702b  (609 bytes)
DATA_patrones_paisaje:
	defb 0fdh,000h,000h,019h,00eh,020h,0c0h,008h,004h,012h,002h,004h,044h,00ch,008h,020h	; 6dca  ..... ......D.. 
	defb 000h,008h,04ch,082h,080h,040h,010h,008h,000h,000h,042h,000h,010h,000h,002h,000h	; 6dda  ..L..@....B.....
	defb 008h,000h,000h,080h,004h,04bh,03eh,000h,006h,000h,041h,026h,01ch,000h,020h,090h	; 6dea  .....K>...A&.. .
	defb 010h,000h,080h,0e0h,0e0h,0f8h,0fch,0fch,0feh,0feh,0fch,0fch,0f8h,0e0h,0e0h,080h	; 6dfa  ................
	defb 000h,000h,001h,007h,007h,01fh,03fh,03fh,07fh,07fh,03fh,03fh,01fh,007h,007h,001h	; 6e0a  ......??..??....
	defb 000h,0ffh,07fh,07fh,03fh,03fh,00fh,001h,000h,000h,001h,001h,003h,01fh,03fh,07fh	; 6e1a  ....??........?.
	defb 07fh,0ffh,0feh,0fch,0f0h,0f0h,0f0h,0e0h,0c0h,000h,080h,080h,0c0h,0f8h,0fch,0feh	; 6e2a  ................
	defb 0feh,003h,007h,007h,00fh,00fh,03fh,07fh,0ffh,03fh,01fh,007h,003h,001h,003h,000h	; 6e3a  ......?..?......
	defb 0d4h,0fch,0f8h,0e0h,0c0h,080h,000h,000h,000h,080h,0c0h,0c0h,0e0h,0f8h,0fch,0feh	; 6e4a  ................
	defb 0ffh,000h,000h,018h,004h,04eh,08bh,005h,000h,07fh,07fh,03fh,03fh,01fh,00fh,003h	; 6e5a  .....N.....??...
	defb 003h,003h,007h,007h,00fh,00fh,03fh,07fh,0ffh,080h,080h,0a8h,040h,080h,080h,080h	; 6e6a  ......?.....@...
	defb 040h,0c0h,0f8h,01ch,036h,002h,006h,002h,015h,080h,060h,084h,073h,02ch,007h,002h	; 6e7a  @...6.....`.s,..
	defb 001h,0f0h,0e0h,0e0h,0c0h,0c0h,080h,080h,000h,0ffh,0fch,0e8h,0c0h,080h,0c0h,0c0h	; 6e8a  ................
	defb 080h,000h,080h,000h,000h,004h,080h,083h,0ffh,0f8h,0c0h,005h,000h,0b0h,004h,002h	; 6e9a  ................
	defb 001h,000h,084h,042h,042h,063h,020h,030h,008h,00ch,006h,002h,001h,001h,004h,00ah	; 6eaa  ...BBc 0........
	defb 00bh,094h,064h,08ah,072h,063h,040h,03eh,090h,04fh,028h,0afh,084h,0d6h,0f8h,003h	; 6eba  ..d.rc@>.O(.....
	defb 001h,001h,001h,007h,01dh,02ah,003h,00fh,01fh,03fh,03fh,07fh,07fh,03fh,008h,001h	; 6eca  .....*...??..?..
	defb 007h,000h,0b1h,0ffh,04eh,02ah,099h,00ah,005h,002h,001h,040h,002h,028h,008h,040h	; 6eda  ....N*.....@.(.@
	defb 000h,008h,002h,000h,040h,044h,010h,010h,002h,050h,044h,000h,0f6h,0bch,078h,0f1h	; 6eea  ....@D...PD...x.
	defb 0a0h,0c4h,080h,000h,031h,018h,066h,091h,043h,06dh,082h,031h,000h,00ch,040h,003h	; 6efa  ....1.f.Cm.1..@.
	defb 030h,000h,066h,000h,008h,000h,081h,0e7h,006h,021h,002h,0e7h,003h,021h,001h,0e7h	; 6f0a  0.f......!...!..
	defb 003h,000h,081h,0ffh,007h,000h,008h,080h,098h,0c0h,000h,000h,006h,000h,000h,030h	; 6f1a  ...............0
	defb 000h,080h,0c0h,060h,0f0h,098h,0fch,066h,0d9h,001h,003h,006h,00fh,019h,03fh,066h	; 6f2a  ...`...f......?f
	defb 0bfh,040h,000h,040h,000h,0a9h,0feh,0fch,0f8h,0f0h,0e0h,0c0h,080h,000h,000h,001h	; 6f3a  .@.@............
	defb 003h,007h,00fh,01fh,03fh,07fh,000h,080h,0c0h,0e0h,0f0h,0f8h,0fch,0feh,07fh,03fh	; 6f4a  ....?..........?
	defb 01fh,00fh,007h,003h,001h,000h,000h,018h,03ch,016h,03eh,01ch,000h,000h,078h,006h	; 6f5a  ........<.>...x.
	defb 008h,092h,078h,000h,0ffh,000h,000h,000h,0ffh,000h,000h,000h,0ffh,001h,001h,001h	; 6f6a  ..x.............
	defb 0ffh,000h,000h,01eh,016h,002h,086h,04eh,000h,0eeh,022h,022h,0eeh,004h,000h,081h	; 6f7a  .......N..""....
	defb 006h,004h,000h,08bh,0c0h,000h,000h,002h,002h,000h,000h,000h,040h,040h,0ffh,00fh	; 6f8a  ............@@..
	defb 080h,081h,0ffh,007h,000h,081h,0ffh,00fh,001h,007h,000h,081h,0ffh,007h,001h,081h	; 6f9a  ................
	defb 0ffh,007h,080h,0d8h,07fh,0ffh,0eeh,022h,022h,0eeh,0ffh,0ffh,0ffh,000h,058h,07ch	; 6faa  ......."".....X|
	defb 0d7h,001h,00ah,045h,03eh,000h,001h,001h,003h,01fh,03fh,07fh,07fh,000h,080h,080h	; 6fba  ...E>.....?.....
	defb 0c0h,0f8h,0fch,0feh,0f7h,001h,003h,01fh,03fh,03fh,07fh,0ffh,0ffh,000h,001h,001h	; 6fca  ........??......
	defb 003h,01fh,03fh,07fh,07fh,000h,080h,080h,0c0h,0f8h,0fch,0feh,0feh,000h,001h,001h	; 6fda  ..?.............
	defb 003h,01fh,03fh,07fh,07fh,000h,080h,080h,0c0h,0f8h,0fch,0feh,0feh,07fh,07fh,03fh	; 6fea  ..?............?
	defb 01fh,003h,001h,001h,000h,0feh,0feh,0fch,0f8h,0c0h,080h,080h,007h,000h,082h,00ch	; 6ffa  ................
	defb 013h,003h,001h,002h,003h,083h,002h,016h,01bh,003h,000h,003h,080h,092h,0d0h,0b0h	; 700a  ................
	defb 093h,0a3h,0c3h,082h,082h,08ah,002h,001h,092h,08ah,086h,082h,082h,0a2h,080h,000h	; 701a  ................
	defb 000h	; 702a

; ----------------------------------------------------------------------
; DATOS colores_paisaje: Guion comprimido: sus 832 bytes de color, a 0x0200 en
;   los tres tercios
;   0x702b..0x70de  (179 bytes)
DATA_colores_paisaje:
	defb 024h,01ch,081h,013h,006h,01ch,081h,013h,004h,01ch,020h,0bch,020h,0b5h,028h,089h	; 702b  $......... . .(.
	defb 010h,068h,088h,098h,0f8h,098h,0f8h,018h,0f8h,098h,018h,008h,096h,005h,018h,043h	; 703b  .h.............C
	defb 016h,003h,096h,005h,016h,082h,0f6h,096h,005h,086h,081h,08fh,010h,0fah,088h,0f9h	; 704b  ................
	defb 0e9h,0f9h,0e9h,0f9h,0e9h,0f9h,0e9h,008h,098h,008h,0e9h,090h,098h,0e8h,098h,098h	; 705b  ................
	defb 0e8h,098h,0f8h,0f8h,0f9h,0e9h,0f9h,0e9h,0f9h,0e9h,0f9h,0e9h,010h,096h,081h,0fbh	; 706b  ................
	defb 006h,019h,082h,01ah,0fah,003h,019h,004h,01ah,081h,011h,00fh,01ah,008h,0bah,008h	; 707b  ................
	defb 068h,008h,069h,030h,000h,070h,057h,008h,0c5h,081h,075h,007h,045h,005h,075h,003h	; 708b  h.i0.pW...u.E.u.
	defb 045h,002h,075h,006h,045h,081h,075h,017h,045h,002h,075h,006h,045h,006h,067h,003h	; 709b  E.u.E.u.E.u.E.g.
	defb 047h,005h,0c7h,002h,067h,019h,0f5h,01fh,015h,007h,0f5h,083h,01fh,0beh,0f5h,003h	; 70ab  G...g...........
	defb 015h,003h,0b5h,004h,0cbh,003h,01ch,081h,01bh,010h,095h,008h,096h,010h,095h,020h	; 70bb  ............... 
	defb 0a5h,007h,0f5h,083h,075h,040h,040h,00eh,0f0h,006h,0f4h,082h,0f0h,040h,006h,0f4h	; 70cb  ....u@@......@..
	defb 002h,0f0h,000h	; 70db

; ----------------------------------------------------------------------
; DATOS patrones_gigante_1: Guion comprimido: 488 bytes (61 caracteres, del
;   0xB0 al 0xEC) a 0x2580; el enemigo grande numero 1
;   0x70de..0x7285  (423 bytes)
DATA_patrones_gigante_1:
	defb 0d1h,001h,003h,007h,00fh,01fh,03fh,07fh,0ffh,0ffh,07fh,03fh,01fh,00fh,007h,003h	; 70de  ......?....?....
	defb 001h,03ch,076h,0dfh,0bdh,02bh,0f5h,05ah,03ch,080h,0c0h,0e0h,0f0h,0f8h,0fch,0feh	; 70ee  .<v..+.Z<.......
	defb 0ffh,0ffh,0feh,0fch,0f8h,0f0h,0e0h,0c0h,080h,0f5h,0eah,0d4h,0a8h,050h,0a0h,040h	; 70fe  .............P.@
	defb 080h,080h,040h,0a0h,050h,0a8h,0d4h,0eah,0f5h,001h,006h,00ch,018h,030h,060h,0c0h	; 710e  ..@.P........0`.
	defb 080h,080h,040h,060h,030h,038h,01ch,00eh,007h,007h,00eh,01ch,038h,030h,060h,040h	; 711e  ..@`08......80`@
	defb 080h,0ffh,007h,002h,006h,0e0h,0bdh,0ffh,080h,0afh,057h,02bh,015h,00ah,005h,002h	; 712e  ..........W+....
	defb 001h,001h,002h,005h,00ah,015h,02bh,057h,0afh,080h,060h,030h,01ch,00eh,007h,003h	; 713e  ......+W..`0....
	defb 001h,001h,002h,006h,00ch,01ch,038h,070h,0e0h,0e0h,070h,038h,01ch,00ch,006h,002h	; 714e  ......8p..p8....
	defb 001h,001h,003h,007h,00eh,01ch,038h,060h,080h,080h,0c0h,0e0h,070h,038h,01ch,006h	; 715e  ......8`....p8..
	defb 001h,001h,003h,0ffh,005h,083h,004h,0c0h,0e7h,000h,0ffh,0fbh,0d5h,03fh,068h,0c8h	; 716e  .............?h.
	defb 0c4h,0c4h,0a2h,0b1h,08fh,0fch,026h,083h,081h,087h,0b8h,0c0h,0e0h,081h,082h,084h	; 717e  ......&.........
	defb 098h,0e1h,0c2h,064h,03fh,0d8h,0e4h,0a3h,0b1h,011h,011h,012h,0fch,03fh,064h,0c2h	; 718e  ...d?........?d.
	defb 081h,0c1h,0bfh,087h,086h,0fch,012h,021h,021h,0e1h,0e6h,0f4h,0f8h,08fh,097h,0a7h	; 719e  .......!!.......
	defb 0c3h,082h,084h,044h,03fh,0b0h,050h,0bch,0e3h,041h,021h,012h,0fch,03fh,064h,083h	; 71ae  ...D?.P..A!..?d.
	defb 08fh,0ffh,09dh,09fh,0beh,0fch,012h,0e1h,0f1h,0f9h,0ebh,0beh,0d4h,0bfh,0bdh,0dfh	; 71be  ................
	defb 09dh,08fh,08bh,048h,03fh,0ach,048h,0bch,06fh,0f9h,0e1h,042h,0fch,007h,007h,000h	; 71ce  ...H?.H.o..B....
	defb 005h,007h,002h,0e0h,081h,000h,005h,0e0h,003h,038h,00ah,0ffh,003h,038h,005h,007h	; 71de  .........8...8..
	defb 083h,000h,007h,007h,005h,0e0h,083h,000h,0e0h,0e0h,003h,01ch,00ah,080h,003h,01ch	; 71ee  ................
	defb 081h,0ffh,007h,000h,008h,080h,0b4h,007h,006h,005h,007h,006h,007h,087h,0c0h,0e0h	; 71fe  ................
	defb 0a0h,040h,0a0h,0c0h,0a0h,0e0h,0ffh,0f7h,0f7h,005h,002h,005h,006h,003h,007h,0dfh	; 720e  .@..............
	defb 0dfh,040h,0c0h,040h,0c0h,040h,0c0h,003h,001h,000h,000h,0ffh,0ffh,05fh,037h,057h	; 721e  .@.@.@......._7W
	defb 03bh,057h,0ffh,000h,000h,001h,003h,0ebh,0d5h,0ebh,03fh,004h,0c0h,082h,0e0h,060h	; 722e  ;W........?....`
	defb 006h,020h,082h,080h,0c0h,006h,0e0h,005h,083h,002h,003h,081h,001h,005h,020h,083h	; 723e  . ............ .
	defb 01fh,07fh,0ffh,005h,002h,002h,0feh,085h,0ffh,03fh,07fh,0f0h,0e0h,004h,0c0h,088h	; 724e  .........?......
	defb 0fch,0feh,007h,003h,001h,000h,07eh,0fch,005h,0c0h,085h,0e0h,070h,03fh,0e3h,080h	; 725e  ......~.....p?..
	defb 003h,000h,093h,001h,002h,0fch,080h,0c0h,0e0h,0f0h,0f8h,0fch,0feh,0ffh,0ffh,0feh	; 726e  ................
	defb 0fch,0f8h,0f0h,0e0h,0c0h,080h,000h	; 727e

; ----------------------------------------------------------------------
; DATOS colores_gigante_1: Sus 488 bytes de color, a 0x0580 en los tres
;   tercios
;   0x7285..0x7323  (158 bytes)
DATA_colores_gigante_1:
	defb 010h,0f5h,004h,01eh,084h,016h,019h,01eh,01eh,010h,045h,038h,0feh,07fh,01eh,010h	; 7285  ..........E8....
	defb 01eh,081h,019h,005h,01eh,002h,019h,002h,01eh,081h,019h,006h,01eh,084h,019h,01eh	; 7295  ................
	defb 019h,016h,004h,01eh,003h,04fh,002h,0efh,081h,01fh,005h,04fh,002h,0efh,083h,01fh	; 72a5  .....O.....O....
	defb 04fh,04fh,003h,0e4h,005h,0f1h,005h,0f4h,003h,0e4h,083h,04fh,041h,0f1h,003h,0e1h	; 72b5  OO.........OA...
	defb 002h,041h,083h,04fh,041h,0f1h,003h,0e1h,002h,041h,003h,0e4h,00ah,0f1h,003h,0e4h	; 72c5  .A.OA....A......
	defb 010h,0f1h,081h,0feh,006h,01eh,082h,01fh,0feh,006h,01eh,081h,0feh,010h,01eh,005h	; 72d5  ................
	defb 0feh,006h,01eh,005h,0feh,003h,01eh,081h,0feh,004h,01eh,081h,01fh,007h,01eh,002h	; 72e5  ................
	defb 0feh,081h,0f1h,005h,0feh,006h,01eh,081h,01fh,006h,01eh,083h,0feh,01eh,01eh,006h	; 72f5  ................
	defb 0feh,002h,01fh,002h,01eh,006h,016h,002h,01eh,004h,016h,002h,086h,083h,016h,018h	; 7305  ................
	defb 018h,004h,019h,081h,01eh,005h,089h,002h,019h,081h,01eh,010h,014h,000h	; 7315  ..............

; ----------------------------------------------------------------------
; DATOS patrones_gigante_2: Lo mismo para el enemigo grande numero 2
;   0x7323..0x74a7  (388 bytes)
DATA_patrones_gigante_2:
	defb 003h,000h,08dh,003h,00fh,01fh,03fh,07fh,000h,001h,003h,007h,00fh,00fh,01fh,01fh	; 7323  ......?.........
	defb 003h,03fh,004h,07fh,002h,0ffh,004h,07fh,003h,03fh,081h,0ffh,004h,0feh,003h,0fch	; 7333  .?.......?......
	defb 002h,01fh,002h,00fh,089h,007h,003h,001h,000h,07fh,03fh,01fh,00fh,003h,003h,000h	; 7343  ..........?.....
	defb 006h,0ffh,0b2h,01fh,001h,000h,03ch,018h,081h,099h,081h,05ah,042h,042h,05ah,081h	; 7353  ......<....ZBBZ.
	defb 099h,081h,018h,03ch,000h,01ch,003h,040h,06ah,06ah,040h,003h,01ch,038h,0c0h,002h	; 7363  ...<...@jj@..8..
	defb 056h,056h,002h,0c0h,038h,000h,0f0h,0feh,0c0h,0f0h,0f8h,0fch,0feh,0feh,080h,0c0h	; 7373  VV..8...........
	defb 0e0h,0f0h,0f0h,0f8h,0f8h,003h,0fch,004h,0feh,007h,0ffh,0c5h,0f8h,080h,0f8h,0f8h	; 7383  ................
	defb 0f0h,0f0h,0e0h,0c0h,080h,0feh,0feh,0fch,0f8h,0f0h,0c0h,0feh,0f0h,000h,001h,01fh	; 7393  ................
	defb 0ffh,0f8h,0c3h,01fh,07fh,0ffh,080h,0f8h,0ffh,03fh,0efh,0fbh,0ffh,0ffh,0feh,0fdh	; 73a3  .........?......
	defb 0f8h,0f0h,0e0h,0c6h,086h,0e0h,07fh,0bfh,01fh,00fh,007h,063h,061h,007h,0e0h,086h	; 73b3  ...........ca...
	defb 0c6h,0e0h,0f0h,0f8h,0fdh,0feh,007h,061h,063h,007h,00fh,01fh,0bfh,07fh,0ffh,0ffh	; 73c3  .......ac.......
	defb 04fh,005h,0ffh,098h,0f7h,0efh,0dfh,0ffh,001h,003h,007h,00fh,010h,030h,070h,0f0h	; 73d3  O............0p.
	defb 0f0h,0e0h,0c0h,080h,008h,00ch,00eh,00fh,00fh,007h,003h,001h,004h,000h,088h,080h	; 73e3  ................
	defb 0c0h,0e0h,0f0h,01fh,03eh,07ch,0f8h,004h,000h,084h,0f8h,07ch,03eh,01fh,008h,000h	; 73f3  ....>|.....|>...
	defb 084h,0f8h,07ch,03eh,01fh,004h,000h,088h,01fh,03eh,07ch,0f8h,00fh,007h,003h,001h	; 7403  ..|>.....>|.....
	defb 004h,000h,084h,0f0h,0e0h,0c0h,080h,004h,000h,090h,080h,0c0h,0e0h,0f0h,0f0h,070h	; 7413  ...............p
	defb 030h,010h,001h,003h,007h,00fh,00fh,00eh,00ch,008h,006h,000h,004h,0ffh,081h,000h	; 7423  0...............
	defb 005h,0ffh,002h,0f8h,003h,0ffh,085h,000h,0ffh,0ffh,000h,000h,003h,0ffh,081h,000h	; 7433  ................
	defb 005h,0ffh,002h,0fch,003h,0f8h,085h,0fch,0f8h,0f0h,0e0h,080h,006h,000h,08bh,080h	; 7443  ................
	defb 0e0h,0f0h,0f8h,0fch,0f0h,0e0h,0e0h,0c0h,0c0h,080h,004h,000h,08eh,080h,0c0h,0c0h	; 7453  ................
	defb 0e0h,0e0h,0f0h,03ch,076h,0dfh,0bdh,0d3h,0e9h,052h,03ch,008h,0feh,008h,07fh,081h	; 7463  ...<v....R<.....
	defb 000h,005h,0ffh,003h,000h,007h,0ffh,081h,000h,007h,0feh,081h,0c0h,007h,01fh,081h	; 7473  ................
	defb 003h,007h,0f8h,003h,0ffh,005h,000h,003h,0f8h,004h,0fch,002h,0feh,004h,0fch,003h	; 7483  ................
	defb 0f8h,081h,0ffh,007h,010h,006h,0ffh,002h,000h,081h,0ffh,005h,000h,004h,0ffh,002h	; 7493  ................
	defb 000h,004h,0ffh,000h	; 74a3

; ----------------------------------------------------------------------
; DATOS colores_gigante_2: Y sus colores
;   0x74a7..0x7522  (123 bytes)
DATA_colores_gigante_2:
	defb 020h,015h,008h,014h,018h,015h,020h,0efh,003h,045h,005h,014h,081h,045h,01eh,014h	; 74a7   ..... ..E...E..
	defb 081h,045h,005h,014h,003h,045h,003h,015h,005h,01fh,003h,014h,00ch,01fh,081h,0efh	; 74b7  .E...E..........
	defb 007h,01fh,002h,0efh,007h,01fh,081h,0efh,013h,01fh,05ch,061h,081h,059h,007h,051h	; 74c7  ..........\a.Y.Q
	defb 002h,041h,006h,01fh,005h,045h,003h,01fh,005h,045h,006h,01fh,025h,045h,004h,01fh	; 74d7  .A...E...E..%E..
	defb 084h,016h,018h,01fh,01fh,010h,019h,006h,01fh,002h,015h,008h,016h,002h,08fh,002h	; 74e7  ................
	defb 06fh,003h,08fh,085h,09fh,0f6h,018h,016h,016h,003h,018h,085h,019h,0f6h,018h,016h	; 74f7  o...............
	defb 016h,003h,018h,081h,019h,008h,015h,010h,045h,008h,061h,008h,015h,006h,091h,002h	; 7507  ........E.a.....
	defb 051h,081h,0f8h,003h,086h,084h,068h,086h,086h,09fh,000h	; 7517  Q.....h....

; ======================================================================
; CODIGO 0x7522..0x757c  (90 bytes)
; ======================================================================


ARRANCA_OLEADAS:		; Coloca la oleada que corresponde a la posicion de la fase
	ld hl,(0e1b8h)		;7522   ; al empezar una vida, la oleada que toque a esa altura
	jr COLOCA_OLEADA		;7525
REVISA_OLEADA:		; Cada 64 filas de avance, cambia de oleada
	ld hl,(0e1b8h)		;7527   ; y luego, cada 64 filas de fase
	ld a,l			;752a
	and 03fh		;752b
	ret nz			;752d
COLOCA_OLEADA:		; Deja la oleada del tramo en 0xE320 y la copia a 0xE321
	xor a			;752e   ; ni enemigo pendiente, ni cuenta de reparto, ni contador de disparos
	ld (0e1b0h),a		;752f
	ld (0e1c1h),a		;7532
	ld (0e1d2h),a		;7535
	ld a,l			;7538   ; los seis rr h / rra parten la posicion entre 64: el tramo
	rr h		;7539
	rra			;753b
	rr h		;753c
	rra			;753e
	rr h		;753f
	rra			;7541
	rr h		;7542
	rra			;7544
	rr h		;7545
	rra			;7547
	rr h		;7548
	rra			;754a
	ld hl,0757ch		;754b   ; 32 tramos, uno por cada 64 filas
	call SUMA_A_HL		;754e
	ld a,(hl)			;7551
	ld (0e320h),a		;7552   ; 0xE320 se queda la oleada
	add a,a			;7555   ; seis bytes por oleada
	ld b,a			;7556
	add a,a			;7557
	add a,b			;7558
	ld de,0759ch		;7559   ; la tabla de las 25 oleadas
	call SUMA_A_DE		;755c
	ld b,002h		;755f   ; dos tandas por oleada
	ld hl,0e321h		;7561   ; las tandas viven en 0xE321, seis bytes cada una
COPIA_TANDA:		; Copia una tanda de tres bytes, intercalando ceros
	ld a,(de)			;7564   ; +0 el tipo de enemigo...
	ld (hl),a			;7565
	inc l			;7566
	inc de			;7567
	ld (hl),000h		;7568   ; ...+1 la cuenta atras, que arranca a cero...
	inc l			;756a
	ld a,(de)			;756b   ; ...+2 la secuencia de esperas entre enemigos...
	ld (hl),a			;756c
	inc l			;756d
	inc de			;756e
	ld (hl),000h		;756f   ; ...+3 el paso dentro de esa secuencia...
	inc l			;7571
	ld a,(de)			;7572   ; ...+4 la secuencia de esperas entre disparos...
	ld (hl),a			;7573
	inc l			;7574
	inc de			;7575
	ld (hl),000h		;7576   ; ...y +5 el paso dentro de esa
	inc l			;7578
	djnz COPIA_TANDA		;7579
	ret			;757b

; ----------------------------------------------------------------------
; DATOS tabla_oleada_por_tramo: Que oleada (0 a 24) toca en cada uno de los 32
;   tramos de la fase
;   0x757c..0x759c  (32 bytes)
DATA_tabla_oleada_por_tramo:
	defb 000h,002h,001h,005h,009h,006h,002h,016h,007h,014h,001h,00bh,004h,007h,008h,017h	; 757c  ................
	defb 00ch,00ah,015h,012h,00eh,00dh,009h,018h,010h,00fh,011h,013h,015h,014h,018h,018h	; 758c  ................

; ----------------------------------------------------------------------
; DATOS tabla_oleadas: Veinticinco oleadas de seis bytes: dos tandas de tres,
;   y cada tanda es tipo de enemigo, secuencia de esperas entre enemigos y
;   secuencia de esperas entre disparos
;   0x759c..0x7632  (150 bytes)
DATA_tabla_oleadas:
	defb 001h,000h,000h,000h,000h,000h	; 759c
	defb 002h,000h,000h,000h,000h,000h	; 75a2
	defb 005h,006h,006h,000h,000h,000h	; 75a8
	defb 003h,000h,000h,000h,000h,000h	; 75ae
	defb 009h,018h,010h,000h,000h,000h	; 75b4
	defb 004h,00ah,005h,000h,000h,000h	; 75ba
	defb 00ah,01bh,00dh,001h,000h,000h	; 75c0
	defb 003h,000h,001h,005h,006h,006h	; 75c6
	defb 004h,00bh,007h,000h,000h,000h	; 75cc
	defb 002h,002h,002h,000h,000h,000h	; 75d2
	defb 006h,00fh,007h,000h,000h,000h	; 75d8
	defb 002h,000h,000h,005h,006h,006h	; 75de
	defb 003h,001h,002h,000h,000h,000h	; 75e4
	defb 007h,012h,00ah,000h,000h,000h	; 75ea
	defb 001h,001h,001h,000h,000h,000h	; 75f0
	defb 002h,001h,001h,004h,007h,007h	; 75f6
	defb 00bh,01eh,002h,000h,000h,000h	; 75fc
	defb 008h,015h,00dh,000h,000h,000h	; 7602
	defb 004h,00ah,005h,005h,005h,005h	; 7608
	defb 003h,002h,002h,005h,007h,007h	; 760e
	defb 005h,005h,005h,000h,000h,000h	; 7614
	defb 002h,001h,001h,005h,006h,006h	; 761a
	defb 00dh,013h,00ch,000h,000h,000h	; 7620
	defb 00eh,013h,00ch,000h,000h,000h	; 7626
	defb 00fh,013h,00ch,000h,000h,000h	; 762c

; ======================================================================
; CODIGO 0x7632..0x767a  (72 bytes)
; ======================================================================


TOCA_OLEADA:		; Cuenta atras de las dos tandas y saca el siguiente enemigo
	ld b,002h		;7632   ; las dos tandas de la oleada
	ld hl,0e321h		;7634
TANDA_CUENTA:		; Baja la cuenta atras de esta tanda
	ld a,(hl)			;7637   ; +0 a cero: tanda vacia
	inc l			;7638
	and a			;7639
	jr z,TANDA_SIGUIENTE		;763a
	dec (hl)			;763c   ; +1 es la cuenta atras hasta el proximo enemigo
	jr z,SACA_DE_LA_TANDA		;763d
TANDA_SIGUIENTE:		; Cinco bytes mas alla esta la otra tanda
	ld de,00005h		;763f   ; seis bytes a la otra tanda
	add hl,de			;7642
	djnz TANDA_CUENTA		;7643
	scf			;7645   ; acarreo puesto: ninguna tanda ha soltado nada
	ret			;7646
SACA_DE_LA_TANDA:		; Coge el enemigo siguiente de la secuencia de esta tanda
	ld (0e1b0h),a		;7647   ; 0xE1B0 se queda el tipo que toca
	inc l			;764a
	ld a,(0e1d3h)		;764b   ; la dificultad corre la secuencia: cada vuelta es otra lista de esperas
	add a,(hl)			;764e
	add a,a			;764f
	ld de,0767ah		;7650   ; los 33 punteros de 0x767A
	call SUMA_A_DE		;7653
	inc l			;7656
	ld a,(hl)			;7657   ; +3 es el paso dentro de la secuencia, y sube uno
	inc (hl)			;7658
	push hl			;7659
	ex de,hl			;765a
	ld e,(hl)			;765b
	inc hl			;765c
	ld d,(hl)			;765d
	ex de,hl			;765e
	ld c,(hl)			;765f   ; C se guarda el primer byte por si hay que volver al principio
	call SUMA_A_HL		;7660
	ld a,(hl)			;7663
	pop hl			;7664
	cp 0ffh		;7665   ; 0xFF acaba la secuencia...
	jr nz,GUARDA_ENEMIGO		;7667
	ld a,c			;7669
	ld (hl),000h		;766a   ; ...y la devuelve al primer paso
GUARDA_ENEMIGO:		; Deja el enemigo elegido y su dificultad
	dec l			;766c
	dec l			;766d
	ld (hl),a			;766e   ; +1: la espera hasta el enemigo siguiente
	ld hl,0e1b7h		;766f   ; 0xE1B7 es la cuenta hasta el primer disparo del enemigo que viene
	ld a,(0e1b0h)		;7672
	call BUSCA_EN_LA_TANDA		;7675   ; que sale de la otra secuencia, la de 0x770F
	xor a			;7678
	ret			;7679

; ----------------------------------------------------------------------
; DATOS tabla_secuencias_a: Treinta y tres punteros a las secuencias de
;   ESPERAS entre enemigo y enemigo; el indice es la dificultad mas el byte +2
;   de la tanda
;   0x767a..0x76bc  (66 bytes)
DATA_tabla_secuencias_a:
	defw 076bch,076c1h,076c7h,076cdh,076d3h,076d9h,076dbh,076ddh	; 767a
	defw 076dfh,076e1h,076bch,076c1h,076c7h,076cdh,076d3h,076e3h	; 768a
	defw 076e8h,076eeh,076f4h,076f4h,076f4h,076c7h,076cdh,076d3h	; 769a
	defw 076ddh,076dfh,076e1h,076f6h,076f9h,076fch,076ffh,07704h	; 76aa
	defw 07709h	; 76ba

; ----------------------------------------------------------------------
; DATOS secuencias_a: Las esperas: un byte por enemigo de la tanda, y 0xFF
;   vuelve al principio
;   0x76bc..0x770f  (83 bytes)
DATA_secuencias_a:
	defb 018h,018h,018h,060h,0ffh,014h,014h,014h,014h,058h,0ffh,010h,010h,010h,010h,050h	; 76bc  ...`.....X.....P
	defb 0ffh,00ch,00ch,00ch,00ch,048h,0ffh,00ah,00ah,00ah,00ah,040h,0ffh,060h,0ffh,050h	; 76cc  .....H.....@.`.P
	defb 0ffh,040h,0ffh,038h,0ffh,030h,0ffh,01ch,018h,020h,060h,0ffh,018h,018h,018h,018h	; 76dc  .@.8.0... `.....
	defb 050h,0ffh,016h,016h,016h,016h,030h,0ffh,058h,0ffh,040h,0c0h,0ffh,038h,080h,0ffh	; 76ec  P.....0.X.@..8..
	defb 030h,060h,0ffh,018h,020h,020h,060h,0ffh,020h,020h,018h,050h,0ffh,018h,020h,028h	; 76fc  0`..  `.  .P.. (
	defb 020h,040h,0ffh	; 770c

; ----------------------------------------------------------------------
; DATOS tabla_secuencias_b: Veinte punteros a las secuencias de esperas ENTRE
;   DISPARO Y DISPARO, que usa 0x670D
;   0x770f..0x7737  (40 bytes)
DATA_tabla_secuencias_b:
	defw 07737h,07739h,0773ch,07740h,07744h,07749h,0774bh,0774dh	; 770f
	defw 0774fh,07751h,07737h,07737h,07737h,07753h,07757h,0775bh	; 771f
	defw 0775eh,07760h,07762h,07764h	; 772f

; ----------------------------------------------------------------------
; DATOS secuencias_b: Las esperas entre disparos, tambien acabadas en 0xFF
;   0x7737..0x7766  (47 bytes)
DATA_secuencias_b:
	defb 000h,0ffh,040h,048h,0ffh,038h,030h,02ch,0ffh,020h,028h,030h,0ffh,020h,010h,018h	; 7737  ..@H.80,. (0. ..
	defb 020h,0ffh,060h,0ffh,050h,0ffh,030h,0ffh,028h,0ffh,020h,0ffh,030h,028h,038h,0ffh	; 7747   .`.P.0.(. .0(8.
	defb 028h,020h,030h,0ffh,020h,018h,0ffh,01ah,0ffh,016h,0ffh,010h,0ffh,0feh,0ffh	; 7757  ( 0. ..........

; ======================================================================
; CODIGO 0x7766..0x7828  (194 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; EL ENEMIGO GRANDE. Va en dos mitades: el CUERPO lo pinta el fondo (las tiras de tipo 18 y 19, caracteres 0xB0-0xEC, unicas del mapa) y encima van CUATRO (o dos) SPRITES de 0xE150, que son las piezas a las que se dispara. 0x7766 lo arranca tres pasos antes de que el cuerpo entre en pantalla: en el indice 0x47 del mapa el gigante 1 (el cuerpo llega en 0x4A) y en 0xE7 el 2 (llega en 0xEA).
; ----------------------------------------------------------------------
EPISODIO_GIGANTE:		; Un paso del episodio del enemigo grande (0xE140)
	ld a,(0e003h)		;7766   ; el episodio del gigante se mueve una vez cada 16 fotogramas
	and 00fh		;7769
	ret nz			;776b
	ld hl,0e140h		;776c   ; 0xE140 lleva el episodio en los dos bits de abajo
	ld a,(hl)			;776f
	and 003h		;7770
	dec a			;7772
	jp z,GIGANTE_EPISODIO_1		;7773
	dec a			;7776
	jp z,GIGANTE_EPISODIO_2		;7777
	dec a			;777a
	jp z,GIGANTE_EPISODIO_3		;777b
	ld a,(0e1d1h)		;777e   ; 0xE1D1 es el indice del mapa: en 0x47 arranca el gigante 1 y en 0xE7 el 2
	ld c,000h		;7781
	cp 047h		;7783   ; tres pasos antes de que el cuerpo entre en pantalla (llega en 0x4A)
	jr nz,MIRA_EL_SEGUNDO		;7785
	inc c			;7787
MIRA_EL_SEGUNDO:		; La posicion 0xE7 del mapa saca el gigante numero 2
	cp 0e7h		;7788   ; y lo mismo para el segundo (llega en 0xEA)
	jr nz,ARRANCA_GIGANTE		;778a
	ld c,002h		;778c
ARRANCA_GIGANTE:		; Marca el episodio, el gigante y sus contadores
	ld a,c			;778e   ; fuera de esas dos posiciones no pasa nada
	and a			;778f
	ret z			;7790
	ld (hl),001h		;7791   ; episodio 1: el gigante esta de camino
	ld (0e1d6h),a		;7793   ; 0xE1D6 dice cual de los dos es
	inc hl			;7796
	ld (hl),000h		;7797   ; 0xE141 el fotograma y 0xE142 a cero
	inc hl			;7799
	ld (hl),000h		;779a
	inc hl			;779c
	dec a			;779d   ; el gigante 1 lleva cuatro piezas...
	ld a,004h		;779e
	jr z,PREPARA_PIEZAS		;77a0
	ld a,002h		;77a2   ; ...y el 2 solo dos
PREPARA_PIEZAS:		; Cuantas piezas y cuanto aguantan
	ld (hl),a			;77a4   ; 0xE143 son las piezas que quedan por romper
	ld hl,02000h		;77a5   ; 0xE1D7 el fotograma del cuerpo y 0xE1D8 su cuenta atras
	ld (0e1d7h),hl		;77a8
	ld hl,0e150h		;77ab   ; las piezas viven en 0xE150, ocho bytes cada una
	ld a,c			;77ae
	dec a			;77af
	ld b,004h		;77b0
	ld de,07828h		;77b2   ; las cuatro posiciones del gigante 1...
	jr z,VIDA_DE_LAS_PIEZAS		;77b5
	ld de,07830h		;77b7   ; ...o las dos del 2
	ld b,002h		;77ba
VIDA_DE_LAS_PIEZAS:		; Lo que aguanta cada pieza baja con la dificultad
	ld a,c			;77bc
	dec a			;77bd
	ld c,020h		;77be   ; el gigante 1 aguanta 0x20 impactos por pieza y el 2 solo 0x14
	jr z,REPARTE_VIDA		;77c0
	ld c,014h		;77c2
REPARTE_VIDA:		; Deja la vida de las piezas en 0xE144 y 0xE1B1
	ld a,(0e1d3h)		;77c4   ; cada vuelta de dificultad le quita cuatro impactos
	add a,a			;77c7
	add a,a			;77c8
	sub c			;77c9
	neg		;77ca
	ld (0e144h),a		;77cc   ; 0xE144 y 0xE1B1 llevan lo que aguanta cada pieza
	ld (0e1b1h),a		;77cf
	xor a			;77d2
	ld (0e1deh),a		;77d3   ; 0xE1DE: el aviso del final aun no ha sonado
MONTA_GIGANTE:		; Rellena las cuatro (o dos) piezas de 0xE150
	ld (hl),012h		;77d6   ; byte +0: el tipo de la pieza, que arranca en 0x12
	inc hl			;77d8
	ld (hl),001h		;77d9   ; byte +1 a 1
	inc hl			;77db
	ld a,(de)			;77dc   ; bytes +2 y +3: la fila y la columna de la tabla
	ld (hl),a			;77dd
	inc de			;77de
	inc hl			;77df
	ld a,(de)			;77e0
	ld (hl),a			;77e1
	inc de			;77e2
	inc hl			;77e3
	inc hl			;77e4
	inc hl			;77e5
	ld (hl),0bch		;77e6   ; bytes +6 y +7: patron 0xBC y color 6
	inc hl			;77e8
	ld (hl),006h		;77e9
	inc hl			;77eb
	djnz MONTA_GIGANTE		;77ec
	ld a,091h		;77ee   ; 0x91 es la musica del gigante
	jp PIDE_SONIDO		;77f0
GIGANTE_EPISODIO_1:		; Cuenta ocho pasos y pasa al episodio 2
	inc hl			;77f3   ; 0xE141 cuenta los pasos
	inc (hl)			;77f4
	ld a,(hl)			;77f5
	cp 008h		;77f6   ; a los ocho pasos empieza el episodio 2, que es cuando se ve
	ret c			;77f8
	dec hl			;77f9
	ld (hl),002h		;77fa
	ret			;77fc
GIGANTE_EPISODIO_2:		; Mantiene sonando la musica del gigante
	ld hl,0e032h		;77fd   ; el canal C es el que lleva la musica del gigante
	ld a,(hl)			;7800
	cp 091h		;7801   ; si ya suena la 0x91, nada que hacer
	ret z			;7803
	ld a,088h		;7804   ; y si no suena la 0x88, se pide
	cp (hl)			;7806
	call nz,PIDE_SONIDO		;7807
	ret			;780a
GIGANTE_EPISODIO_3:		; Cuenta 0x3F pasos y cierra el episodio
	inc hl			;780b   ; 0xE141 cuenta los pasos del episodio 3
	inc (hl)			;780c
	ld a,(hl)			;780d
	cp 03fh		;780e   ; a los 0x3F pasos el gigante se acaba
	jr c,GIGANTE_SUENA_UNA_VEZ		;7810
	dec hl			;7812
	xor a			;7813
	ld (hl),a			;7814
	ld (0e1d9h),a		;7815   ; y la carga de sus caracteres vuelve a cero
	ret			;7818
GIGANTE_SUENA_UNA_VEZ:		; A los 0x14 pasos suena una sola vez
	cp 014h		;7819   ; a los 0x14 pasos suena el aviso
	ret nz			;781b
	ld hl,0e1deh		;781c
	ld a,(hl)			;781f   ; 0xE1DE evita que suene mas de una vez
	and a			;7820
	ret nz			;7821
	inc (hl)			;7822
	ld a,096h		;7823   ; 0x96 es ese aviso
	jp PIDE_SONIDO		;7825

; ----------------------------------------------------------------------
; DATOS posiciones_gigante_1: Cuatro parejas de fila y columna: el gigante 1
;   son cuatro piezas en cuadro
;   0x7828..0x7830  (8 bytes)
DATA_posiciones_gigante_1:
	defb 00bh,04ch	; 7828
	defb 00bh,064h	; 782a
	defb 023h,04ch	; 782c
	defb 023h,064h	; 782e

; ----------------------------------------------------------------------
; DATOS posiciones_gigante_2: Dos parejas de fila y columna: el gigante 2 son
;   dos piezas
;   0x7830..0x7834  (4 bytes)
DATA_posiciones_gigante_2:
	defb 01bh,024h	; 7830
	defb 01bh,094h	; 7832

; ======================================================================
; CODIGO 0x7834..0x7903  (207 bytes)
; ======================================================================


MUEVE_GIGANTE:		; Coloca las piezas del gigante en las fichas de sprite
	call RECORRE_PIEZAS		;7834   ; primero el color de cada pieza...
	call PASO_EXPLOSIONES		;7837   ; ...y luego sus explosiones
	ld hl,0e150h		;783a
	ld b,004h		;783d
	ld a,(0e1d6h)		;783f   ; cuatro piezas el gigante 1 y dos el 2
	dec a			;7842
	jr z,COLOCA_PIEZAS		;7843
	ld b,002h		;7845
COLOCA_PIEZAS:		; Reparte las piezas por la pantalla segun el fotograma
	ld a,(0e141h)		;7847   ; 0xE141 es el fotograma de bajada
	cp 020h		;784a   ; pasado el 0x20 las piezas ya no se colocan
	ret nc			;784c
	add a,a			;784d   ; ocho pixeles por paso: 32 pasos son 256 pixeles
	add a,a			;784e
	add a,a			;784f
	ld c,a			;7850
PIEZA_COLOCA:		; Coloca una pieza, o la manda fuera si se sale
	ld a,(hl)			;7851   ; pieza rota, nada que colocar
	inc l			;7852
	inc l			;7853
	and a			;7854
	jr z,PIEZA_FUERA		;7855
	ld a,(hl)			;7857   ; byte +2: la fila de la tabla, mas la bajada
	add a,c			;7858
	sub 040h		;7859
	ld e,a			;785b
	sub 0c0h		;785c   ; entre las filas 0xC0 y 0xDF la pieza no se ve
	cp 020h		;785e
	jr nc,PIEZA_GUARDA		;7860
PIEZA_FUERA:		; La pieza se sale: fila 0xC3, o sea apagada
	ld e,0c3h		;7862   ; fila 0xC3: fuera de la pantalla
PIEZA_GUARDA:		; Deja la fila y la columna de la pieza
	inc l			;7864
	ld a,(hl)			;7865   ; byte +3: la columna
	inc l			;7866
	ld (hl),e			;7867   ; bytes +4 y +5: la fila y la columna de verdad, las que se miran
	inc l			;7868
	ld (hl),a			;7869
	inc l			;786a   ; ocho bytes a la pieza siguiente
	inc l			;786b
	inc l			;786c
	djnz PIEZA_COLOCA		;786d
	ret			;786f
GIGANTE_A_SPRITES:		; Copia las piezas a los atributos de sprite
	ld hl,0e154h		;7870   ; de cada pieza se copian los bytes +4 a +7
	ld de,0e0c4h		;7873   ; 0xE0C4 es la ficha 5: el gigante usa las fichas 5 a 8
	ld b,004h		;7876
	ld a,(0e1d6h)		;7878   ; cuatro piezas o dos
	dec a			;787b
	jr z,COPIA_UNA_PIEZA		;787c
	ld b,002h		;787e
COPIA_UNA_PIEZA:		; Cuatro bytes de la pieza a los atributos de sprite
	push bc			;7880
	ld bc,00004h		;7881   ; fila, columna, patron y color
	ldir		;7884
	ld a,004h		;7886   ; y cuatro bytes hasta la pieza siguiente
	call SUMA_A_HL		;7888
	pop bc			;788b
	djnz COPIA_UNA_PIEZA		;788c
	ret			;788e
MARCA_EXPLOSION:		; Enciende la explosion que corresponde a esta pieza
	ld a,l			;788f   ; la pieza esta en 0xE150 mas ocho por pieza
	sub 050h		;7890
	and 0f8h		;7892   ; se queda el numero de pieza...
	rra			;7894
	rra			;7895
	rra			;7896
	ld hl,0e145h		;7897   ; ...y con el, su explosion en 0xE145
	call SUMA_A_HL		;789a
	ld (hl),010h		;789d   ; 0x10 fotogramas de explosion
	ret			;789f
PASO_EXPLOSIONES:		; Un paso de las cuatro explosiones del gigante
	ld hl,0e145h		;78a0   ; las cuatro explosiones de 0xE145
	ld ix,0e150h		;78a3   ; y las cuatro piezas de 0xE150
	ld de,00008h		;78a7
	ld b,004h		;78aa
EXPLOSION_PASO:		; Baja la cuenta y elige el patron de la explosion
	ld a,(hl)			;78ac   ; explosion a cero: esta pieza no explota
	and a			;78ad
	jr z,EXPLOSION_SIGUIENTE		;78ae
	dec a			;78b0
	ld (hl),a			;78b1
	jr z,PIEZA_TIPO		;78b2   ; agotada la cuenta, la pieza vuelve o desaparece
	cp 004h		;78b4   ; patron 0x94 al principio y 0x9C al final
	ld a,094h		;78b6
	jr nc,EXPLOSION_PATRON_PIEZA		;78b8
	ld a,09ch		;78ba
EXPLOSION_PATRON_PIEZA:		; Deja el patron y el color de la explosion
	ld (ix+006h),a		;78bc   ; byte +6 el patron y +7 el color 11
	ld (ix+007h),00bh		;78bf
EXPLOSION_SIGUIENTE:		; Pasa a la explosion siguiente
	inc hl			;78c3
	add ix,de		;78c4   ; ocho bytes a la pieza siguiente
	djnz EXPLOSION_PASO		;78c6
	ret			;78c8
PIEZA_VUELVE:		; La explosion se acaba: la pieza vuelve a su patron
	call PATRON_GIGANTE		;78c9   ; acabada la explosion, la pieza recupera su color
	jr EXPLOSION_SIGUIENTE		;78cc
PATRON_GIGANTE:		; Elige el COLOR de la pieza segun su tipo
	ld a,(ix+000h)		;78ce   ; byte +0: el tipo, que arranca en 0x12
	sub 012h		;78d1
	exx			;78d3
	ld hl,07903h		;78d4   ; la tabla de colores de 0x7903
	call SUMA_A_HL		;78d7
	ld a,(0e003h)		;78da
	bit 4,a		;78dd   ; cada 32 fotogramas la pieza parpadea...
	ld a,(hl)			;78df
	jr z,GUARDA_PATRON_PIEZA		;78e0
	ld a,001h		;78e2   ; ...poniendose del color 1, o sea negra
GUARDA_PATRON_PIEZA:		; Deja el color de la pieza y su patron fijo 0xBC
	exx			;78e4
	ld (ix+007h),a		;78e5   ; byte +7: el color
	ld (ix+006h),0bch		;78e8   ; byte +6: el patron, que siempre es 0xBC
	ret			;78ec
PIEZA_TIPO:		; El tipo de la ultima pieza depende de cual sea el gigante
	ld a,(0e1d6h)		;78ed   ; la ultima pieza del gigante 1 es la 0x14...
	dec a			;78f0
	ld c,014h		;78f1
	jr z,PIEZA_MIRA_TIPO		;78f3
	ld c,017h		;78f5   ; ...y la del 2 la 0x17
PIEZA_MIRA_TIPO:		; Compara el tipo de la pieza con el ultimo
	ld a,(ix+000h)		;78f7   ; con cualquier otro tipo la pieza sigue ahi
	cp c			;78fa
	jr c,PIEZA_VUELVE		;78fb
	ld (ix+000h),000h		;78fd   ; y la ultima desaparece del todo
	jr EXPLOSION_SIGUIENTE		;7901

; ----------------------------------------------------------------------
; DATOS tabla_color_pieza_gigante: COLOR de cada pieza del gigante (base
;   0x7903, indice el tipo menos 0x12); el patron es siempre 0xBC, y cada 32
;   fotogramas la pieza se pone del color 1, o sea negra
;   0x7903..0x7909  (6 bytes)
DATA_tabla_color_pieza_gigante:
	defb 006h,00ah,00bh,007h,004h,000h	; 7903

; ======================================================================
; CODIGO 0x7909..0x793e  (53 bytes)
; ======================================================================


RECORRE_PIEZAS:		; Da su color a cada pieza viva
	ld a,(0e1d6h)		;7909   ; cuatro piezas o dos
	ld b,004h		;790c
	dec a			;790e
	jr z,PIEZA_IX		;790f
	ld b,002h		;7911
PIEZA_IX:		; Apunta IX a la primera pieza
	ld ix,0e150h		;7913   ; las piezas de 0xE150
PIEZA_PATRON_PASO:		; Una pieza, si esta viva
	ld a,(ix+000h)		;7917   ; pieza a cero: ya no esta
	and a			;791a
	jr z,PIEZA_IX_SIGUIENTE		;791b
	call PATRON_GIGANTE		;791d   ; le da su color
PIEZA_IX_SIGUIENTE:		; Ocho bytes mas alla esta la pieza siguiente
	ld de,00008h		;7920   ; ocho bytes a la siguiente
	add ix,de		;7923
	djnz PIEZA_PATRON_PASO		;7925
	ret			;7927
RITMO_GIGANTE:		; Cuenta atras entre fotogramas del gigante
	ld hl,0e1d7h		;7928   ; 0xE1D7 el fotograma del cuerpo y 0xE1D8 su cuenta
	ld a,(hl)			;792b
	inc hl			;792c
	dec (hl)			;792d   ; mientras quede cuenta, el cuerpo no cambia
	ret nz			;792e
	ld de,0793eh		;792f   ; cada fotograma tiene su propia espera
	call SUMA_A_DE		;7932
	ld a,(de)			;7935
	ld (hl),a			;7936
	dec hl			;7937
	ld a,(hl)			;7938   ; y el fotograma del cuerpo da la vuelta cada cuatro
	inc a			;7939
	and 003h		;793a
	ld (hl),a			;793c
	ret			;793d

; ----------------------------------------------------------------------
; DATOS tabla_ritmo_gigante: Cuatro esperas, 0x1F, 0x5F, 0x1F y 0x7F, que se
;   van alternando
;   0x793e..0x7942  (4 bytes)
DATA_tabla_ritmo_gigante:
	defb 01fh,05fh,01fh,07fh	; 793e

; ======================================================================
; CODIGO 0x7942..0x7970  (46 bytes)
; ======================================================================


PINTA_GIGANTE:		; Repinta las dos o tres celdas que se animan del cuerpo del gigante
	ld a,(0e1d6h)		;7942   ; 0xE1D6 dice cual de los dos gigantes
	ld c,a			;7945
	ld hl,0e1d7h		;7946
	ld a,(hl)			;7949   ; el cuerpo solo se repinta con el fotograma 1 o el 3
	inc hl			;794a
	dec a			;794b
	jr z,RITMO_AL_REVES		;794c
	cp 002h		;794e
	ret nz			;7950
	ld a,(hl)			;7951   ; la cuenta atras, partida por cuatro, elige el guion
	rra			;7952
	rra			;7953
	and 006h		;7954
	jr ELIGE_GUION_GIGANTE		;7956
RITMO_AL_REVES:		; El gigante 1 recorre sus fotogramas al reves
	ld a,(hl)			;7958   ; el gigante 1 recorre los cuatro guiones al reves
	rra			;7959
	rra			;795a
	and 006h		;795b
	sub 006h		;795d
	neg		;795f
ELIGE_GUION_GIGANTE:		; Elige la lista de guiones segun el gigante
	ld hl,07970h		;7961   ; los cuatro guiones del gigante 1...
	dec c			;7964
	jr z,PINTA_EL_GUION		;7965
	ld hl,079a0h		;7967   ; ...o los del 2
PINTA_EL_GUION:		; Coge el guion y lo vuelca en la tabla de nombres
	call LEE_PUNTERO		;796a   ; dos bytes por guion
	jp PINTA_GUION		;796d

; ----------------------------------------------------------------------
; DATOS tabla_guiones_gigante_1: Cuatro guiones de tabla de nombres, uno por
;   fotograma del gigante 1
;   0x7970..0x7978  (8 bytes)
DATA_tabla_guiones_gigante_1:
	defw 07978h,07982h,0798ch,07996h	; 7970  -> DATA_guiones_gigante_1 0x7982 0x798c 0x7996

; ----------------------------------------------------------------------
; DATOS guiones_gigante_1: Los cuatro guiones: dos tiras de dos celdas en las
;   filas 3 y 4, columnas 11 y 12
;   0x7978..0x79a0  (40 bytes)
DATA_guiones_gigante_1:
	defb 06bh,038h,0c5h,0c6h,0feh,08bh,038h,0c7h,0c8h,0ffh,06bh,038h,0c9h,0cah,0feh,08bh	; 7978  k8....8...k8....
	defb 038h,0cbh,0cch,0ffh,06bh,038h,0cdh,0ceh,0feh,08bh,038h,0cfh,0d0h,0ffh,06bh,038h	; 7988  8...k8....8...k8
	defb 0e7h,0e8h,0feh,08bh,038h,0e9h,0eah,0ffh	; 7998  ....8...

; ----------------------------------------------------------------------
; DATOS tabla_guiones_gigante_2: Cuatro guiones para el gigante 2
;   0x79a0..0x79a8  (8 bytes)
DATA_tabla_guiones_gigante_2:
	defw 079a8h,079b4h,079c0h,079cch	; 79a0  -> DATA_guiones_gigante_2 0x79b4 0x79c0 0x79cc

; ----------------------------------------------------------------------
; DATOS guiones_gigante_2: Los cuatro guiones: dos tiras de tres celdas en las
;   filas 4 y 5, columnas 11 a 13
;   0x79a8..0x79d8  (48 bytes)
DATA_guiones_gigante_2:
	defb 08bh,038h,0e2h,0e9h,0e2h,0feh,0abh,038h,0ebh,0ebh,0ebh,0ffh,08bh,038h,0e2h,0e3h	; 79a8  .8.....8.....8..
	defb 0e2h,0feh,0abh,038h,0ebh,0e1h,0ebh,0ffh,08bh,038h,0e5h,0ech,0e4h,0feh,0abh,038h	; 79b8  ...8.....8.....8
	defb 0ebh,0e1h,0ebh,0ffh,08bh,038h,0ech,0ech,0ech,0feh,0abh,038h,0e1h,0e1h,0e1h,0ffh	; 79c8  .....8.....8....

; ======================================================================
; CODIGO 0x79d8..0x7be3  (523 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; EL SONIDO. Tres canales, 14 bytes de estado por canal desde 0xE01A.
; ----------------------------------------------------------------------
PIDE_SONIDO:		; Pide el sonido A, pero solo con partida en marcha
	ex af,af'			;79d8   ; el codigo se aparca en el registro alterno mientras se hacen las comprobaciones
	ld a,(0e002h)		;79d9   ; sin partida en marcha no hay efectos
	and 040h		;79dc
	ret z			;79de
	ld a,(0e1ddh)		;79df   ; ni con el avion muriendo: 0xE1DD deja sonar solo su explosion
	and a			;79e2
	ret nz			;79e3
	ex af,af'			;79e4
PONE_SONIDO:		; Reparte el sonido A entre los canales que le tocan
	ld c,a			;79e5   ; C guarda el codigo entero, con sus bits 6 y 7
	and 03fh		;79e6   ; el codigo es A y 0x3F: los bits 6 y 7 no cuentan
	ld b,002h		;79e8   ; B es cuantos canales se van a ocupar, menos uno
	ld hl,0e032h		;79ea
	cp 009h		;79ed   ; menos de 9: un canal, el C, en 0xE032
	jr c,UN_CANAL		;79ef
	ld hl,0e026h		;79f1
	cp 00ch		;79f4   ; de 9 a 11: un canal, el B, en 0xE026
	jr c,UN_CANAL		;79f6
	cp 011h		;79f8   ; el 17: dos canales, el B y el C
	jr z,REPARTE_CANALES		;79fa
	ld hl,0e01ah		;79fc
	cp 013h		;79ff   ; de 12 a 18: un canal, el A, en 0xE01A
	jr c,UN_CANAL		;7a01
	inc b			;7a03   ; de 19 en adelante: los tres canales
	jr REPARTE_CANALES		;7a04
UN_CANAL:		; Un solo canal para este sonido
	dec b			;7a06   ; un solo canal
REPARTE_CANALES:		; Compara prioridades y reparte el sonido por los canales
	ld a,(hl)			;7a07   ; no se pisa un sonido con codigo mas alto que el que se pide
	and 03fh		;7a08
	ld e,a			;7a0a
	ld a,c			;7a0b   ; el codigo que se pide, sin los bits de arriba
	and 03fh		;7a0c
	cp e			;7a0e
	ret c			;7a0f
	add a,a			;7a10   ; dos bytes por sonido
	ld de,07bedh		;7a11   ; la base es 0x7BED, dos bytes antes de la tabla: el indice es 2*codigo
	call SUMA_A_DE		;7a14
	dec hl			;7a17   ; del codigo (+2) hacia atras, al arranque del canal
	dec hl			;7a18
MONTA_CANAL:		; Deja el codigo y el puntero del guion en un canal
	ld (hl),001h		;7a19   ; byte +0: la cuenta de la nota, que arranca en 1 para que suene ya
	inc hl			;7a1b
	ld (hl),001h		;7a1c   ; byte +1: la duracion
	inc hl			;7a1e
	ld (hl),c			;7a1f   ; byte +2: el codigo del sonido
	inc hl			;7a20
	ld a,(de)			;7a21   ; bytes +3 y +4: el puntero del guion
	ld (hl),a			;7a22
	inc hl			;7a23
	inc de			;7a24
	ld a,(de)			;7a25
	ld (hl),a			;7a26
	ld a,008h		;7a27   ; doce bytes por canal
	add a,l			;7a29
	ld l,a			;7a2a
	inc de			;7a2b   ; y los guiones de los canales de un mismo sonido van seguidos en la tabla
	djnz MONTA_CANAL		;7a2c
	ret			;7a2e
REPITE_O_ACABA:		; Un 0xFE del guion: repite el bloque o pasa al siguiente
	inc hl			;7a2f   ; detras del 0xFE viene cuantas veces se repite
	ld a,(ix+009h)		;7a30   ; byte +9: las vueltas dadas
	inc a			;7a33
	cp (hl)			;7a34
	jp z,CALLA_CANAL		;7a35   ; dadas todas, el canal calla
	jp m,ENCADENA_SONIDO		;7a38   ; y si no, se vuelve a lanzar el mismo sonido desde el principio
	dec a			;7a3b
ENCADENA_SONIDO:		; Encadena el sonido que sigue en el guion
	ex af,af'			;7a3c
	ld a,(ix+002h)		;7a3d
	push bc			;7a40
	ld d,001h		;7a41   ; D a 1 enciende la mezcla
	call PONE_SONIDO		;7a43   ; el mismo codigo otra vez: eso rearranca el guion
	pop bc			;7a46
	ex af,af'			;7a47
	ld (ix+009h),a		;7a48   ; byte +9: una vuelta mas
	ret			;7a4b
MEZCLA_PSG:		; Enciende o apaga el tono y el ruido de este canal
	ld a,(0e03ch)		;7a4c   ; 0xE03C es la copia del registro 7 del PSG, el de la mezcla
	ld e,a			;7a4f
	ld a,c			;7a50   ; de C (1, 3 o 5) saca el numero de canal: 1, 2 o 4
	cp 001h		;7a51
	jr z,MEZCLA_BITS		;7a53
	dec a			;7a55
MEZCLA_BITS:		; Coloca los bits de tono y ruido de este canal
	rlca			;7a56   ; tres rotaciones lo llevan a los bits de ruido: 8, 16 o 32
	rlca			;7a57
	rlca			;7a58
	dec d			;7a59   ; con D a 1 se enciende, y si no se apaga
	jr z,MEZCLA_ENCIENDE		;7a5a
	cpl			;7a5c   ; el complemento apaga solo ese bit
	and e			;7a5d
	jr MEZCLA_AJUSTA		;7a5e
MEZCLA_ENCIENDE:		; Enciende los bits que tocan
	or e			;7a60
MEZCLA_AJUSTA:		; Ajusta el ruido para que tono y ruido no se pisen
	set 2,a		;7a61   ; el tono del canal C se apaga si su ruido esta encendido...
	bit 5,a		;7a63
	jr z,CORTA_SONIDO		;7a65
	res 2,a		;7a67   ; ...y se vuelve a encender si no
	set 0,a		;7a69   ; lo mismo con el canal A
	bit 3,a		;7a6b
	jr z,CORTA_SONIDO		;7a6d
	res 0,a		;7a6f
CORTA_SONIDO:		; Escribe el byte de mezcla en el registro 7 del PSG
	ld (0e03ch),a		;7a71   ; el registro 7 del PSG lleva los seis bits de tono y ruido
	ld e,a			;7a74
	ld a,007h		;7a75
	jp 00093h		;7a77   ; BIOS WRTPSG - Writes data to PSG-register
VUELCA_SONIDO:		; Un paso de los tres canales y volcado al PSG
	ld a,(0e03ch)		;7a7a   ; la mezcla de antes, tal cual: esto solo la vuelve a escribir
	call CORTA_SONIDO		;7a7d
	ld c,001h		;7a80   ; C arranca en 1: el registro de periodo del canal A
	ld ix,0e018h		;7a82   ; IX apunta dos bytes antes del codigo, o sea al byte +0 del canal
	exx			;7a86
	ld b,003h		;7a87   ; tres canales
	ld de,0000ch		;7a89   ; doce bytes de un canal al siguiente
CANAL_PASO:		; Un paso de un canal, y salta al siguiente
	exx			;7a8c
	ld a,(ix+002h)		;7a8d   ; byte +2: el codigo; a cero, el canal esta mudo
	or a			;7a90
	call nz,CANAL_ACTIVO		;7a91
	inc c			;7a94   ; dos mas en C: del registro 1 al 3 y del 3 al 5
	inc c			;7a95
	exx			;7a96
	add ix,de		;7a97
	djnz CANAL_PASO		;7a99
	ret			;7a9b
CANAL_ACTIVO:		; Un canal que suena: baja su cuenta y sigue el guion
	bit 6,a		;7a9c   ; bit 6 del codigo: los que lo llevan no tocan la mezcla
	ld d,001h		;7a9e
	call z,MEZCLA_PSG		;7aa0
	ld a,(ix+002h)		;7aa3   ; bit 7 del codigo: guion largo, con sobre de volumen
	or a			;7aa6
	jp m,BAJA_EL_VOLUMEN		;7aa7
	dec (ix+000h)		;7aaa   ; mientras dure la nota no se lee nada mas
	ret nz			;7aad
LEE_ORDEN:		; Lee la siguiente orden del guion del canal
	ld l,(ix+003h)		;7aae   ; bytes +3 y +4: por donde va el guion
	ld h,(ix+004h)		;7ab1
	ld a,(hl)			;7ab4
	cp 0feh		;7ab5   ; 0xFE repite el sonido
	jp z,REPITE_O_ACABA		;7ab7
	jr nc,CALLA_CANAL		;7aba   ; y de 0xFF en adelante lo acaba
	bit 7,(ix+002h)		;7abc   ; los guiones largos tienen sus propias ordenes
	jp nz,ORDEN_LARGA		;7ac0
	and 0f0h		;7ac3   ; 0x2n cambia la duracion de las notas que vienen
	cp 020h		;7ac5
	ld a,(hl)			;7ac7
	jr nz,ORDEN_RUIDO		;7ac8
	and 00fh		;7aca   ; el nibble bajo es la duracion
	ld (ix+001h),a		;7acc
	inc hl			;7acf
	ld a,(hl)			;7ad0
ORDEN_RUIDO:		; 0x1n: pone el periodo del ruido y enciende el sobre
	ld b,a			;7ad1   ; B se queda el byte por si no era una orden
	and 0f0h		;7ad2
	cp 010h		;7ad4   ; 0x1n pone el periodo del ruido
	jr nz,ORDEN_NOTA		;7ad6
	ld a,(hl)			;7ad8
	and 01fh		;7ad9   ; los cinco bits de abajo son el periodo del ruido
	ld e,a			;7adb
	ld a,c			;7adc   ; en el canal C el periodo va tal cual
	cp 003h		;7add
	jr z,ORDEN_RUIDO_MANDA		;7adf
	inc hl			;7ae1
	bit 4,(hl)		;7ae2   ; bit 4 del byte siguiente: si esta puesto, el periodo no se toca
	ld b,(hl)			;7ae4
	jr nz,ORDEN_RUIDO_ATRAS		;7ae5
	ld a,e			;7ae7
	sub 010h		;7ae8   ; y si no, se le restan 16
	ld e,a			;7aea
ORDEN_RUIDO_ATRAS:		; Retrocede al byte de la orden
	dec hl			;7aeb   ; el dec hl devuelve el puntero al byte de la orden
ORDEN_RUIDO_MANDA:		; Manda el periodo del ruido y el sobre al PSG
	ld a,006h		;7aec   ; registro 6 del PSG: el periodo del ruido
	call 00093h		;7aee   ; BIOS WRTPSG - Writes data to PSG-register
	ld a,00dh		;7af1   ; registro 13: el sobre, en modo 15
	ld e,00fh		;7af3
	call 00093h		;7af5   ; BIOS WRTPSG - Writes data to PSG-register
	ld d,000h		;7af8   ; D a 0 apaga la mezcla de este canal
	call MEZCLA_PSG		;7afa
	inc hl			;7afd
ORDEN_NOTA:		; La nota y su duracion
	bit 6,(ix+002h)		;7afe   ; bit 6 del codigo
	jr z,NOTA_CON_PERIODO		;7b02
	ld a,c			;7b04
	cp 003h		;7b05   ; el canal C se salta el atajo
	ld a,(hl)			;7b07
	jr z,NOTA_CON_PERIODO		;7b08
	call GUARDA_PUNTERO		;7b0a   ; los demas se quedan con la duracion y no tocan el periodo
	ld a,b			;7b0d
	jr GUARDA_VOLUMEN		;7b0e
NOTA_CON_PERIODO:		; Nota con el periodo escrito en el guion
	and 0f0h		;7b10   ; el nibble alto de la nota es el volumen...
	ld b,a			;7b12
	xor (hl)			;7b13   ; ...y el bajo, junto con el byte siguiente, el periodo de 12 bits
	ld d,a			;7b14
	inc hl			;7b15
	ld e,(hl)			;7b16
	call GUARDA_PUNTERO		;7b17   ; el puntero se guarda ya avanzado
	ex de,hl			;7b1a
	call MANDA_PERIODO		;7b1b   ; manda el periodo al PSG
	ld a,b			;7b1e
	rrca			;7b1f   ; las cuatro rotaciones bajan el volumen a los bits de abajo
	rrca			;7b20
	rrca			;7b21
	rrca			;7b22
GUARDA_VOLUMEN:		; Deja el volumen y la duracion del canal
	ld h,a			;7b23   ; H lleva el volumen
	ld a,(ix+001h)		;7b24   ; byte +0: la cuenta vuelve a la duracion de +1
	ld (ix+000h),a		;7b27
	ld (ix+008h),002h		;7b2a   ; byte +8: dos pasos hasta que el volumen empiece a bajar
	jr MANDA_VOLUMEN		;7b2e
CALLA_CANAL:		; Apaga el canal y su volumen
	xor a			;7b30   ; byte +9: sin vueltas pendientes
	ld (ix+009h),a		;7b31
	ld (ix+00bh),a		;7b34   ; y byte +11: sin afinado
	ld d,001h		;7b37   ; D a 1 apaga este canal en la mezcla
	call MEZCLA_PSG		;7b39
	xor a			;7b3c
	ld (ix+002h),a		;7b3d   ; byte +2 a cero: el canal queda libre
	ld h,a			;7b40
	jr MANDA_VOLUMEN		;7b41
BAJA_EL_VOLUMEN:		; El sobre a mano: baja el volumen paso a paso
	dec (ix+000h)		;7b43   ; byte +0: lo que le queda a la nota
	jp z,LEE_ORDEN		;7b46   ; acabada, a por la orden siguiente
	dec (ix+008h)		;7b49   ; byte +8: cada dos pasos baja un punto de volumen
	ret nz			;7b4c
	ld a,(ix+007h)		;7b4d   ; byte +7: el volumen que suena ahora
	dec a			;7b50
	ret m			;7b51   ; llegado a cero ya no baja mas
	ld (ix+007h),a		;7b52
	ld h,a			;7b55
MANDA_VOLUMEN:		; Escribe el volumen del canal en el PSG
	ld a,c			;7b56   ; de C (1, 3 o 5) saca el registro de volumen: 8, 9 o 10
	rrca			;7b57
	add a,088h		;7b58
	ld e,h			;7b5a
	jp 00093h		;7b5b   ; BIOS WRTPSG - Writes data to PSG-register
ORDEN_LARGA:		; Las ordenes 0xD0, 0xE0 y 0xF0: tempo, sobre y octava
	ld a,(hl)			;7b5e   ; la orden larga: el nibble alto manda
	and 0f0h		;7b5f
	cp 0d0h		;7b61   ; 0xDn es el tempo
	ld a,(hl)			;7b63
	jr nz,ORDEN_VOLUMEN		;7b64
	and 00fh		;7b66
	ld (ix+00ah),a		;7b68   ; byte +10: el tempo
	inc hl			;7b6b
	ld a,(hl)			;7b6c
ORDEN_VOLUMEN:		; 0xFn: volumen base del canal
	cp 0f0h		;7b6d   ; 0xFn es el volumen base
	jr c,ORDEN_OCTAVA		;7b6f
	and 00fh		;7b71
	ld (ix+006h),a		;7b73   ; byte +6: el volumen base
	inc hl			;7b76
	ld a,(hl)			;7b77
ORDEN_OCTAVA:		; 0xEn: octava, o el bit de afinado si es 0xE8 o mas
	cp 0e0h		;7b78   ; 0xEn es la octava
	jr c,ORDEN_DURACION		;7b7a
	and 00fh		;7b7c
	bit 3,a		;7b7e   ; de 0xE8 en adelante no es octava, es el bit de afinado
	jr z,ORDEN_OCTAVA_GUARDA		;7b80
	ld (ix+00bh),a		;7b82   ; byte +11: el afinado
	inc hl			;7b85
	jr ORDEN_LARGA		;7b86
ORDEN_OCTAVA_GUARDA:		; Deja la octava del canal
	ld (ix+005h),a		;7b88   ; byte +5: la octava
	inc hl			;7b8b
	ld a,(hl)			;7b8c
ORDEN_DURACION:		; La duracion sale de multiplicar el tempo por el valor
	and 00fh		;7b8d   ; el nibble bajo dice cuantos tempos dura la nota
	ld b,a			;7b8f
	ld a,(ix+00ah)		;7b90   ; con el nibble a cero dura un solo tempo
	jr z,GUARDA_DURACION		;7b93
MULTIPLICA_TEMPO:		; Suma el tempo tantas veces como diga el valor
	add a,(ix+00ah)		;7b95   ; y si no, se suma el tempo tantas veces como diga
	djnz MULTIPLICA_TEMPO		;7b98
GUARDA_DURACION:		; Deja la duracion y sigue con la nota
	ld (ix+001h),a		;7b9a   ; byte +1: la duracion que queda fijada
	ld a,(hl)			;7b9d
	call GUARDA_PUNTERO		;7b9e   ; el puntero se guarda ya en el byte siguiente
	and 0f0h		;7ba1   ; el nibble alto de la nota es el semitono
	rrca			;7ba3
	rrca			;7ba4
	rrca			;7ba5
	rrca			;7ba6
	ld b,a			;7ba7
	sub 00ch		;7ba8   ; el semitono 0x0C es un silencio: volumen cero
	jr z,NOTA_GUARDA_VOLUMEN		;7baa
	ld a,(ix+006h)		;7bac   ; y los demas arrancan con el volumen base
NOTA_GUARDA_VOLUMEN:		; Deja el volumen de arranque de la nota
	ld (ix+007h),a		;7baf   ; byte +7: el volumen de arranque
	call GUARDA_VOLUMEN		;7bb2
	ld a,b			;7bb5
	ld hl,07be3h		;7bb6   ; los doce semitonos de 0x7BE3
	call SUMA_A_HL		;7bb9
	ld l,(hl)			;7bbc
	ld h,000h		;7bbd
	ld a,(ix+005h)		;7bbf   ; byte +5: la octava
	or a			;7bc2
	jr z,MANDA_PERIODO		;7bc3
	ld b,a			;7bc5
SUBE_OCTAVA:		; Dobla el periodo por cada octava
	add hl,hl			;7bc6   ; doblar el periodo es bajar una octava
	djnz SUBE_OCTAVA		;7bc7
	ld a,(ix+00bh)		;7bc9   ; byte +11: el afinado sube el periodo en uno
	or a			;7bcc
	jr z,MANDA_PERIODO		;7bcd
	inc hl			;7bcf
MANDA_PERIODO:		; Escribe el periodo de 12 bits en los dos registros del PSG
	ld a,c			;7bd0   ; registro 1, 3 o 5: la parte alta del periodo
	ld e,h			;7bd1
	call 00093h		;7bd2   ; BIOS WRTPSG - Writes data to PSG-register
	ld a,c			;7bd5   ; y el de al lado, la parte baja
	dec a			;7bd6
	ld e,l			;7bd7
	jp 00093h		;7bd8   ; BIOS WRTPSG - Writes data to PSG-register
GUARDA_PUNTERO:		; Deja el puntero del guion en el canal
	inc hl			;7bdb   ; bytes +3 y +4: por donde se ha quedado el guion
	ld (ix+003h),l		;7bdc
	ld (ix+004h),h		;7bdf
	ret			;7be2

; ----------------------------------------------------------------------
; DATOS tabla_de_notas: Los doce semitonos de una octava; las demas octavas
;   salen de doblar
;   0x7be3..0x7bef  (12 bytes)
DATA_tabla_de_notas:
	defb 06ah,064h,05fh,059h,054h,050h,04bh,047h,043h,03fh,03ch,038h	; 7be3  jd_YTPKGC?<8

; ----------------------------------------------------------------------
; DATOS tabla_de_sonidos: Un puntero por codigo de sonido (base 0x7BED,
;   codigos del 1 al 31); los sonidos de varios canales ocupan huecos seguidos
;   0x7bef..0x7c2d  (62 bytes)
DATA_tabla_de_sonidos:
	defw 07c4fh,07ca8h,07c6dh,07c8bh,07d85h,07c57h,07d6bh,07fc0h	; 7bef
	defw 07c30h,07e1dh,07d96h,07c3dh,07ce6h,07cceh,07cf8h,07de6h	; 7bff
	defw 07f74h,07fb9h,07e31h,07e34h,07e78h,07edch,07eddh,07ef1h	; 7c0f
	defw 07f0ah,07f2dh,07f50h,07db0h,07c2dh,07c2dh,07c2dh	; 7c1f

; ----------------------------------------------------------------------
; DATOS guiones_de_sonido: Los guiones de los 31 sonidos y melodias, uno por
;   canal
;   0x7c2d..0x7ffc  (975 bytes)
DATA_guiones_de_sonido:
	defb 0ffh,0feh,0ffh,0d1h,0fdh,0e2h,050h,0e1h,090h,0e2h,020h,0e1h,090h,0c0h,0feh,002h	; 7c2d  ......P... .....
	defb 021h,0d0h,0c0h,0c0h,0d0h,0c0h,0e0h,0c0h,0f0h,0b1h,000h,0b1h,010h,0b1h,020h,0b1h	; 7c3d  !............. .
	defb 030h,0ffh,0d2h,0fdh,0e3h,040h,050h,060h,050h,0ffh,022h,0d0h,070h,021h,0c0h,072h	; 7c4d  0....@P`P.".p!.r
	defb 0b0h,070h,0c0h,050h,022h,0b0h,052h,0a0h,050h,0b0h,050h,0a0h,052h,090h,050h,0ffh	; 7c5d  .p.P".R.P.P.R.P.
	defb 021h,080h,0a0h,090h,098h,0a0h,090h,0b0h,088h,022h,0b0h,088h,0b0h,078h,0b0h,070h	; 7c6d  !........"...x.p
	defb 0b0h,078h,0b0h,080h,021h,0b0h,088h,0a0h,090h,090h,098h,080h,0a0h,0ffh,0d1h,0fbh	; 7c7d  .x..!...........
	defb 0e3h,010h,030h,060h,080h,0a0h,0fch,0e2h,000h,020h,040h,060h,080h,090h,0b0h,070h	; 7c8d  ..0`..... @`...p
	defb 050h,030h,010h,0fbh,0e3h,0a0h,080h,060h,030h,010h,0ffh,023h,0a0h,040h,0a0h,044h	; 7c9d  P0.....`0..#.@.D
	defb 0a0h,048h,0a0h,04bh,0a0h,050h,0b0h,055h,0b0h,05ah,0b0h,060h,0b0h,068h,0b0h,070h	; 7cad  .H.K.P.U.Z.`.h.p
	defb 0b0h,078h,0b0h,080h,0b0h,088h,0b0h,090h,0b0h,098h,0b0h,0a0h,0b0h,0a8h,0b0h,0b0h	; 7cbd  .x..............
	defb 0ffh,0d1h,0fdh,0e1h,000h,030h,060h,030h,060h,080h,0a0h,0e0h,000h,020h,040h,0c2h	; 7ccd  .....0`0`.... @.
	defb 0e1h,0b0h,080h,060h,030h,060h,030h,000h,0ffh,021h,0f0h,01ch,080h,01ch,080h,01ch	; 7cdd  ...`0`0..!......
	defb 0e0h,01ch,0c0h,01ch,0b0h,01ch,0a0h,01ch,090h,01ch,0ffh,0d1h,0fbh,0e3h,020h,000h	; 7ced  .............. .
	defb 030h,010h,040h,020h,050h,030h,060h,040h,070h,050h,080h,060h,090h,070h,0a0h,080h	; 7cfd  0.@ P0`@pP.`.p..
	defb 0b0h,090h,0fch,0e2h,000h,0e3h,000h,0e3h,0a0h,0e2h,010h,0e3h,0b0h,0e2h,020h,000h	; 7d0d  .............. .
	defb 030h,010h,040h,020h,050h,030h,060h,040h,070h,050h,080h,060h,090h,070h,0a0h,080h	; 7d1d  0.@ P0`@pP.`.p..
	defb 0b0h,090h,0fdh,0e1h,000h,0e2h,0a0h,0e1h,010h,0e2h,0b0h,0e1h,020h,000h,030h,010h	; 7d2d  ............ .0.
	defb 040h,020h,050h,030h,060h,040h,070h,050h,080h,060h,090h,070h,0a0h,080h,0b0h,090h	; 7d3d  @ P0`@pP.`.p....
	defb 0e0h,000h,0e1h,0a0h,0e0h,010h,0e1h,0b0h,0e0h,020h,000h,030h,010h,040h,020h,050h	; 7d4d  ......... .0.@ P
	defb 030h,060h,040h,070h,050h,080h,060h,090h,070h,0a0h,080h,0b0h,090h,0ffh,021h,01fh	; 7d5d  0`@pP.`.p.....!.
	defb 00ah,01bh,01ch,017h,00eh,013h,01ah,022h,000h,021h,011h,00ah,014h,01ch,016h,00eh	; 7d6d  .......".!......
	defb 01ah,01bh,01eh,00ah,022h,000h,0feh,002h,0d1h,0fdh,0e2h,070h,0fch,040h,0fbh,000h	; 7d7d  ...."......p.@..
	defb 0fdh,070h,0fch,040h,0fbh,000h,0c0h,0feh,006h,022h,0d0h,05fh,0c0h,061h,0b0h,05fh	; 7d8d  .p.@....."._.a._
	defb 0d0h,04bh,0c0h,04dh,0b0h,04bh,0d0h,05fh,0c0h,061h,0b0h,05fh,0d0h,03fh,0c0h,041h	; 7d9d  .K.M.K._.a._.?.A
	defb 0b0h,03fh,0ffh,022h,01dh,01fh,00eh,00fh,01ch,01fh,00eh,00fh,01bh,01eh,00dh,00eh	; 7dad  .?."............
	defb 01ah,01eh,00dh,00eh,019h,01dh,00ch,00dh,018h,01ch,00bh,00ch,019h,01bh,00ah,00bh	; 7dbd  ................
	defb 01ah,01ah,009h,00ah,01bh,019h,008h,009h,01ch,018h,007h,008h,01dh,017h,006h,005h	; 7dcd  ................
	defb 01eh,016h,005h,006h,01fh,015h,004h,005h,0ffh,022h,01dh,00fh,000h,00eh,01ch,00fh	; 7ddd  ........."......
	defb 000h,00eh,01bh,00eh,000h,00dh,01ah,00eh,000h,00dh,019h,00dh,000h,00ch,018h,00ch	; 7ded  ................
	defb 000h,00bh,019h,00bh,000h,00ah,01ah,00ah,000h,009h,01bh,009h,000h,008h,01ch,008h	; 7dfd  ................
	defb 000h,007h,01dh,007h,000h,006h,01eh,006h,000h,005h,01fh,005h,000h,004h,0ffh,0ffh	; 7e0d  ................
	defb 022h,0d0h,0cah,0d0h,0c8h,000h,000h,0d0h,0cah,0c0h,0c8h,000h,000h,0b0h,0cbh,0b0h	; 7e1d  "...............
	defb 0cah,0a0h,0c8h,0ffh,0d3h,0c0h,0e8h,0d6h,0fch,0e2h,000h,050h,070h,0e1h,000h,0e2h	; 7e2d  ...........Pp...
	defb 070h,050h,000h,050h,070h,0e1h,000h,0e2h,070h,050h,040h,090h,0b0h,0e1h,040h,0e2h	; 7e3d  pP.Pp...pP@...@.
	defb 0b0h,090h,040h,090h,0b0h,0e1h,040h,0e2h,0b0h,090h,000h,050h,070h,0e1h,000h,0e2h	; 7e4d  ..@...@....Pp...
	defb 070h,050h,000h,050h,070h,0e1h,000h,0e2h,070h,050h,040h,090h,0b0h,0e1h,040h,0e2h	; 7e5d  pP.Pp...pP@...@.
	defb 0b0h,090h,040h,090h,0b0h,0e1h,040h,0e2h,0b0h,090h,0ffh,0d3h,0fch,0e3h,000h,0c0h	; 7e6d  ..@...@.........
	defb 000h,0c0h,000h,0c0h,000h,0c0h,000h,0c0h,000h,0c0h,000h,0c0h,000h,0c0h,000h,0c0h	; 7e7d  ................
	defb 000h,0c0h,000h,0c0h,000h,0c0h,040h,0c0h,040h,0c0h,040h,0c0h,040h,0c0h,040h,0c0h	; 7e8d  ......@.@.@.@.@.
	defb 040h,0c0h,040h,0c0h,040h,0c0h,040h,0c0h,040h,0c0h,040h,0c0h,040h,0c0h,000h,0c0h	; 7e9d  @.@.@.@.@.@.@...
	defb 000h,0c0h,000h,0c0h,000h,0c0h,000h,0c0h,000h,0c0h,000h,0c0h,000h,0c0h,000h,0c0h	; 7ead  ................
	defb 000h,0c0h,000h,0c0h,000h,0c0h,040h,0c0h,040h,0c0h,040h,0c0h,040h,0c0h,040h,0c0h	; 7ebd  ......@.@.@.@.@.
	defb 040h,0c0h,040h,0c0h,040h,0c0h,040h,0c0h,040h,0c0h,040h,0c0h,040h,0c0h,0ffh,0e8h	; 7ecd  @.@.@.@.@.@.@...
	defb 0d4h,0c2h,0fch,0e1h,026h,0c0h,046h,0c0h,056h,0c0h,042h,0c0h,052h,0c0h,076h,0c0h	; 7edd  ....&.F.V.B.R.v.
	defb 046h,0c0h,05fh,0ffh,0d4h,0c2h,0fdh,0e2h,096h,0c0h,0b6h,0c0h,0e1h,006h,0c0h,0e2h	; 7eed  F._.............
	defb 0b2h,0c0h,0e1h,002h,0c0h,026h,0c0h,0e2h,0b6h,0c0h,0e1h,00fh,0ffh,0d7h,0c3h,0fch	; 7efd  .....&..........
	defb 0e1h,020h,010h,020h,040h,050h,040h,020h,010h,020h,050h,040h,070h,050h,040h,020h	; 7f0d  . . @P@ . P@pP@ 
	defb 010h,0d8h,021h,0dah,0e2h,091h,0dbh,071h,0dch,0a1h,0d6h,020h,090h,0e1h,025h,0ffh	; 7f1d  ..!....q... ..%.
	defb 0d7h,0c3h,0fch,0e3h,021h,091h,090h,070h,050h,040h,050h,070h,0a0h,090h,070h,050h	; 7f2d  ....!..pP@Pp..pP
	defb 040h,0e2h,020h,0d8h,0e3h,090h,0e2h,050h,0dah,020h,040h,0dbh,0e3h,0a0h,070h,0dch	; 7f3d  @. ....P. @...p.
	defb 041h,024h,0ffh,0d7h,0c3h,0fbh,0e2h,090h,070h,090h,0a0h,0e1h,000h,0e2h,0a0h,090h	; 7f4d  A$......p.......
	defb 070h,090h,0e1h,000h,0e2h,0a0h,0e1h,020h,000h,0e2h,0a0h,090h,070h,0d8h,091h,0dah	; 7f5d  p...... ....p...
	defb 051h,0dbh,041h,0dch,071h,054h,0ffh,0d1h,0fdh,0e1h,070h,0c3h,070h,0c3h,070h,0c3h	; 7f6d  Q.A.qT....p.p.p.
	defb 070h,0c3h,070h,0c3h,070h,0c3h,070h,0c3h,070h,0c3h,0a0h,0c3h,0a0h,0c3h,0a0h,0c3h	; 7f7d  p.p.p.p.p.......
	defb 0a0h,0c3h,0a0h,0c3h,0a0h,0c3h,0a0h,0c3h,0a0h,0c3h,060h,0c3h,060h,0c3h,060h,0c3h	; 7f8d  ..........`.`.`.
	defb 060h,0c3h,060h,0c3h,060h,0c3h,060h,0c3h,060h,0c3h,060h,0c3h,060h,0c3h,060h,0c3h	; 7f9d  `.`.`.`.`.`.`.`.
	defb 060h,0c3h,060h,0c3h,060h,0c3h,060h,0c3h,060h,0c3h,0feh,002h,0d8h,0fdh,0e3h,074h	; 7fad  `.`.`.`.`......t
	defb 0a4h,069h,0ffh,0d4h,0fdh,0e3h,052h,072h,082h,0a2h,0b2h,0a2h,082h,072h,0d2h,0e2h	; 7fbd  .i....Rr.....r..
	defb 050h,0c0h,050h,0c0h,050h,0c0h,070h,0c0h,070h,0c0h,070h,0c0h,080h,0c0h,080h,0c0h	; 7fcd  P.P.P.p.p.p.....
	defb 080h,0c0h,0a0h,0c0h,0a0h,0c0h,0a0h,0c0h,0b0h,0c0h,0b0h,0c0h,0b0h,0c0h,0a0h,0c0h	; 7fdd  ................
	defb 0a0h,0c0h,0a0h,0c0h,080h,0c0h,080h,0c0h,080h,0c0h,070h,0c0h,070h,0c0h,070h	; 7fed  ..........p.p.p

; ----------------------------------------------------------------------
; DATOS relleno: Cuatro bytes 0xFF: lo unico que sobra en los 16 KB
;   0x7ffc..0x8000  (4 bytes)
DATA_relleno:
	defb 0ffh,0ffh,0ffh,0ffh	; 7ffc
