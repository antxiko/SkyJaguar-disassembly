#!/usr/bin/env python3
"""Dibuja los graficos de Sky Jaguar desde los bytes del cartucho.

Las imagenes de esta web no son capturas del emulador ni ilustraciones traidas
de fuera: se montan leyendo la ROM y ejecutando en Python los MISMOS pasos que
el Z80 corre en la maquina. Los dos descompresores (0x4396 a la VRAM y 0x43D8 a
la tabla de nombres) y el compositor del fondo (0x5837) estan aqui reproducidos
instruccion a instruccion. Eso es lo que convierte el dibujo en una prueba: si
un rango o un formato estuvieran mal leidos, saldria ruido en vez del paisaje.

Lo que dibuja (en docs/imagenes/):
  rotulo.png            el rotulo SKY JAGUAR del titulo
  titulo.png            la pantalla del titulo entera
  pantalla_juego.png    la pantalla de partida con su panel
  nivel.png             LA FASE ENTERA: 1920 filas en ocho columnas
  nivel_00..07.png      la misma fase en ocho tramos de 240 filas
  enemigo_grande_1.png  el primer enemigo grande, con su cuerpo de fondo
  enemigo_grande_2.png  el segundo
  fuente.png            los 74 caracteres de la fuente (0x10-0x59)
  paisaje.png           los 104 caracteres del paisaje (0x40-0xA7)
  lisos.png             los 16 caracteres de color entero (0x00-0x0F)
  sprites.png           los sprites de 16x16
  bicho_1.png           los 61 caracteres del enemigo grande 1 (0xB0-0xEC)
  bicho_2.png           los del enemigo grande 2

Uso: graficos.py <rom> <org> <docs/imagenes>
     graficos.py --comprueba <rom> <org> <carpeta de volcados>...

El segundo modo compara byte a byte lo que monta este guion con la VRAM de
verdad que vuelcan tools/omsx_vram.tcl y tools/omsx_vram_fase.tcl desde
openMSX. Mirar el dibujo no basta.
"""
import os
import struct
import sys
import zlib

# --------------------------------------------------------------------------
# La paleta del TMS9918. El color 0 es transparente: como el registro 7 vale
# 0xE0 (0x443D), el borde y todo lo transparente se ven negros.
# --------------------------------------------------------------------------
PALETA = [
    (0, 0, 0), (0, 0, 0), (62, 184, 73), (116, 208, 125),
    (89, 85, 224), (128, 118, 241), (185, 94, 81), (101, 219, 239),
    (219, 101, 89), (255, 137, 125), (204, 195, 94), (222, 208, 135),
    (58, 162, 65), (183, 102, 181), (204, 204, 204), (255, 255, 255),
]

FONDO = (0x20, 0x20, 0x30)
REJA = (0x38, 0x38, 0x4A)
SEPARA = (0x30, 0x30, 0x40)

# Los ocho registros del VDP (DATA_tabla_registros_vdp, 0x443D) dicen donde
# esta cada tabla. No se copia ninguna direccion de otro juego: salen de aqui.
REGISTROS = 0x443D


class Vdp(object):
    """Las tablas de la VRAM tal como las coloca este cartucho."""

    def __init__(self, rom, org):
        r = rom[REGISTROS - org:REGISTROS - org + 8]
        self.regs = list(r)
        self.nombres = r[2] * 0x400          # 0x0E -> 0x3800
        self.patrones = (r[4] & 0x04) * 0x800   # 0x07 -> 0x2000
        self.colores = (r[3] & 0x80) * 0x40     # 0x7F -> 0x0000
        self.sprite_attr = r[5] * 0x80          # 0x76 -> 0x3B00
        self.sprite_pat = r[6] * 0x800          # 0x03 -> 0x1800


# --------------------------------------------------------------------------
# PNG sin dependencias
# --------------------------------------------------------------------------
def png(w, h, px, fn):
    raw = b"".join(b"\0" + bytes(px[y * w * 3:(y + 1) * w * 3]) for y in range(h))

    def chunk(t, d):
        return (struct.pack(">I", len(d)) + t + d
                + struct.pack(">I", zlib.crc32(t + d) & 0xFFFFFFFF))
    with open(fn, "wb") as f:
        f.write(b"\x89PNG\r\n\x1a\n"
                + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0))
                + chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b""))


# ==========================================================================
# LOS DOS DESCOMPRESORES DEL CARTUCHO, TAL CUAL
# ==========================================================================
class Rom(object):
    def __init__(self, datos, org):
        self.d, self.org = datos, org

    def b(self, a):
        return self.d[a - self.org]

    def w(self, a):
        return self.d[a - self.org] | (self.d[a - self.org + 1] << 8)


def desc_vram(rom, p, vram, dest=None, marca=None):
    """DESC_VRAM (0x4396) y DESC_VRAM_HL (0x439C).

    El byte de mando se decide igual que en 0x43A6-0x43B0: un 0x00 acaba
    (`and a / ret z`); si `a and 0x7F` es igual al byte -o sea con el bit 7
    CLARO- salta a DESC_VRAM_REPITE y repite n veces el byte siguiente; si al
    quitarle el bit alto queda cero -o sea el byte era 0x80- vuelve a 0x4396 y
    lee del flujo otra direccion de VRAM; en lo demas copia n bytes tal cual.
    Devuelve donde se quedo el guion, que es lo que permite comprobar que un
    bloque acaba justo donde empieza el siguiente.
    """
    if dest is None:
        dest = rom.w(p)
        p += 2
    wr = dest & 0x3FFF
    while True:
        x = rom.b(p)
        p += 1
        if x == 0:
            return p
        n = x & 0x7F
        if n == x:                       # bit 7 claro: repite un byte
            v = rom.b(p)
            p += 1
            for _ in range(n):
                vram[wr] = v
                if marca is not None:
                    marca[wr] = 1
                wr = (wr + 1) & 0x3FFF
        elif n == 0:                     # 0x80: otro bloque, con su direccion
            dest = rom.w(p)
            p += 2
            wr = dest & 0x3FFF
        else:                            # copia literal
            for _ in range(n):
                vram[wr] = rom.b(p)
                p += 1
                if marca is not None:
                    marca[wr] = 1
                wr = (wr + 1) & 0x3FFF


def desc_tres(rom, p, vram, dest):
    """DESC_TRES (0x4408): el mismo bloque en los tres tercios, sumando 0x800."""
    fin = p
    for tercio in range(3):
        fin = desc_vram(rom, p, vram, dest + tercio * 0x800)
    return fin


def rellena_tres(vram, dest, n, val):
    """RELLENA_TRES (0x43F7): FILVRM repetido en los tres tercios."""
    for tercio in range(3):
        for i in range(n):
            vram[(dest + tercio * 0x800 + i) & 0x3FFF] = val


def pinta_guion(rom, p, vram, mascara=0xFF):
    """PINTA_GUION (0x43D8) y BORRA_GUION (0x43F3).

    Cada bloque empieza por su direccion de tabla de nombres y sigue con un
    byte por celda; 0xFE abre otro bloque y 0xFF acaba. La mascara es el
    registro C: 0xFF pinta el guion y 0x00 lo borra, que es como el cartucho
    usa el MISMO guion para poner y quitar un letrero.
    """
    while True:
        wr = rom.w(p) & 0x3FFF
        p += 2
        while True:
            x = rom.b(p)
            p += 1
            if x == 0xFF:
                return p
            if x == 0xFE:
                break
            vram[wr] = x & mascara
            wr = (wr + 1) & 0x3FFF


def a_vram(rom, p, vram, dest, n):
    """A_VRAM (0x438E), o sea LDIRVM: n bytes tal cual."""
    for i in range(n):
        vram[(dest + i) & 0x3FFF] = rom.b(p + i)


# ==========================================================================
# LAS CARGAS DE GRAFICOS DEL CARTUCHO
# ==========================================================================
def color_lisos(vdp, vram):
    """COLOR_LISOS (0x4B71): a los caracteres 0x00-0x0F, ocho bytes de color
    cada uno, empezando en 0x00 y sumando 0x11. Su patron se queda a cero, o
    sea que se pintan enteros del color del PAPEL: son el mar y los llanos."""
    for tercio in range(3):
        c = 0
        for k in range(0x10):
            for j in range(8):
                vram[vdp.colores + tercio * 0x800 + k * 8 + j] = c
            c = (c + 0x11) & 0xFF


def carga_fuente(rom, vdp, vram):
    """CARGA_FUENTE (0x4B97): los 74 caracteres 0x10-0x59 a 0x2080 en los tres
    tercios, y sus 0x250 bytes de color a 0x0080 puestos a 0xF0 (blanco)."""
    fin = desc_tres(rom, 0x4BAB, vram, vdp.patrones + 0x80)
    rellena_tres(vram, vdp.colores + 0x80, 0x250, 0xF0)
    return fin


def carga_paisaje(rom, vdp, vram):
    """CARGA_PAISAJE (0x6D84): los 104 caracteres 0x40-0xA7 a 0x2200 y sus 832
    bytes de color a 0x0200, los dos en los tres tercios."""
    f1 = desc_tres(rom, 0x6DCA, vram, vdp.patrones + 0x200)
    f2 = desc_tres(rom, 0x702B, vram, vdp.colores + 0x200)
    return f1, f2


def carga_gigante(rom, vdp, vram, cual):
    """CARGA_GIGANTE (0x6D96): los 61 caracteres 0xB0-0xEC del enemigo grande
    que toque, a 0x2580, y sus colores a 0x0580. El 1 sale del indice 0x4A del
    mapa y el 2 del 0xEA, y por eso NUNCA coinciden en pantalla aunque usen el
    mismo hueco de caracteres."""
    pat, col = (0x70DE, 0x7285) if cual == 1 else (0x7323, 0x74A7)
    f1 = desc_tres(rom, pat, vram, vdp.patrones + 0x580)
    f2 = desc_tres(rom, col, vram, vdp.colores + 0x580)
    return f1, f2


def carga_sprites(rom, vdp, vram):
    """CARGA_SPRITES (0x4F12): salta a DESC_VRAM, o sea que la direccion la
    trae el GUION (sus dos primeros bytes son 00 18) y el ld hl,0x1800 de
    0x4F12 no lo usa nadie. Cuantos bytes escribe NO se supone: se cuentan
    marcando la VRAM, y de ahi salen los patrones (8 bytes) y los sprites de
    16x16 (32 bytes)."""
    marca = bytearray(0x4000)
    fin = desc_vram(rom, 0x4F1B, vram, marca=marca)
    if rom.w(0x4F1B) != vdp.sprite_pat:
        raise SystemExit("  el guion de sprites no apunta a 0x%04X" % vdp.sprite_pat)
    return fin, sum(marca)


def carga_titulo(rom, vdp, vram):
    """CARGA_TITULO (0x434D) y PINTA_ROTULO (0x4374): los 40 caracteres del
    rotulo a 0x2600, sus colores (0xF0 los 28 primeros, 0x80 los 12 ultimos),
    el guion comprimido 0x4E82 que los coloca en la tabla de nombres, y el
    guion 0x4B1C con PUSH SPACE KEY y (c) KONAMI 1984."""
    desc_tres(rom, 0x4D61, vram, vdp.patrones + 0x600)
    rellena_tres(vram, vdp.colores + 0x600, 0xE0, 0xF0)
    rellena_tres(vram, vdp.colores + 0x6E0, 0x60, 0x80)
    desc_vram(rom, 0x4E82, vram)
    pinta_guion(rom, 0x4B1C, vram)


def pinta_panel(rom, vdp, vram, vidas=None, escena=None, puntos=0, record=0):
    """PINTA_PANEL (0x42B0): los rotulos HI/SCENE/SCORE/REST del guion 0x4B00,
    los avioncitos de las vidas, el numero de escena, el (c) KONAMI 1984 de las
    dos ultimas filas y las seis cifras de puntos y record. Las cifras van en
    BCD y el caracter de una cifra es 0x10 + la cifra (0x42F7)."""
    if vidas is None:                 # DATA_valores_iniciales_partida (0x4200)
        vidas = rom.b(0x4200)
    if escena is None:
        escena = rom.b(0x4201)
    pinta_guion(rom, 0x4B00, vram)
    # PINTA_VIDAS (0x430A): tres avioncitos de 2x2 en la fila 9 y tres en la 11
    for k in range(6):
        base = (0x3939 if k < 3 else 0x3979) + 2 * (k % 3)
        for j, d in enumerate((0, 1, 0x20, 0x21)):
            vram[(base + d) & 0x3FFF] = (0xA4 + j) if k < vidas else 0
    # (c) KONAMI y 1984, los dos LDIRVM de 0x42BC
    a_vram(rom, 0x4B2F, vram, 0x3AD8, 7)
    a_vram(rom, 0x4B36, vram, 0x3AFA, 5)

    def cifras(dest, valor, n):
        for i in range(n):
            vram[(dest + i) & 0x3FFF] = 0x10 + int(("%0*d" % (n, valor))[i])
    cifras(0x38B9, record, 6)      # PINTA_EL_RECORD (0x42D0), fila 5
    cifras(0x3859, puntos, 6)      # PINTA_LOS_PUNTOS (0x42D9), fila 2
    cifras(0x3A3C, escena, 2)      # PINTA_ESCENA (0x42E3), fila 17


def vram_base(rom, vdp):
    """Lo que ESTADO_0_SUB_3 (0x4108) deja puesto: los colores de los lisos y
    la fuente."""
    vram = bytearray(0x4000)
    color_lisos(vdp, vram)
    carga_fuente(rom, vdp, vram)
    return vram


# ==========================================================================
# EL COMPOSITOR DEL FONDO (PASO_DE_FONDO, 0x5837)
# ==========================================================================
MAPA = 0x58FF          # DATA_mapa_de_la_fase: 244 codigos, uno por ocho filas
TIPOS = 0x59F3         # DATA_tabla_tipos_de_tira: 20 punteros
FILA_DE_ABAJO = 0x3AE1  # 0x58AE: fila 23, columna 1
LARGO = 0x780          # 0x5852: la fase mide 1920 filas


def paso_de_fondo(rom, vram, pos):
    """Redibuja la pantalla entera para la posicion `pos`, igual que 0x5837.

    - el indice del mapa es pos/8 (DIVIDE_ENTRE_OCHO, 0x5881) y de ahi salen
      CUATRO codigos de tira, copiados de 0xE1BE hacia abajo (0x589B) y
      consumidos en ese mismo orden por SIGUIENTE_TIRA (0x58EE);
    - la PRIMERA tira entra por la variante 2*(pos y 7), que es el
      desplazamiento fino de 0xE1BA; las otras tres por la variante 0, que es
      lo que hace CAMBIA_DE_TIRA (0x58E4) al leer el primer puntero;
    - se vuelca de ABAJO ARRIBA desde 0x3AE1, restando 0x20 por fila
      (SUBE_UNA_FILA, 0x58D7), y para a las 24 filas.

    Devuelve las anchuras de las 24 filas, que tienen que ser 23 clavadas.
    """
    idx = pos >> 3
    fino = 2 * (pos & 7)
    codigos = [rom.b(MAPA + idx + k) for k in range(4)]
    cola = list(codigos)

    def siguiente():
        # SIGUIENTE_TIRA: el codigo indexa 0x59F3 y devuelve su subtabla de ocho
        return rom.w(TIPOS + 2 * cola.pop(0))

    p = rom.w(siguiente() + fino)
    hl = FILA_DE_ABAJO
    wr = hl
    filas, anchos, n = 24, [], 0
    while True:
        x = rom.b(p)
        p += 1
        if x & 0x80:
            if x == 0xFF:                       # acaba la tira: otra del mapa
                p = rom.w(siguiente())          # y siempre por la variante 0
                cierra = True
            else:
                cierra = False
                for _ in range(x & 0x7F):
                    vram[wr & 0x3FFF] = rom.b(p)
                    p += 1
                    wr += 1
                    n += 1
        else:
            if x == 0:                          # acaba la fila
                cierra = True
            else:
                cierra = False
                v = rom.b(p)
                p += 1
                for _ in range(x):
                    vram[wr & 0x3FFF] = v
                    wr += 1
                    n += 1
        if cierra:
            anchos.append(n)
            n = 0
            filas -= 1
            if filas == 0:
                return anchos
            hl -= 0x20
            wr = hl


def nivel_entero(rom, vdp):
    """Las 1920 filas de la fase, de la 0 (donde arranca) a la 1919.

    La fila que ENTRA por arriba en la posicion p es la fila 0 de su dibujo, y
    de ahi sale el mosaico. Que el paisaje sea continuo -que el dibujo de p+1
    sea el de p bajado una fila- se comprueba en `comprueba_continuidad`.
    """
    filas = []
    for pos in range(LARGO):
        v = bytearray(0x4000)
        anchos = paso_de_fondo(rom, v, pos)
        if set(anchos) != {23}:
            raise SystemExit("  la posicion %d dio filas de %s celdas"
                             % (pos, sorted(set(anchos))))
        filas.append(bytes(v[vdp.nombres:vdp.nombres + 24]))   # fila 0, col 0..23
    return filas


def comprueba_continuidad(rom, vdp):
    """La prueba de que el formato del fondo esta bien leido: el dibujo de la
    posicion p+1 tiene que ser el de p BAJADO una fila, para las 1919 parejas,
    y la 1919 tiene que cerrar con la 0 porque la fase da vueltas."""
    def dibujo(pos):
        v = bytearray(0x4000)
        paso_de_fondo(rom, v, pos)
        return [bytes(v[vdp.nombres + f * 32 + 1:vdp.nombres + f * 32 + 24])
                for f in range(24)]
    bien = 0
    ant = dibujo(0)
    for pos in range(1, LARGO):
        hoy = dibujo(pos)
        if all(hoy[i] == ant[i - 1] for i in range(1, 24)):
            bien += 1
        ant = hoy
    cero = dibujo(0)
    cierra = all(cero[i] == ant[i - 1] for i in range(1, 24))
    return bien, LARGO - 1, cierra


def tramos_del_gigante(filas):
    """En que filas de la fase salen los caracteres 0xB0-0xEC. Tienen que ser
    dos tramos y solo dos: el cuerpo del enemigo grande 1 y el del 2. No se
    recorta a ojo ni se escribe ninguna fila a mano."""
    con = [n for n, f in enumerate(filas) if any(c >= 0xB0 for c in f[1:24])]
    tram = []
    for x in con:
        if tram and x == tram[-1][1] + 1:
            tram[-1][1] = x
        else:
            tram.append([x, x])
    return tram


# ==========================================================================
# DIBUJO
# ==========================================================================
def celda(vram, vdp, t, tercio):
    """Los ocho pares (patron, color) de un caracter en un tercio."""
    pb = vdp.patrones + tercio * 0x800 + t * 8
    cb = vdp.colores + tercio * 0x800 + t * 8
    return [(vram[pb + f], vram[cb + f]) for f in range(8)]


def pinta_celdas(vram, vdp, celdas, esc=2, tercio_de=None):
    """Una rejilla de celdas de la tabla de nombres, como la lee el VDP en
    SCREEN 2. `tercio_de(fila)` dice que tercio toca; por omision el 0, que en
    este cartucho vale para todos porque los tres se cargan iguales."""
    alto, ancho = len(celdas), len(celdas[0])
    w, h = ancho * 8 * esc, alto * 8 * esc
    px = bytearray(w * h * 3)
    for fila in range(alto):
        tercio = 0 if tercio_de is None else tercio_de(fila)
        for col in range(ancho):
            for f, (linea, color) in enumerate(
                    celda(vram, vdp, celdas[fila][col], tercio)):
                tinta, papel = PALETA[color >> 4], PALETA[color & 15]
                for x in range(8):
                    c = tinta if (linea >> (7 - x)) & 1 else papel
                    for dy in range(esc):
                        base = (((fila * 8 + f) * esc + dy) * w
                                + (col * 8 + x) * esc) * 3
                        for dx in range(esc):
                            px[base + dx * 3:base + dx * 3 + 3] = bytes(c)
    return w, h, px


def pantalla(vram, vdp, esc=2):
    """Las 24x32 celdas de la tabla de nombres, cada tercio con sus patrones."""
    celdas = [[vram[vdp.nombres + f * 32 + c] for c in range(32)]
              for f in range(24)]
    return pinta_celdas(vram, vdp, celdas, esc, lambda f: f // 8)


def marco(vram, vdp, desde):
    """Las esquinas de lo escrito en la tabla de nombres contando solo los
    caracteres a partir de `desde`. Con desde=0xC0 salen las del rotulo del
    titulo y de nada mas, porque el rotulo es lo unico que usa 0xC0-0xE7."""
    o = [(f, c) for f in range(24) for c in range(32)
         if vram[vdp.nombres + f * 32 + c] >= desde]
    return (min(f for f, _ in o), max(f for f, _ in o),
            min(c for _, c in o), max(c for _, c in o))


def hoja(vram, vdp, primero, ultimo, cols=16, esc=3, margen=1, tercio=0):
    """Los caracteres de `primero` a `ultimo` en una rejilla, con su color."""
    n = ultimo - primero + 1
    filas = (n + cols - 1) // cols
    lado = 8 * esc + margen
    w, h = cols * lado + margen, filas * lado + margen
    px = bytearray(bytes(REJA) * (w * h))
    for k in range(n):
        gx, gy = margen + (k % cols) * lado, margen + (k // cols) * lado
        for f, (linea, color) in enumerate(celda(vram, vdp, primero + k, tercio)):
            tinta, papel = PALETA[color >> 4], PALETA[color & 15]
            if color == 0:
                tinta = papel = FONDO
            for c in range(8):
                col = tinta if (linea >> (7 - c)) & 1 else papel
                for a in range(esc):
                    for bq in range(esc):
                        x, y = gx + c * esc + bq, gy + f * esc + a
                        px[(y * w + x) * 3:(y * w + x) * 3 + 3] = bytes(col)
    return w, h, px


def hoja_sprites(vram, vdp, n, cols=8, esc=3, margen=2):
    """Los sprites de 16x16: cuatro patrones de 8x8 por sprite, en el orden
    del VDP (columna izquierda arriba y abajo, luego la derecha)."""
    filas = (n + cols - 1) // cols
    lado = 16 * esc + margen
    w, h = cols * lado + margen, filas * lado + margen
    px = bytearray(bytes(REJA) * (w * h))
    for k in range(n):
        gx, gy = margen + (k % cols) * lado, margen + (k // cols) * lado
        base = vdp.sprite_pat + k * 32
        for cuarto in range(4):
            ox, oy = (cuarto // 2) * 8, (cuarto % 2) * 8
            for f in range(8):
                v = vram[base + cuarto * 8 + f]
                for c in range(8):
                    col = PALETA[15] if (v >> (7 - c)) & 1 else FONDO
                    for a in range(esc):
                        for bq in range(esc):
                            x, y = gx + (ox + c) * esc + bq, gy + (oy + f) * esc + a
                            px[(y * w + x) * 3:(y * w + x) * 3 + 3] = bytes(col)
    return w, h, px


def tira_del_nivel(vrams, vdp, filas, gigantes, desde, hasta, esc=1):
    """Un tramo de la fase, con el PRINCIPIO ABAJO: el paisaje entra por arriba
    segun avanza la posicion, asi que el mosaico se lee de abajo hacia arriba
    igual que se juega. `vrams` trae una VRAM por juego de caracteres del
    enemigo grande, y para cada fila se usa el que el cartucho tendria cargado.
    """
    trozo = filas[desde:hasta]
    celdas = [list(f[1:24]) for f in reversed(trozo)]
    alto, ancho = len(celdas), 23
    w, h = ancho * 8 * esc, alto * 8 * esc
    px = bytearray(w * h * 3)
    for fila in range(alto):
        n_fase = hasta - 1 - fila
        vram = vrams[cual_gigante(gigantes, n_fase)]
        for col in range(ancho):
            for f, (linea, color) in enumerate(
                    celda(vram, vdp, celdas[fila][col], 0)):
                tinta, papel = PALETA[color >> 4], PALETA[color & 15]
                for x in range(8):
                    c = tinta if (linea >> (7 - x)) & 1 else papel
                    for dy in range(esc):
                        base = (((fila * 8 + f) * esc + dy) * w
                                + (col * 8 + x) * esc) * 3
                        for dx in range(esc):
                            px[base + dx * 3:base + dx * 3 + 3] = bytes(c)
    return w, h, px


def cual_gigante(gigantes, n_fase):
    """Cual de los dos juegos de caracteres 0xB0-0xEC tendria cargado el
    cartucho en esa fila de la fase."""
    for k, (a, z) in enumerate(gigantes):
        if a <= n_fase <= z:
            return k + 1
    return 1


def junta(trozos, sep=8):
    """Pega imagenes del mismo alto una al lado de otra."""
    alto = trozos[0][1]
    w = sum(t[0] for t in trozos) + sep * (len(trozos) + 1)
    px = bytearray(bytes(SEPARA) * (w * alto))
    x0 = sep
    for tw, th, tp in trozos:
        for y in range(th):
            px[(y * w + x0) * 3:(y * w + x0 + tw) * 3] = tp[y * tw * 3:(y + 1) * tw * 3]
        x0 += tw + sep
    return w, alto, px


# ==========================================================================
# LA COMPROBACION CONTRA LA VRAM DE VERDAD
# ==========================================================================
def lee_info(fn):
    d = {}
    for linea in open(fn, encoding="utf-8"):
        k, _, v = linea.strip().partition(" ")
        d[k] = v
    return d


# Las catorce celdas del panel que llevan cifras: seis de puntos (0x42D9), seis
# de record (0x42D0) y dos de escena (0x42E3). Su valor depende de como vaya la
# partida, asi que no se comparan con un numero: se comprueba que sean
# caracteres 0x10-0x19, que es lo que 0x42F7 escribe (0x10 mas la cifra).
CIFRAS = ([0x3859 + i for i in range(6)] + [0x38B9 + i for i in range(6)]
          + [0x3A3C, 0x3A3D])


def panel_mal(rom, vdp, real, mio, vidas, escena):
    pinta_panel(rom, vdp, mio, vidas=vidas, escena=escena)
    return sum(1 for f in range(24) for c in range(24, 32)
               if vdp.nombres + f * 32 + c not in CIFRAS
               and real[vdp.nombres + f * 32 + c] != mio[vdp.nombres + f * 32 + c])


def comprueba(rom, vdp, carpetas):
    """Compara byte a byte lo que monta este guion con la VRAM que openMSX
    vuelca (tools/omsx_vram.tcl y tools/omsx_vram_fase.tcl).

    De cada volcado se lee la posicion que el cartucho tenia en 0xE1B8/B9, se
    monta aqui esa MISMA posicion y se comparan la tabla de nombres, los
    patrones, los colores y los patrones de sprite. Las cifras que salgan son
    la prueba de que las imagenes no son una interpretacion.
    """
    import glob
    tot = {}

    def suma(k, mal, n):
        a, b = tot.get(k, (0, 0))
        tot[k] = (a + mal, b + n)

    def dif(real, mio, ini, fin):
        mal = n = 0
        for t in range(3):
            for x in range(ini + t * 0x800, fin + t * 0x800):
                n += 1
                if real[x] != mio[x]:
                    mal += 1
        return mal, n

    # El mosaico de nivel.png se monta con la fila que ENTRA por arriba en
    # cada posicion. Aqui se ata a la VRAM de verdad: la pantalla que el
    # cartucho tiene dibujada en la posicion p tiene que ser, de arriba abajo,
    # las filas p, p-1, ... p-23 del mosaico.
    filas = nivel_entero(rom, vdp)
    vistos, saltados = 0, [0]
    for carpeta in carpetas:
        for fn in sorted(glob.glob(os.path.join(carpeta, "info_*.txt"))):
            d = lee_info(fn)
            v = fn.replace("info_", "vram_").replace(".txt", ".bin")
            if not os.path.exists(v):
                continue
            real = open(v, "rb").read()
            regs = [int(x, 16) for x in d["regs"].split()]
            tabla = list(rom.d[REGISTROS - rom.org:REGISTROS - rom.org + 8])
            # el registro 7 lo mueve la cortinilla del titulo (0x4500), asi que
            # de los ocho solo se exigen los siete que colocan las tablas
            suma("registros del VDP (R0-R6)",
                 sum(1 for k in range(7) if regs[k] != tabla[k]), 7)
            # un volcado con la tabla de nombres a cero es de un instante en
            # que el cartucho la acaba de borrar (BORRA_NOMBRES, 0x4381) y aun
            # no ha vuelto a dibujar: no hay nada que comparar
            vacia = not any(real[vdp.nombres + f * 32 + c]
                            for f in range(24) for c in range(1, 24))
            vistos += 1
            if vacia:
                saltados[0] += 1
            elif d.get("fase_en_marcha") == "1":
                pos = int(d["pos_baja"]) | (int(d["pos_alta"]) << 8)
                mio = bytearray(vram_base(rom, vdp))
                carga_paisaje(rom, vdp, mio)
                if d.get("cargado_gigante") == "2":
                    carga_gigante(rom, vdp, mio, int(d["cual_gigante"]))
                paso_de_fondo(rom, mio, pos)
                mal = sum(1 for f in range(24) for c in range(1, 24)
                          if real[vdp.nombres + f * 32 + c]
                          != mio[vdp.nombres + f * 32 + c])
                suma("EL FONDO de la fase (24x23 celdas)", mal, 552)
                mal = sum(1 for f in range(24) for c in range(1, 24)
                          if real[vdp.nombres + f * 32 + c]
                          != filas[(pos - f) % LARGO][c])
                suma("el mosaico de nivel.png contra esa pantalla", mal, 552)
                suma("colores 0x00-0xAF", *dif(real, mio, 0x0000, 0x0580))
                suma("patrones 0x00-0xAF", *dif(real, mio, 0x2000, 0x2580))
                if d.get("cargado_gigante") == "2":
                    suma("colores del enemigo grande 0xB0-0xEC",
                         *dif(real, mio, 0x0580, 0x0768))
                    suma("patrones del enemigo grande 0xB0-0xEC",
                         *dif(real, mio, 0x2580, 0x2768))
                # El panel se pinta UNA vez, al montar la escena, con las
                # vidas y los puntos de entonces; el volcado es posterior y ya
                # no dice cuales eran. Asi que se prueban las siete cuentas de
                # vidas posibles y tiene que haber una que cuadre CLAVADA.
                mal = min(panel_mal(rom, vdp, real, bytearray(mio), v,
                                    int(d["escena"])) for v in range(7))
                suma("EL PANEL sin las cifras (178 celdas)", mal, 192 - len(CIFRAS))
                suma("las 14 cifras del panel, en 0x10-0x19",
                     sum(1 for x in CIFRAS if not 0x10 <= real[x] <= 0x19),
                     len(CIFRAS))
                spr = bytearray(0x4000)
                _, escritos = carga_sprites(rom, vdp, spr)
                suma("patrones de sprite",
                     sum(1 for x in range(vdp.sprite_pat,
                                          vdp.sprite_pat + escritos)
                         if real[x] != spr[x]), escritos)
                for base in (vdp.patrones, vdp.colores):
                    suma("los tres tercios, iguales entre si",
                         sum(1 for x in range(0x800)
                             for t in (0x800, 0x1000)
                             if real[base + x] != real[base + t + x]), 0x1000)
            elif d.get("estado") == "1":
                mio = bytearray(vram_base(rom, vdp))
                carga_titulo(rom, vdp, mio)
                mal = sum(1 for f in range(24) for c in range(32)
                          if real[vdp.nombres + f * 32 + c]
                          != mio[vdp.nombres + f * 32 + c])
                suma("LA PANTALLA DEL TITULO (24x32 celdas)", mal, 768)
                suma("colores del titulo 0x00-0xE7",
                     *dif(real, mio, 0x0000, 0x0740))
                suma("patrones del titulo 0x00-0xE7",
                     *dif(real, mio, 0x2000, 0x2740))
    print("  %d volcados de openMSX leidos (%d saltados por tener la pantalla"
          " en blanco)" % (vistos, saltados[0]))
    peor = 0
    for k in sorted(tot):
        mal, n = tot[k]
        peor = max(peor, mal)
        print("  %-38s %6d / %-7d bytes distintos" % (k, mal, n))
    return 0 if peor == 0 else 1


# ==========================================================================
def main(argv):
    if len(argv) >= 5 and argv[1] == "--comprueba":
        rom = Rom(open(argv[2], "rb").read(), int(argv[3], 0))
        return comprueba(rom, Vdp(rom.d, rom.org), argv[4:])
    if len(argv) < 4:
        print(__doc__)
        return 2
    rom = Rom(open(argv[1], "rb").read(), int(argv[2], 0))
    destino = argv[3]
    os.makedirs(destino, exist_ok=True)
    vdp = Vdp(rom.d, rom.org)
    print("  VDP: nombres 0x%04X, patrones 0x%04X, colores 0x%04X, sprites 0x%04X"
          % (vdp.nombres, vdp.patrones, vdp.colores, vdp.sprite_pat))

    def salva(nombre, whp, que):
        png(whp[0], whp[1], whp[2], os.path.join(destino, nombre))
        print("  %-22s %s  (%dx%d)" % (nombre, que, whp[0], whp[1]))

    # --- las hojas de caracteres -----------------------------------------
    base = vram_base(rom, vdp)
    fin = carga_fuente(rom, vdp, bytearray(0x4000))
    if fin != 0x4D61:
        raise SystemExit("  la fuente tenia que acabar en 0x4D61 y acabo en 0x%04X"
                         % fin)
    salva("fuente.png", hoja(base, vdp, 0x10, 0x59),
          "los 74 caracteres de la fuente, 0x10-0x59")
    salva("lisos.png", hoja(base, vdp, 0x00, 0x0F),
          "los 16 caracteres de color entero, 0x00-0x0F")

    juego = bytearray(base)
    f1, f2 = carga_paisaje(rom, vdp, juego)
    if (f1, f2) != (0x702B, 0x70DE):
        raise SystemExit("  el paisaje acaba en 0x%04X/0x%04X, no en 0x702B/0x70DE"
                         % (f1, f2))
    salva("paisaje.png", hoja(juego, vdp, 0x40, 0xA7),
          "los 104 caracteres del paisaje, 0x40-0xA7")

    vrams = {}
    for cual in (1, 2):
        v = bytearray(juego)
        g1, g2 = carga_gigante(rom, vdp, v, cual)
        esperado = (0x7285, 0x7323) if cual == 1 else (0x74A7, 0x7522)
        if (g1, g2) != esperado:
            raise SystemExit("  el gigante %d acaba en 0x%04X/0x%04X, no en %s"
                             % (cual, g1, g2, esperado))
        vrams[cual] = v
        salva("bicho_%d.png" % cual, hoja(v, vdp, 0xB0, 0xEC),
              "los 61 caracteres del enemigo grande %d, 0xB0-0xEC" % cual)

    spr = bytearray(0x4000)
    fin, escritos = carga_sprites(rom, vdp, spr)
    if fin != 0x5334:
        raise SystemExit("  los sprites acaban en 0x%04X, no en 0x5334" % fin)
    n_spr = escritos // 32
    salva("sprites.png", hoja_sprites(spr, vdp, n_spr),
          "los %d sprites de 16x16 descomprimidos en 0x%04X (%d bytes, %d patrones"
          " de 8x8)" % (n_spr, vdp.sprite_pat, escritos, escritos // 8))

    # --- la pantalla del titulo ------------------------------------------
    tit = bytearray(base)
    carga_titulo(rom, vdp, tit)
    salva("titulo.png", pantalla(tit, vdp),
          "la pantalla del titulo, con CARGA_TITULO y PINTA_ROTULO")
    f0, f1_, c0, c1 = marco(tit, vdp, 0xC0)
    celdas = [[tit[vdp.nombres + f * 32 + c] for c in range(c0, c1 + 1)]
              for f in range(f0, f1_ + 1)]
    salva("rotulo.png", pinta_celdas(tit, vdp, celdas, esc=4),
          "el rotulo, filas %d-%d y columnas %d-%d" % (f0, f1_, c0, c1))

    # --- la fase ----------------------------------------------------------
    bien, total, cierra = comprueba_continuidad(rom, vdp)
    print("  fase: %d de %d parejas de posiciones encajan bajando una fila; "
          "el cierre 1919->0 %s" % (bien, total, "encaja" if cierra else "NO ENCAJA"))
    if bien != total or not cierra:
        raise SystemExit("  la fase NO es continua: el formato del fondo falla")
    filas = nivel_entero(rom, vdp)
    gigantes = tramos_del_gigante(filas)
    print("  fase: los caracteres 0xB0-0xEC salen en %d tramos: %s"
          % (len(gigantes), ", ".join("%d-%d" % (a, z) for a, z in gigantes)))
    if len(gigantes) != 2:
        raise SystemExit("  el enemigo grande tenia que salir dos veces")

    tramo = LARGO // 8
    trozos = []
    for k in range(8):
        a, z = k * tramo, (k + 1) * tramo
        trozos.append(tira_del_nivel(vrams, vdp, filas, gigantes, a, z, esc=1))
        salva("nivel_%02d.png" % k,
              tira_del_nivel(vrams, vdp, filas, gigantes, a, z, esc=2),
              "filas %d-%d de la fase" % (k * tramo, (k + 1) * tramo - 1))
    salva("nivel.png", junta(trozos),
          "LA FASE ENTERA: 1920 filas en ocho columnas, de abajo arriba")

    # --- el enemigo grande ------------------------------------------------
    for k, (a, z) in enumerate(gigantes):
        cual = k + 1
        # la ventana de 24 filas que deja el cuerpo entero dentro, con el
        # margen justo por arriba y por abajo
        alto = z - a + 1
        desde = a - (24 - alto) // 2
        celdas = [list(filas[n][1:24])
                  for n in range(desde + 23, desde - 1, -1)]
        salva("enemigo_grande_%d.png" % cual,
              pinta_celdas(vrams[cual], vdp, celdas, esc=3),
              "el enemigo grande %d: filas %d-%d de la fase" % (cual, a, z))

    # --- la pantalla de partida -------------------------------------------
    # la posicion no se elige a ojo: se coge la que mas caracteres distintos
    # del paisaje deja en pantalla, saltandose las dos ventanas del enemigo
    # grande (que ya tienen su propia imagen)
    def variedad(pos):
        return len(set(c for f in range(24)
                       for c in filas[(pos - f) % LARGO][1:24]))

    def limpia(pos):
        return not any(a - 24 <= pos <= z + 24 for a, z in gigantes)
    mejor = max((p for p in range(LARGO) if limpia(p)), key=variedad)
    v = bytearray(vrams[cual_gigante(gigantes, mejor)])
    paso_de_fondo(rom, v, mejor)
    pinta_panel(rom, vdp, v)
    salva("pantalla_juego.png", pantalla(v, vdp),
          "la pantalla de partida en la posicion %d (%d caracteres distintos):"
          " fondo de 0x5837 y panel de 0x42B0" % (mejor, variedad(mejor)))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
