#!/usr/bin/env python3
"""Genera la portada de la web de Sky Jaguar, en los dos idiomas.

El diseno es el compartido por la serie (tools/estilo_web.py) y la pagina sale
autocontenida, con las imagenes embebidas como data URI.

Las imagenes NO son ilustraciones ni capturas: las dibuja tools/graficos.py a
partir de los propios bytes de la ROM, ejecutando en Python los mismos
descompresores que corre el Z80, y estan comprobadas byte a byte contra la VRAM
de openMSX. Ninguna se ha retocado.

Uso: make_web.py <docs/imagenes> <salida.html> <idioma>
"""
import base64
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from estilo_web import ESTILO                                   # noqa: E402

# Las cifras salen de contar sobre el listado generado, no de escribirlas a ojo:
# 16384 = 7086 + 9298, que es lo que imprime tools/presupuesto.py (make sanity).
# RUTINAS son las etiquetas de codigo con nombre propio, las mismas que cuenta
# el .notes con su directiva L. FILAS es el largo de la unica fase del juego.
CODIGO = 7086
DATOS = 9298
RUTINAS = 464
FILAS = 1920


def mil(n, idioma):
    return f"{n:,}".replace(",", "." if idioma == "es" else ",")


TXT = {
    "es": dict(
        titulo="Sky Jaguar — desensamblado comentado",
        aviso="<b>Aquí no hay ninguna ilustración ni captura.</b> El rótulo, el "
              "paisaje y <b>la fase entera</b> están <b>dibujados desde los "
              "bytes de la ROM</b>, ejecutando en Python los mismos "
              "descompresores que corre el Z80, y comprobados byte a byte "
              "contra la VRAM del emulador. El listado y las cifras salen del "
              "binario y se reproducen con <code>make</code>.",
        claim="Un matamarcianos vertical en 16 KB, con una sola fase de 1.920 "
              "filas que se repite, un paisaje que va comprimido en guiones de "
              "rachas, y un enemigo gigante al que le dibuja el cuerpo el "
              "propio fondo.",
        ficha=["Konami · <b>© Konami 1984</b>",
               "Cartucho <b>RC-721</b>, 16 KB",
               "MSX1 · <b>página 1</b>", "Volcado <b>58abc5ae…</b>"],
        nav=[("#numbers", "Las cifras"), ("#findings", "Hallazgos"),
             ("#screens", "Lo que dibuja")],
        docnav=[("EMPEZAR.html", "Empezar"), ("EL-JUEGO.html", "El juego"),
                ("EL-CARTUCHO.html", "El cartucho"),
                ("EL-CODIGO.html", "El código"),
                ("HALLAZGOS.html", "Hallazgos"),
                ("EN-EL-EMULADOR.html", "En el emulador"),
                ("PREGUNTAS-ABIERTAS.html", "Preguntas abiertas")],
        otro=("../", "In English"),
        h_num="El cartucho en cifras", h_find="Lo que apareció al desmontarlo",
        h_scr="Lo que el cartucho dibuja",
        cifras=[("100 %", "del binario explicado"),
                (str(RUTINAS), "rutinas identificadas"),
                (mil(FILAS, "es"), "filas de la única fase"),
                (mil(CODIGO, "es"), "bytes de código"),
                (mil(DATOS, "es"), "bytes de datos"),
                ("0", "bytes sin identificar")],
        nota_scr="Debajo de cada imagen está de dónde sale y qué se está "
                 "viendo.",
        pie_leg="Esto es trabajo de documentación y preservación: el código y "
                "los gráficos siguen siendo de sus autores y de Konami, y la "
                "imagen del cartucho no se distribuye.",
    ),
    "en": dict(
        titulo="Sky Jaguar — a commented disassembly",
        aviso="<b>There is not one illustration or capture here.</b> The "
              "wordmark, the landscape and <b>the whole stage</b> are "
              "<b>drawn from the bytes of the ROM</b>, by running in Python the "
              "same decompressors the Z80 runs, and checked byte for byte "
              "against the emulator's VRAM. The listing and the numbers come "
              "from the binary and are reproducible with <code>make</code>.",
        claim="A vertical shooter in 16 KB, with a single 1,920-row stage that "
              "repeats, a landscape stored as run-length scripts, and a giant "
              "enemy whose body is drawn by the background itself.",
        ficha=["Konami · <b>© Konami 1984</b>",
               "An <b>RC-721</b> 16 KB cartridge",
               "MSX1 · <b>page 1</b>", "Dump <b>58abc5ae…</b>"],
        nav=[("#numbers", "The numbers"), ("#findings", "What turned up"),
             ("#screens", "What it draws")],
        docnav=[("GETTING-STARTED.html", "Getting started"),
                ("THE-GAME.html", "The game"),
                ("THE-CARTRIDGE.html", "The cartridge"),
                ("THE-CODE.html", "The code"),
                ("FINDINGS.html", "Findings"),
                ("IN-THE-EMULATOR.html", "In the emulator"),
                ("OPEN-QUESTIONS.html", "Open questions")],
        otro=("es/", "En castellano"),
        h_num="The cartridge in numbers",
        h_find="What turned up when we took it apart",
        h_scr="What the cartridge draws",
        cifras=[("100%", "of the binary explained"),
                (str(RUTINAS), "routines identified"),
                (mil(FILAS, "en"), "rows in the only stage"),
                (mil(CODIGO, "en"), "bytes of code"),
                (mil(DATOS, "en"), "bytes of data"),
                ("0", "bytes unidentified")],
        nota_scr="Under each picture is where it comes from and what is on it.",
        pie_leg="This is documentation and preservation work: the code and "
                "artwork still belong to their authors and to Konami, and the "
                "cartridge image is not distributed.",
    ),
}

HALLAZGOS = {
    "es": [
        ("No lleva la marca oculta de Konami, y se ha comprobado en serio",
         "<p>Konami escondía al final de muchos cartuchos su número de catálogo "
         "y el título en katakana; lo descubrió <b>Manuel Pazos</b> "
         "(<a href=\"https://twitter.com/ManuelPazosMSX\">@ManuelPazosMSX</a>) "
         "y el bloque vive en el offset 0x3FF0. <b>Éste no la lleva</b>, y no "
         "por no mirar: se rastrearon las 16.384 posiciones de la ROM con un "
         "buscador <b>validado antes contra cuatro cartuchos de la misma "
         "familia que sí la llevan</b>, que es la única manera de fiarse de un "
         "negativo. La razón se ve en el volcado: la ROM llega llena de datos "
         "hasta 0x7FFB y sólo sobran cuatro bytes de relleno. No cabe.</p>"),
        ("Una sola fase de 1.920 filas, y el scroll sale de una tabla",
         "<p>No hay niveles: hay <b>una fase</b> que se repite, y lo único que "
         "sube es la dificultad (0xE1D3, <b>con tope 2</b>). El paisaje va "
         "comprimido: 244 bytes eligen, cada ocho filas, cuál de veinte tiras "
         "se dibuja. Y el desplazamiento fino no se calcula, <b>está guardado</b>: "
         "cada tira tiene <b>ocho versiones</b>, la misma empezada de cero a "
         "siete filas más abajo, y el índice es <code>2·(posición y 7)</code>.</p>"),
        ("Al enemigo gigante le dibuja el cuerpo el fondo",
         "<p>Sale dos veces en la fase, en dos mitades, y <b>su cuerpo no son "
         "sprites</b>: las tiras de paisaje de tipo 18 y 19 son las únicas del "
         "mapa que usan los caracteres 0xB0–0xEC, y cada una aparece <b>una "
         "sola vez</b>. Encima van los sprites de las piezas a las que se "
         "dispara. El juego lo arranca <b>tres pasos antes</b> de que asome, "
         "para que dé tiempo a descomprimir sus gráficos.</p>"),
        ("La tabla de puntería tiene dos entradas cambiadas",
         "<p>0x6917 son nueve direcciones de disparo, un cuarto de vuelta con "
         "radio 320. <b>Siete de las nueve cuadran al bit</b> con "
         "<code>320·sen</code> y <code>320·cos</code>; las entradas <b>3 y 5 "
         "contienen exactamente lo de la otra</b>. No es redondeo: es una "
         "errata, y dos de los nueve ángulos de disparo enemigo apuntan al "
         "espejo del que les tocaba.</p>"),
        ("Dos saltos que caen a mitad de una instrucción, a propósito",
         "<p>En 0x6684 un <code>jr c</code> aterriza en el <b>último byte</b> "
         "del <code>ld bc,0x0300</code> de 0x6686. Ese byte es <code>0x03</code>, "
         "y suelto se ejecuta como <code>inc bc</code>: con acarreo BC queda en "
         "0xFE01, y sin acarreo se ejecuta el <code>ld</code> entero. Un byte "
         "ahorrado frente a un <code>jp</code>. En 0x69A1 hacen lo mismo con el "
         "<code>03</code> de un <code>ld (hl),3</code>.</p>"),
        ("El mismo guión pinta y borra",
         "<p>De los dos descompresores de la casa, el de la tabla de nombres "
         "(0x43D8) tiene una segunda puerta en 0x43F3: entrando por ahí escribe "
         "<b>ceros</b> en vez del dato. Así el cartucho no guarda un guión para "
         "poner cada cosa y otro para quitarla, sino uno solo.</p>"),
    ],
    "en": [
        ("It does not carry Konami's hidden mark, and that was checked properly",
         "<p>At the end of many cartridges Konami hid its catalogue number and "
         "the title in katakana; <b>Manuel Pazos</b> "
         "(<a href=\"https://twitter.com/ManuelPazosMSX\">@ManuelPazosMSX</a>) "
         "found it, and the block lives at offset 0x3FF0. <b>This one does "
         "not have it</b>, and not for want of looking: all 16,384 positions "
         "were scanned with a finder <b>first validated against four other "
         "cartridges of the same family that do carry it</b>, which is the only "
         "way to trust a negative. The dump shows why: the ROM "
         "runs full of data to 0x7FFB, with four bytes of filler left. No "
         "room.</p>"),
        ("One 1,920-row stage, and the scroll comes out of a table",
         "<p>There are no levels: there is <b>one stage</b> that repeats, and "
         "all that climbs is the difficulty (0xE1D3, <b>capped at 2</b>). The "
         "landscape is compressed: 244 bytes choose, every eight rows, which of "
         "twenty strips to draw. And the fine scroll is not computed, it is "
         "<b>stored</b>: every strip has <b>eight versions</b>, the same one "
         "started zero to seven rows lower, indexed by "
         "<code>2·(position and 7)</code>.</p>"),
        ("The giant enemy's body is drawn by the background",
         "<p>It appears twice in the stage, in two halves, and <b>its body is "
         "not sprites</b>: landscape strip types 18 and 19 are the only ones in "
         "the map that use characters 0xB0–0xEC, and each appears <b>exactly "
         "once</b>. On top go the sprites of the parts you shoot. The game "
         "starts it <b>three steps before</b> it comes into view, to give its "
         "graphics time to decompress.</p>"),
        ("The aiming table has two entries swapped",
         "<p>0x6917 holds nine firing directions, a quarter turn at radius 320. "
         "<b>Seven of the nine match to the bit</b> against <code>320·sin</code> "
         "and <code>320·cos</code>; entries <b>3 and 5 hold exactly what the "
         "other should</b>. This is not rounding, it is an erratum, and two of "
         "the nine enemy firing angles point at the mirror of their intended "
         "one.</p>"),
        ("Two jumps that land mid-instruction, deliberately",
         "<p>At 0x6684 a <code>jr c</code> lands on the <b>last byte</b> of the "
         "<code>ld bc,0x0300</code> at 0x6686. That byte is <code>0x03</code>, "
         "and alone it executes as <code>inc bc</code>: with carry BC ends at "
         "0xFE01, without it the whole <code>ld</code> runs. One byte saved over "
         "a <code>jp</code>. At 0x69A1 the same trick is played with the "
         "<code>03</code> of a <code>ld (hl),3</code>.</p>"),
        ("The same script both paints and erases",
         "<p>Of the two in-house decompressors, the name-table one (0x43D8) has "
         "a second door at 0x43F3: entering there it writes <b>zeros</b> instead "
         "of the data. So the cartridge does not keep one script to put each "
         "thing on screen and another to take it off — just one.</p>"),
    ],
}

GALERIA = [
    ("nivel.png",
     "<b>La fase entera</b>: las 1.920 filas, cortadas en ocho columnas de 240 "
     "y puestas una al lado de otra. Sale de ejecutar en Python el mismo "
     "PASO_DE_FONDO (0x5837) del cartucho sobre las 1.920 posiciones. Que es "
     "correcta no es una impresión: el mosaico se comparó celda a celda contra "
     "pantallas reales volcadas de openMSX, y salieron cero diferencias en "
     "11.592 celdas",
     "<b>The whole stage</b>: all 1,920 rows, cut into eight columns of 240 and "
     "set side by side. It comes from running the cartridge's own PASO_DE_FONDO "
     "(0x5837) in Python over the 1,920 positions. That it is right is not an "
     "impression: the mosaic was compared cell by cell against real screens "
     "dumped from openMSX, with zero differences across 11,592 cells"),
    ("enemigo_grande_1.png",
     "El primero de los dos enemigos gigantes, sobre el mar. Lo llamativo es "
     "que <b>este cuerpo no son sprites</b>: lo pinta el propio fondo, con una "
     "tira de paisaje que aparece una sola vez en todo el mapa",
     "The first of the two giant enemies, over the sea. The striking part is "
     "that <b>this body is not sprites</b>: the background paints it, with a "
     "landscape strip that appears exactly once in the whole map"),
    ("enemigo_grande_2.png",
     "El segundo gigante, con sus propios caracteres. El juego empieza a "
     "montarlo tres pasos antes de que asome por abajo",
     "The second giant, with its own characters. The game starts assembling it "
     "three steps before it comes up from the bottom"),
    ("titulo.png",
     "La pantalla del título, montada con los mismos pasos del cartucho: "
     "CARGA_TITULO (0x434D) descomprime las piezas del rótulo y PINTA_ROTULO "
     "(0x4374) las coloca en la tabla de nombres",
     "The title screen, built with the cartridge's own steps: CARGA_TITULO "
     "(0x434D) decompresses the wordmark's pieces and PINTA_ROTULO (0x4374) "
     "places them in the name table"),
    ("pantalla_juego.png",
     "Una pantalla de partida con su panel, en la posición de la fase con más "
     "caracteres distintos a la vez",
     "A gameplay screen with its panel, at the position in the stage with the "
     "most distinct characters at once"),
    ("paisaje.png",
     "Los 104 caracteres con los que se dibuja todo el paisaje (0x40–0xA7), "
     "descomprimidos desde 0x6DCA con sus colores de 0x702B",
     "The 104 characters the whole landscape is drawn with (0x40–0xA7), "
     "decompressed from 0x6DCA with their colours from 0x702B"),
    ("lisos.png",
     "Los dieciséis caracteres 0x00–0x0F, que <b>no tienen patrón ninguno</b>: "
     "0x4B71 le da a cada uno un color entero, y son el mar y los llanos",
     "The sixteen characters 0x00–0x0F, which <b>have no pattern at all</b>: "
     "0x4B71 gives each one a solid colour, and they are the sea and the "
     "flatlands"),
    ("sprites.png",
     "Los 48 sprites de 16×16 del cartucho, del guión de 0x4F1B. Son 1.536 "
     "bytes a la VRAM: el avión, los enemigos, los disparos y las explosiones",
     "The cartridge's 48 sprites of 16×16, from the script at 0x4F1B. That is "
     "1,536 bytes to VRAM: the plane, the enemies, the shots and the explosions"),
    ("fuente.png",
     "La fuente con la que se escribe todo, del rango 0x10–0x59",
     "The font everything is written with, from the 0x10–0x59 range"),
]


def img64(ruta):
    with open(ruta, "rb") as f:
        return "data:image/png;base64," + base64.b64encode(f.read()).decode()


def main(argv):
    if len(argv) < 4:
        print(__doc__)
        return 2
    imgdir, salida, idioma = argv[1:4]
    t = TXT[idioma]

    # El "logotipo" de la cabecera no es un montaje ni una captura: es el rotulo
    # que el propio cartucho pinta en su pantalla de titulo, dibujado desde la
    # ROM por graficos.py. Si el PNG no esta, el trabajo NO esta hecho: se cae
    # al texto, y eso se ve.
    ruta_logo = os.path.join(imgdir, "rotulo.png")
    cabecera = (f'<img src="{img64(ruta_logo)}" alt="Sky Jaguar">'
                if os.path.exists(ruta_logo) else "<h1>Sky Jaguar</h1>")

    nav = "".join(f'<a href="{h}">{x}</a>' for h, x in t["nav"])
    nav += "".join(f'<a href="{h}">{x}</a>' for h, x in t["docnav"])
    nav += (f'<a href="{t["otro"][0]}" style="margin-left:auto;color:var(--oro)">'
            f'{t["otro"][1]}</a>')

    cifras = "".join(f'<div class="cifra"><b>{v}</b><span>{e}</span></div>'
                     for v, e in t["cifras"])
    halls = "".join(f'<div class="hall"><h3>{tit}</h3>{cuerpo}</div>'
                    for tit, cuerpo in HALLAZGOS[idioma])
    imgs = ""
    faltan = []
    for fich, es, en in GALERIA:
        ruta = os.path.join(imgdir, fich)
        if not os.path.exists(ruta):
            faltan.append(fich)
            continue
        pie = es if idioma == "es" else en
        imgs += (f'<figure><img src="{img64(ruta)}" alt="{pie}">'
                 f'<figcaption>{pie}</figcaption></figure>')
    if faltan:
        print("  (faltan %d imagenes: %s)" % (len(faltan), " ".join(faltan)))

    html = f"""<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>{t['titulo']}</title>
<style>{ESTILO}</style>
<header class="top">
  {cabecera}
  <p class="claim">{t['claim']}</p>
  <p class="ficha">{' · '.join(t['ficha'])}</p>
</header>
<p class="ficha" style="border:1px solid var(--oro);padding:.8em 1em;margin:1.5em 0">
{t['aviso']}</p>
<nav>{nav}</nav>
<section id="numbers">
  <h2>{t['h_num']}</h2>
  <div class="cifras">{cifras}</div>
</section>
<section id="findings"><h2>{t['h_find']}</h2>{halls}</section>
<section id="screens">
  <h2>{t['h_scr']}</h2>
  <p class="n">{t['nota_scr']}</p>
  <div class="galeria">{imgs}</div>
</section>
<footer><p>{t['pie_leg']}</p></footer>
"""
    with open(salida, "w", encoding="utf-8") as f:
        f.write(html)
    print("  %s: %d KB (%s)" % (salida, len(html) // 1024, idioma))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
