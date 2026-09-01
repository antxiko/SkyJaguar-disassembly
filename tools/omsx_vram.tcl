# omsx_vram.tcl - Vuelca la VRAM de verdad de Sky Jaguar para comprobar los PNG.
#
# Para que sirve: tools/graficos.py monta las imagenes de la web ejecutando en
# Python los pasos del cartucho (los descompresores 0x4396 y 0x43D8 y el
# compositor de fondo 0x5837). Mirar el dibujo no basta: hay que comparar sus
# bytes con los que el VDP tiene de verdad. Esto deja correr el juego, y en
# varios instantes vuelca los 16 KB de VRAM, los ocho registros del VDP y las
# variables que hacen falta para saber QUE se estaba dibujando (sobre todo
# 0xE1B8/B9, la posicion en la fase).
#
# No pone NINGUN punto de ruptura: PASO_DE_FONDO corre cada fotograma y un bp
# ahi ahoga al emulador. Los volcados van por reloj emulado, y como el juego
# redibuja y avanza la posicion en el mismo golpe, la VRAM de cualquier
# instante es el dibujo de la posicion que se lee a la vez.
#
# Variables de entorno:
#   SJ_SALIDA  carpeta de salida (por defecto work/omsx)
#
#   "C:/Program Files/openMSX/openmsx.exe" -machine Philips_VG_8020 \
#       -cart skyjaguar.rom -script tools/omsx_vram.tcl

proc opcion {nombre porDefecto} {
    global env
    if {[info exists env($nombre)]} { return $env($nombre) }
    return $porDefecto
}

set ::SALIDA [opcion SJ_SALIDA {C:/Users/Antxiko/Documents/DES_ASM/SKYJAGUAR_DISAM/work/omsx}]
file mkdir $::SALIDA
set ::n 0

proc vuelca {etiqueta} {
    set i [format %02d $::n]
    incr ::n
    # los 16 KB de VRAM tal cual los ve el VDP
    set datos [debug read_block VRAM 0 16384]
    set f [open $::SALIDA/vram_$i.bin w]
    fconfigure $f -translation binary
    puts -nonewline $f $datos
    close $f
    # los ocho registros, que dicen donde esta cada tabla
    set r {}
    for {set k 0} {$k < 8} {incr k} {
        lappend r [format %02X [debug read {VDP regs} $k]]
    }
    set f [open $::SALIDA/info_$i.txt w]
    puts $f [format {etiqueta %s} $etiqueta]
    puts $f [format {tiempo %s} [machine_info time]]
    puts $f [format {regs %s} [join $r { }]]
    foreach {nombre dir} {estado 0xE000 subestado 0xE001 bits 0xE002
                          fase_en_marcha 0xE053 vidas 0xE050 escena 0xE051
                          episodio_gigante 0xE140 cual_gigante 0xE1D6
                          pos_baja 0xE1B8 pos_alta 0xE1B9 fino 0xE1BA
                          indice_mapa 0xE1D1} {
        puts $f [format {%s %d} $nombre [debug read memory $dir]]
    }
    close $f
    catch { screenshot -raw $::SALIDA/pant_$i.png }
}

# --- la barra de espacio, para pasar del titulo a la partida --------------
proc pulsa {} {
    keymatrixdown 8 0x01
    after time 0.4 suelta
}
proc suelta {} {
    keymatrixup 8 0x01
}

# --- calendario ------------------------------------------------------------
# Primero el titulo y la demo (el juego se juega solo: 0x449E se inventa los
# mandos cuando el bit 6 de 0xE002 esta a cero), luego una partida de verdad.
after time  6.0 { vuelca titulo }
after time 12.0 { vuelca titulo_o_demo }
after time 20.0 { vuelca demo }
after time 28.0 { vuelca demo }
after time 34.0 { pulsa }
after time 36.0 { pulsa }
after time 44.0 { vuelca partida }
after time 54.0 { vuelca partida }
after time 64.0 { vuelca partida }
after time 74.0 { vuelca partida }
after time 84.0 { vuelca partida }
after time 94.0 { vuelca partida }
after time 96.0 { exit }

# perro guardian de tiempo REAL: un guion roto no puede colgar el emulador
after realtime 300 {
    puts {PERRO GUARDIAN a los 300 s reales}
    exit
}
