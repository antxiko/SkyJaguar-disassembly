# Sky Jaguar (Konami, MSX1) - desensamblado
#
# El orden de las cosas: trazar el flujo -> generar el listado -> comprobar que
# vuelve a dar la ROM byte a byte -> las comprobaciones que el reensamblado NO
# cubre.
#
# La ROM no se distribuye. Hace falta en la raiz como skyjaguar.rom, y
# `make comprueba` verifica el sha256.

ROM      = skyjaguar.rom
SHA      = 58abc5aec19dbca6f6aaf278b233a85219afde9622a9c3b34544b94a350d2a3b
SRC      = src
WORK     = work
ORG      = 0x4000
TITULO   = SKY JAGUAR - Konami - MSX1 - cartucho RC-721 de 16 KB en la pagina 1

all: listado verify sanity test

$(ROM):
	@echo "=================================================================="
	@echo " Falta $(ROM), y este repositorio NO lo distribuye."
	@echo ""
	@echo " Es Sky Jaguar (Konami, RC-721) para MSX, 16384 bytes exactos."
	@echo " Ponlo aqui con ese nombre. Para comprobar que es el mismo:"
	@echo "     shasum -a 256 $(ROM)"
	@echo "     $(SHA)"
	@echo "=================================================================="
	@false

comprueba: $(ROM)
	@echo "$(SHA)  $(ROM)" | shasum -a 256 -c -

# El trazado sigue el flujo desde los puntos de entrada. Los que no se pueden
# deducir estaticamente -ganchos de interrupcion, destinos de saltos
# indirectos- estan declarados en el .entries, cada uno con su justificacion.
$(WORK)/skyjaguar.trace.json: $(ROM) $(SRC)/skyjaguar.entries $(SRC)/skyjaguar.nocode
	@mkdir -p $(WORK)
	python3 tools/z80trace.py $(ROM) $(ORG) $(SRC)/skyjaguar.entries \
	        $(WORK)/skyjaguar $(SRC)/skyjaguar.nocode

trace: $(WORK)/skyjaguar.trace.json

listado: $(WORK)/skyjaguar.trace.json $(SRC)/skyjaguar.notes
	python3 tools/mkasm.py $(ROM) $(ORG) $(WORK)/skyjaguar.trace.json \
	        $(SRC)/skyjaguar.notes work/msx.sym $(SRC)/skyjaguar.asm "$(TITULO)"

# La prueba que decide si el desensamblado es fiable.
verify: $(SRC)/skyjaguar.asm $(ROM)
	@sh tools/verify_build.sh $(SRC)/skyjaguar.asm $(ROM) $(ORG)

# Lo que el reensamblado NO puede cazar: que unos datos se esten leyendo como
# codigo. El binario sale identico igual, porque los bytes no cambian; lo unico
# que cambia es lo que decimos de ellos.
sanity: $(WORK)/skyjaguar.trace.json
	@echo "=================================================================="
	@echo " ningun byte declarado como datos puede salir como codigo"
	@echo "=================================================================="
	@python3 tools/check_trace.py $(WORK)/skyjaguar.trace.json $(SRC)/skyjaguar.nocode
	@python3 tools/check_datos_como_codigo.py $(WORK) $(SRC)
	@echo "=================================================================="
	@echo " ningun punto de entrada puede caer dentro de una zona de datos"
	@echo "=================================================================="
	@python3 tools/check_entradas.py $(SRC)/skyjaguar.entries $(SRC)/skyjaguar.notes \
	        $(SRC)/skyjaguar.nocode
	@echo "=================================================================="
	@echo " ni un byte del cartucho sin asignar"
	@echo "=================================================================="
	@python3 tools/presupuesto.py $(WORK) $(SRC)

densidad:
	@python3 tools/densidad.py $(SRC)/skyjaguar.asm

test:
	@echo "=================================================================="
	@echo " Tests"
	@echo "=================================================================="
	@python3 -m unittest discover -s tests -v

# Dibuja los bloques de datos graficos declarados en el .notes, para MIRARLOS.
imagenes: $(ROM)
	@mkdir -p work/gfx
	python3 tools/dibuja.py $(ROM) $(ORG) $(SRC)/skyjaguar.notes work/gfx

# LA WEB
#
# Bilingue: el ingles en docs/ y el castellano en docs/es/. Las paginas se
# escriben en markdown y se convierten con md2html.py; la portada la monta
# make_web.py, que declara las cifras medidas de ESTE cartucho.
web: $(ROM)
	python3 tools/graficos.py $(ROM) $(ORG) docs/imagenes
	python3 tools/md2html.py docs en
	python3 tools/md2html.py docs/es es
	python3 tools/make_web.py docs/imagenes docs/index.html en
	python3 tools/make_web.py docs/imagenes docs/es/index.html es
	python3 tools/check_enlaces.py docs

clean:
	rm -rf $(WORK)/skyjaguar.trace.json $(WORK)/skyjaguar.blocks

.PHONY: all comprueba trace listado verify sanity test densidad imagenes web clean
