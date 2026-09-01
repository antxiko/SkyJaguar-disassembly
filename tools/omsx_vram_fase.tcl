# omsx_vram_fase.tcl - Recorre la fase de Sky Jaguar y vuelca su VRAM.
#
# Para que sirve: omsx_vram.tcl solo llega a las primeras filas, porque el
# avion muere antes. Aqui se ESCRIBE la posicion en 0xE1B8/B9 y se deja que el
# cartucho redibuje con ella, de modo que se puede comprobar el fondo en
# cualquier punto de las 1920 filas, incluidas las dos del enemigo grande.
#
# Como se escribe la posicion: PASO_DE_FONDO (0x5837) hace inc de ANTES de
# dibujar, asi que para ver la fila P se deja P-1 en 0xE1B8/B9 y el
# desplazamiento fino de 0xE1BA en 2*((P-1) y 7), que es el que le toca; el
# propio 0x5875 le suma 2 y lo envuelve a 16, con lo que queda 2*(P y 7).
# DESPUES se comprueba que 0xE1B8/B9 valen ya P: si no, es que el cartucho no
# ha redibujado y ese volcado no valdria.
#
# Que hay que sujetar CADA FOTOGRAMA para que el fondo se redibuje:
#   0xE000/0xE001 = 2/1   el estado que llama PASO_DE_FASE (0x411F)
#   0xE053 = 1            la fase en marcha
#   0xE050 = 9            vidas, que no se corte
#   0xE1DC = 0            la cuenta atras de PASO_DE_FASE (0x4537)
#   0xE01A != 0x93        con ese valor FOTOGRAMA (0x4540) se salta entero
#   0xE051 = 1, 0xE1D3 = 0    saltar filas dispara SUBE_ESCENA (0x584D)
#   0xE140 = 0            con (0xE140 y 3) == 2 PASO_DE_FONDO hace ret (0x583E):
#                         mientras el enemigo grande esta en pantalla el fondo
#                         se CONGELA, y por eso hay que soltarlo a mano
#
# Y aun asi el juego se escapa a veces a la pantalla de titulo, donde
# ESTADO_0_SUB_3 (0x4108) borra la tabla de nombres y CARGA_FUENTE (0x4B97)
# vuelve a pisar los caracteres 0x40-0x59, que la fuente y el paisaje
# COMPARTEN. Por eso antes de cada volcado se mira si la VRAM esta sana y, si
# no lo esta, se manda al cartucho a montar la escena otra vez (estado 2
# subestado 0, que es BORRA_NOMBRES + ARRANCA_ESCENA).
#
# Los dos enemigos grandes NO se alcanzan de un salto: sus caracteres los carga
# CARGA_GIGANTE (0x6D96) y para eso 0xE140 tiene que pasar por 1, cosa que solo
# hace EPISODIO_GIGANTE (0x7766) cuando el indice del mapa vale 0x47 o 0xE7.
# Asi que a esos dos tramos se llega avanzando de UNA fila en una sin tocar
# 0xE140, y solo cuando 0xE1D9 vale 2 -o sea con los caracteres ya dentro- se
# suelta el fondo y se vuelca.
#
# No hay ningun punto de ruptura: el fondo se redibuja una vez cada 16
# fotogramas y un bp ahi ahoga al emulador. Todo va por reloj emulado, y hay
# perro guardian de tiempo real.
#
#   "C:/Program Files/openMSX/openmsx.exe" -machine Philips_VG_8020 \
#       -cart skyjaguar.rom -script tools/omsx_vram_fase.tcl

proc opcion {nombre porDefecto} {
    global env
    if {[info exists env($nombre)]} { return $env($nombre) }
    return $porDefecto
}

set ::SALIDA [opcion SJ_SALIDA {C:/Users/Antxiko/Documents/DES_ASM/SKYJAGUAR_DISAM/work/fase}]
file mkdir $::SALIDA
set ::n 0
set ::cola {}
set ::suelta_gigante 1
set ::pausa 0
set ::intentos 0
set ::diario {}

proc apunta {t} {
    lappend ::diario [format {%9.3f s  %s} [machine_info time] $t]
    set f [open $::SALIDA/diario.txt w]
    foreach l $::diario { puts $f $l }
    close $f
}

proc vuelca {etiqueta} {
    set i [format %03d $::n]
    incr ::n
    set datos [debug read_block VRAM 0 16384]
    set f [open $::SALIDA/vram_$i.bin w]
    fconfigure $f -translation binary
    puts -nonewline $f $datos
    close $f
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
                          cargado_gigante 0xE1D9
                          pos_baja 0xE1B8 pos_alta 0xE1B9 fino 0xE1BA
                          indice_mapa 0xE1D1} {
        puts $f [format {%s %d} $nombre [debug read memory $dir]]
    }
    close $f
    catch { screenshot -raw $::SALIDA/pant_$i.png }
    apunta [format {volcado %s (%s)} $i $etiqueta]
}

proc lee_pos {} {
    return [expr {[debug read memory 0xE1B8] | ([debug read memory 0xE1B9] << 8)}]
}

# Las dos senales de que la VRAM sirve: la tabla de nombres no esta a cero, y
# el color del caracter 0x40 no es el 0xF0 que RELLENA_TRES le deja a la
# fuente (el paisaje le pone el suyo).
proc vram_sana {} {
    if {[debug read VRAM 0x0200] == 0xF0} { return 0 }
    set d [debug read_block VRAM 0x3800 768]
    binary scan $d cu* v
    foreach x $v { if {$x != 0} { return 1 } }
    return 0
}

proc sujeta {} {
    debug write memory 0xE000 2      ;# el estado que llama PASO_DE_FASE
    debug write memory 0xE001 1
    debug write memory 0xE053 1      ;# la fase en marcha
    debug write memory 0xE050 9      ;# vidas de sobra
    debug write memory 0xE1DC 0      ;# sin cuenta atras
    debug write memory 0xE01A 0      ;# 0x93 se salta el fotograma entero
    debug write memory 0xE051 1      ;# escena fija: saltar filas dispara
    debug write memory 0xE1D3 0      ;# SUBE_ESCENA (0x584D)
    if {$::suelta_gigante} { debug write memory 0xE140 0 }
}

proc vigila {} {
    if {!$::pausa} { sujeta }
    after frame vigila
}

proc pon_posicion {p} {
    set q [expr {($p - 1) & 0x7FF}]
    debug write memory 0xE1B8 [expr {$q & 0xFF}]
    debug write memory 0xE1B9 [expr {($q >> 8) & 0xFF}]
    debug write memory 0xE1BA [expr {2 * ($q & 7)}]
}

# --- la cola de ordenes ---------------------------------------------------
#   {P etiqueta}  ir a la fila P (etiqueta vacia = avanzar sin volcar)
#   {reinicia}    olvidar el enemigo grande y dejar de soltar el fondo
proc encola {p etiqueta} { lappend ::cola [list $p $etiqueta] }
proc encola_reinicio {} { lappend ::cola {reinicia {}} }

proc paso {} {
    while {[llength $::cola] && [lindex [lindex $::cola 0] 0] eq {reinicia}} {
        set ::cola [lrange $::cola 1 end]
        set ::suelta_gigante 0
        debug write memory 0xE140 0
        debug write memory 0xE1D9 0
        apunta {reinicio del enemigo grande}
    }
    if {[llength $::cola] == 0} {
        apunta {cola vacia: fin}
        exit
    }
    set orden [lindex $::cola 0]
    set ::cola [lrange $::cola 1 end]
    set ::pos_actual [lindex $orden 0]
    set ::etiqueta_actual [lindex $orden 1]
    set ::intentos 0
    sujeta
    pon_posicion $::pos_actual
    # 0.40 s emulados son 24 fotogramas: cabe de sobra un redibujado entero
    after time 0.40 remata
}

# Cuando la VRAM no sirve, se manda al cartucho a montar la escena de nuevo:
# el subestado 0 del estado 2 es BORRA_NOMBRES + ARRANCA_ESCENA (0x412B), que
# vuelve a pintar el panel y a cargar el paisaje encima de la fuente.
proc remonta_escena {} {
    set ::pausa 1
    debug write memory 0xE000 2
    debug write memory 0xE001 0
    debug write memory 0xE053 1
    debug write memory 0xE050 9
    debug write memory 0xE002 [expr {[debug read memory 0xE002] | 0x40}]
    apunta {remontando la escena}
    after time 0.8 {
        set ::pausa 0
        sujeta
        pon_posicion $::pos_actual
        after time 0.40 remata
    }
}

proc remata {} {
    # los caracteres del enemigo grande ya dentro: a partir de aqui se suelta
    # el fondo, que EPISODIO_GIGANTE tenia congelado
    if {[debug read memory 0xE1D9] == 2} { set ::suelta_gigante 1 }
    set sana [vram_sana]
    if {[lee_pos] == $::pos_actual && $sana} {
        if {$::etiqueta_actual ne {}} { vuelca $::etiqueta_actual }
        paso
        return
    }
    incr ::intentos
    if {$::intentos > 12} {
        apunta [format {ABANDONO la fila %d (%s): pos=%d sana=%d} \
                $::pos_actual $::etiqueta_actual [lee_pos] $sana]
        paso
        return
    }
    if {!$sana} {
        remonta_escena
    } else {
        sujeta
        after time 0.40 remata
    }
}

# --- arranque: pulsar la barra hasta que la fase este en marcha -----------
proc arranca {} {
    if {[debug read memory 0xE053] == 1} {
        apunta {fase en marcha: empieza el recorrido}
        prepara
        return
    }
    if {[machine_info time] > 90.0} {
        apunta {FALLO: 90 s emulados sin arrancar la fase}
        exit
    }
    keymatrixdown 8 0x01
    after time 0.3 {
        keymatrixup 8 0x01
        after time 0.7 arranca
    }
}

proc prepara {} {
    vigila
    # doce calas repartidas por las 1920 filas, de un salto cada una
    foreach p {50 100 300 500 700 900 1100 1300 1500 1700 1900 1919} {
        encola $p [format {cala_%04d} $p]
    }
    # el enemigo grande 1: 0xE140 pasa por 1 en el indice 0x47 (fila 568), asi
    # que hay que llegar fila a fila y sin soltar el fondo
    encola 540 {}
    encola_reinicio
    for {set p 541} {$p <= 600} {incr p} {
        if {$p == 580 || $p == 584 || $p == 588 || $p == 592} {
            encola $p [format {gigante1_%04d} $p]
        } else {
            encola $p {}
        }
    }
    # y el 2, que arranca en el indice 0xE7 (fila 1848)
    encola 1820 {}
    encola_reinicio
    for {set p 1821} {$p <= 1880} {incr p} {
        if {$p == 1860 || $p == 1864 || $p == 1868 || $p == 1872} {
            encola $p [format {gigante2_%04d} $p]
        } else {
            encola $p {}
        }
    }
    paso
}

set throttle off
after time 8.0 arranca

# perro guardian de tiempo REAL: un guion roto no puede colgar el emulador
after realtime 420 {
    apunta {PERRO GUARDIAN a los 420 s reales}
    exit
}
