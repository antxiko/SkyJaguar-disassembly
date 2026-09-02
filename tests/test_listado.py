#!/usr/bin/env python3
"""Comprobaciones sobre el listado generado.

Ninguna necesita el cartucho: se hacen sobre src/skyjaguar.asm y
src/skyjaguar.notes. Vigilan que el listado no se degrade sin que nadie se
entere: que no desaparezcan comentarios, que no vuelvan a aparecer bloques de
datos sin identificar, y que las cifras publicadas sean las del arbol.
"""
import json
import os
import re
import unittest

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ASM = os.path.join(RAIZ, "src", "skyjaguar.asm")
NOTES = os.path.join(RAIZ, "src", "skyjaguar.notes")
TRACE = os.path.join(RAIZ, "work", "skyjaguar.trace.json")
DOCS = os.path.join(RAIZ, "docs")
ORG, FIN = 0x4000, 0x8000

# Los demas juegos de la serie. Que el nombre de otro aparezca en una pagina de
# este es casi siempre un copia y pega. Los dos hermanos de armazon -Hyper
# Olympic y Hyper Sports- pueden nombrarse en la pagina de hallazgos, donde el
# asunto es JUSTO cuanto codigo se comparte.
OTROS_JUEGOS = ("Pitfall", "Temptations", "Stardust", "Ale Hop", "Colt 36",
                "Middle Earth", "Monkey", "F-1 Spirit", "Athletic",
                "Antarctic", "Pippols", "Frogger", "Time Pilot",
                "Super Cobra", "Billiards", "Mahjong", "Hyper Rally",
                "Hyper Olympic", "Hyper Sports", "Cabbage Patch",
                "Demonia", "Nemesis", "Golf", "Tennis")


def asm():
    with open(ASM, encoding="utf-8") as f:
        return f.read()


def notas():
    with open(NOTES, encoding="utf-8") as f:
        return f.read().splitlines()


def directivas(clave):
    return [l for l in notas() if l.startswith(clave + " ")]


class TestListado(unittest.TestCase):

    def test_ningun_bloque_de_datos_sin_identificar(self):
        n = asm().count("DATOS sin identificar")
        self.assertEqual(n, 0, "hay %d bloques de datos sin identificar" % n)

    def test_todas_las_rutinas_con_call_tienen_nombre(self):
        sueltas = sorted(set(re.findall(
            r"\bcall (?:n?[zc],|p[oe],|[mp],)?(L_[0-9A-F]{4})", asm())))
        self.assertEqual(sueltas, [], "rutinas llamadas y sin nombre: %s"
                         % " ".join(sueltas[:12]))

    def test_no_queda_ninguna_etiqueta_sin_bautizar(self):
        sueltas = sorted(set(re.findall(r"\bL_[0-9A-F]{4}\b", asm())))
        self.assertEqual(sueltas, [], "etiquetas sin nombre: %s"
                         % " ".join(sueltas[:12]))

    def test_ninguna_etiqueta_declarada_dos_veces(self):
        nombres = re.findall(r"^([A-Za-z_][\w]*):", asm(), re.M)
        repetidas = sorted({n for n in nombres if nombres.count(n) > 1})
        self.assertEqual(repetidas, [], "etiquetas repetidas: %s"
                         % " ".join(repetidas))

    def test_ningun_comentario_de_linea_repetido(self):
        dirs = [l.split()[1].upper() for l in directivas("C")]
        repes = sorted({d for d in dirs if dirs.count(d) > 1})
        self.assertEqual(repes, [], "comentarios repetidos en %s" % " ".join(repes))

    def test_ninguna_direccion_bautizada_dos_veces(self):
        dirs = [l.split()[1] for l in directivas("L")]
        repes = sorted({d for d in dirs if dirs.count(d) > 1})
        self.assertEqual(repes, [], "direcciones con dos nombres: %s"
                         % " ".join(repes))

    def test_todos_los_comentarios_llegan_al_listado(self):
        vivas = set(re.findall(r";([0-9a-f]{4})(?:\s|$)", asm(), re.M))
        perdidos = [l.split()[1] for l in directivas("C")
                    if l.split()[1][2:].lower() not in vivas]
        self.assertEqual(perdidos, [], "comentarios que no llegan: %s"
                         % " ".join(perdidos[:12]))

    def test_todas_las_cabeceras_llegan_al_listado(self):
        vivas = set(re.findall(r";([0-9a-f]{4})(?:\s|$)", asm(), re.M))
        perdidas = sorted({l.split()[1] for l in directivas("B")
                           if l.split()[1][2:].lower() not in vivas})
        self.assertEqual(perdidas, [], "cabeceras que no llegan: %s"
                         % " ".join(perdidas[:12]))

    def test_todas_las_etiquetas_llegan_al_listado(self):
        texto = asm()
        perdidas = [l.split()[2] for l in directivas("L")
                    if not re.search(r"^%s:" % re.escape(l.split()[2]), texto, re.M)
                    and not re.search(r"^%s:\s+equ" % re.escape(l.split()[2]),
                                      texto, re.M)]
        self.assertEqual(perdidas, [], "etiquetas que no llegan: %s"
                         % " ".join(perdidas[:12]))

    def test_los_rangos_no_se_solapan(self):
        rangos = sorted((int(l.split()[1], 16), int(l.split()[2], 16),
                         l.split()[3]) for l in directivas("D"))
        for (a1, b1, n1), (a2, b2, n2) in zip(rangos, rangos[1:]):
            self.assertLessEqual(b1, a2, "%s (%04X-%04X) pisa a %s (%04X-%04X)"
                                 % (n1, a1, b1, n2, a2, b2))

    def test_todos_los_rangos_van_al_derecho_y_dentro(self):
        for l in directivas("D"):
            a, b, nombre = int(l.split()[1], 16), int(l.split()[2], 16), l.split()[3]
            self.assertLess(a, b, "%s va del reves" % nombre)
            self.assertGreaterEqual(a, ORG, "%s empieza fuera" % nombre)
            self.assertLessEqual(b, FIN, "%s acaba fuera" % nombre)

    def test_todos_los_rangos_estan_explicados(self):
        pelados = [l.split()[3] for l in directivas("D") if len(l.split()) < 5]
        self.assertEqual(pelados, [], "rangos sin explicacion: %s"
                         % " ".join(pelados))

    def test_cada_anchura_cae_en_un_rango(self):
        inicios = {l.split()[1].lower() for l in directivas("D")}
        sueltas = [l.split()[1] for l in directivas("F")
                   if l.split()[1].lower() not in inicios]
        self.assertEqual(sueltas, [], "anchuras sin rango: %s"
                         % " ".join(sueltas[:12]))

    def test_el_listado_lo_genera_la_herramienta(self):
        self.assertIn("Generado por tools/mkasm.py", asm())

    def test_no_queda_nada_por_repartir(self):
        pendientes = [l for l in notas()
                      if "formato pendiente" in l or "reparto por" in l]
        self.assertEqual(pendientes, [], "quedan %d zonas por repartir"
                         % len(pendientes))

    def test_el_listado_no_habla_de_otro_juego(self):
        for juego in OTROS_JUEGOS:
            self.assertNotIn(juego, asm(), "el listado nombra %s" % juego)

    def test_la_raiz_no_habla_de_otro_juego(self):
        for fichero in ("README.md", "README.es.md", "AVISO-LEGAL.md",
                        "LEGAL-NOTICE.md", "LICENSE"):
            ruta = os.path.join(RAIZ, fichero)
            if not os.path.exists(ruta):
                continue
            with open(ruta, encoding="utf-8") as f:
                texto = f.read()
            for juego in OTROS_JUEGOS:
                self.assertNotIn(juego, texto, "%s nombra %s" % (fichero, juego))


class TestWeb(unittest.TestCase):
    """La web es bilingue y se genera: lo que se vigila es que no se separe."""

    PAGINAS = [("GETTING-STARTED.md", "EMPEZAR.md"),
               ("THE-GAME.md", "EL-JUEGO.md"),
               ("THE-CARTRIDGE.md", "EL-CARTUCHO.md"),
               ("THE-CODE.md", "EL-CODIGO.md"),
               ("FINDINGS.md", "HALLAZGOS.md"),
               ("IN-THE-EMULATOR.md", "EN-EL-EMULADOR.md"),
               ("OPEN-QUESTIONS.md", "PREGUNTAS-ABIERTAS.md")]
    PUEDEN_COMPARAR = ("FINDINGS.md", "HALLAZGOS.md")

    def test_cada_pagina_tiene_su_pareja_en_el_otro_idioma(self):
        for en, es in self.PAGINAS:
            self.assertTrue(os.path.exists(os.path.join(DOCS, en)),
                            "falta docs/%s" % en)
            self.assertTrue(os.path.exists(os.path.join(DOCS, "es", es)),
                            "falta docs/es/%s" % es)

    def test_las_paginas_no_hablan_de_otro_juego(self):
        for raiz, _, ficheros in os.walk(DOCS):
            for fn in ficheros:
                if not fn.endswith(".md") or fn in self.PUEDEN_COMPARAR:
                    continue
                with open(os.path.join(raiz, fn), encoding="utf-8") as f:
                    texto = f.read()
                for juego in OTROS_JUEGOS:
                    self.assertNotIn(juego, texto,
                                     "%s nombra %s" % (fn, juego))

    def test_las_herramientas_de_la_web_no_hablan_de_otro_juego(self):
        for fn in ("make_web.py", "md2html.py", "graficos.py"):
            with open(os.path.join(RAIZ, "tools", fn), encoding="utf-8") as f:
                texto = f.read()
            for juego in OTROS_JUEGOS:
                self.assertNotIn(juego, texto, "tools/%s nombra %s"
                                 % (fn, juego))

    def test_la_portada_publica_las_cifras_del_arbol(self):
        with open(os.path.join(RAIZ, "tools", "make_web.py"),
                  encoding="utf-8") as f:
            texto = f.read()
        traza = json.load(open(TRACE, encoding="utf-8"))
        codigo = traza["report"]["code_bytes"]
        datos = FIN - ORG - codigo
        self.assertIn("CODIGO = %d" % codigo, texto,
                      "la portada no publica CODIGO = %d" % codigo)
        self.assertIn("DATOS = %d" % datos, texto,
                      "la portada no publica DATOS = %d" % datos)

    def test_los_readme_publican_las_cuentas_de_las_notas(self):
        cuentas = {clave: len(directivas(clave)) for clave in "LCD"}
        for fichero, filas in (
                ("README.md", (("named labels", "L"),
                               ("anchored comments", "C"),
                               ("explained data ranges", "D"))),
                ("README.es.md", (("etiquetas con nombre", "L"),
                                  ("comentarios anclados", "C"),
                                  ("rangos de datos con explicación", "D")))):
            with open(os.path.join(RAIZ, fichero), encoding="utf-8") as f:
                texto = f.read()
            for rotulo, clave in filas:
                fila = re.search(r"\|\s*%s\s*\|\s*([0-9.,]+)\s*\|"
                                 % re.escape(rotulo), texto)
                self.assertIsNotNone(fila, "%s no publica '%s'"
                                     % (fichero, rotulo))
                dice = int(fila.group(1).replace(".", "").replace(",", ""))
                self.assertEqual(dice, cuentas[clave],
                                 "%s dice %d %s y en las notas hay %d"
                                 % (fichero, dice, rotulo, cuentas[clave]))

    def test_las_paginas_no_inventan_direcciones(self):
        """Cada 0xNNNN del cartucho que se cite tiene que existir de verdad:
        arranque de instruccion o dentro de un rango de datos declarado."""
        with open(TRACE, encoding="utf-8") as f:
            traza = json.load(f)
        import sys
        sys.path.insert(0, os.path.join(RAIZ, "tools"))
        from z80trace import Tracer
        with open(os.path.join(RAIZ, "skyjaguar.rom"), "rb") as f:
            rom = f.read()
        t = Tracer(rom, ORG)
        arranques, datos = set(), set()
        for k, a, b in traza["blocks"]:
            if k == "c":
                p = a
                while p < b:
                    n = t.ilen(p)
                    if n == 0:
                        break
                    arranques.add(p)
                    p += n
            else:
                datos.update(range(a, b))
        cita = re.compile(r"0x([0-9A-Fa-f]{4})")
        for raiz, _, ficheros in os.walk(DOCS):
            for fn in ficheros:
                if not fn.endswith(".md"):
                    continue
                with open(os.path.join(raiz, fn), encoding="utf-8") as f:
                    pagina = f.read()
                for m in cita.finditer(pagina):
                    v = int(m.group(1), 16)
                    if not ORG <= v < FIN:
                        continue
                    self.assertTrue(v in arranques or v in datos or v == FIN - 1,
                                    "%s nombra 0x%04X y no existe" % (fn, v))


if __name__ == "__main__":
    unittest.main()
