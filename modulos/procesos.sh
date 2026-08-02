#! /bin/bash

#SCRIPT PARA REGISTRO Y ADMINISTRACION DE LOS PROCESO

#FUNCION PARA MOSTRAR 20 PROCESOS ACTIVOS
#===========================================================================================================================================================
listar_procesos() {

    local total
    total="$(ps aux | wc -l)"

echo "Procesos activos (mostrando 20 de $total totales): "

ps aux | head -20

    if [[ "$total" -gt 20 ]]; then
        if confirmar_accion "¿Desea ver la lista completa?"; then
            echo ""
            echo "--- Lista completa ---"
            ps aux
        fi
    fi

}
#===========================================================================================================================================================

#FUNCION PARA BUSQUEDA DE PROCESO POR NOMBRE
#===========================================================================================================================================================
buscar_proceso_nombre() {

local nombre
read -rp "Nombre del proceso a buscar: " nombre

#VALIDACION CAMPO VACIO
if [[ -z "$nombre" ]]; then
        echo "ERROR: EL NOMBRE NO PUEDE QUEDAR VACIO"
        return 1
fi

echo "Resultados para '$nombre': "

local resultado
resultado="$(ps aux | grep -i "$nombre" | grep -v grep)"

#NUESTRA EL PROCESO
if [[ -z "$resultado" ]]; then
        echo "  (No se encontraron procesos con ese nombre)"
    else
        echo "$resultado"
fi

}
#===========================================================================================================================================================

#FUNCION PARA BUSQUEDA DE PROCESO POR PID
#===========================================================================================================================================================
buscar_proceso_pid() {

local pid
read -rp "PID a buscar: " pid

#VALIDACION DE CAMPO VACIO
if [[ -z "$pid" ]]; then
        echo "ERROR: EL PID NO PUEDE QUEDAR VACIO"
        return 1
fi

#VALIDACION DE DATO CORRECTO
if [[ ! "$pid" =~ ^[0-9]+$ ]]; then
        echo "ERROR: EL PID DEBE SER NUMERICO"
        return 1
fi

#VALIDACION NUMERO DE PID
if ! ps -p "$pid" &> /dev/null; then
        echo "ERROR: NO EXISTE UN PROCESO CON ESE PID"
        return 1
fi

echo "Información del PID $pid: "
ps -p "$pid" -o pid,ppid,user,%cpu,%mem,cmd

}
#===========================================================================================================================================================

#FUNCION PARA VER PROCESOS DEL USUARIO ACTUAL
#===========================================================================================================================================================
procesos_usuario_actual() {

local usuario
usuario="$(whoami)"
local total
total="$(pgrep -u "$usuario" | wc -l)"

echo "Procesos del usuario actual ($usuario): "
echo "Total de tareas activas: $total"
echo ""
ps -u "$usuario"

}
#===========================================================================================================================================================

#FUNCION PARA VER LOS PROCESOS DE MAYOR CONSUMO
#===========================================================================================================================================================
mayor_consumo() {

echo "Top 5 procesos por consumo de CPU: "
ps aux --sort=-%cpu | head -6

echo ""
echo "--- Top 5 procesos por consumo de memoria ---"
ps aux --sort=-%mem | head -6

}
#===========================================================================================================================================================

#FUNCION PARA FINALIZAR RROCESOS
#===========================================================================================================================================================
finalizar_proceso_pid() {

if ! requiere_root; then
        return 1
fi
local pid
read -rp "PID a finalizar: " pid

#VALIDACION DE CAMPO VACIO
if [[ -z "$pid" ]]; then
        echo "ERROR: EL PID NO PUEDE QUEDAR VACIO"
        return 1
fi

#VALIDACION DATO CORRECTO
if [[ ! "$pid" =~ ^[0-9]+$ ]]; then
        echo "ERROR: EL PID DEBE SER NUMERICO"
        return 1
fi

#VALIDACION DE PROCESO POR PID
if ! ps -p "$pid" &> /dev/null; then
        echo "ERROR: NO EXISTE UN PROCESO CON ESE PID"
        return 1
fi

#PROTECCIÓN: no permitir matar procesos críticos (PID 1 = init/systemd)
if [[ "$pid" -eq 1 ]]; then
        echo "ERROR: NO SE PUEDE FINALIZAR EL PROCESO PRINCIPAL DEL SISTEMA (PID 1)"
        return 1
fi

local nombre_proceso
nombre_proceso="$(ps -p "$pid" -o comm=)"

#CONFIRMAR ANTES DE ELIMINAR
if ! confirmar_accion "¿Está seguro que desea finalizar el proceso '$nombre_proceso' (PID $pid)?"; then
        return 1
fi

#INTENTO SUAVE (SIGTERM) - le pide al proceso que cierre por si mismo
kill "$pid" &> /dev/null
sleep 2

#VERIFICAR SI REALMENTE TERMINO
if ! ps -p "$pid" &> /dev/null; then
        echo "Proceso finalizado exitosamente"
        registrar_bitacora "Se finalizo el proceso PID $pid ($nombre_proceso)"
        return 0
else
        echo "AVISO: el proceso no respondió a la señal normal (SIGTERM)."
        if confirmar_accion "¿Desea forzar su finalización (SIGKILL)?"; then
                if kill -9 "$pid" &> /dev/null; then
                        echo "Proceso finalizado de forma forzada"
                        registrar_bitacora "Se forzo la finalizacion del proceso PID $pid ($nombre_proceso)"
                        return 0
                else
                        echo "ERROR: NO SE PUDO FINALIZAR EL PROCESO NI DE FORMA FORZADA"
                        return 1
                fi
        else
                echo "Operación cancelada. El proceso sigue activo."
                return 1
        fi
fi

}
#===========================================================================================================================================================

#FINALIZAR PROCESO POR MEDIO DE NOMBRE
#===========================================================================================================================================================
finalizar_proceso_nombre() {

if ! requiere_root; then
        return 1
fi
local nombre
read -rp "Nombre del proceso a finalizar: " nombre

if [[ -z "$nombre" ]]; then
        echo "ERROR: EL NOMBRE NO PUEDE QUEDAR VACIO"
        return 1
fi

if ! pgrep -x "$nombre" &> /dev/null; then
        echo "ERROR: NO EXISTE UN PROCESO CON ESE NOMBRE"
        return 1
fi

if ! confirmar_accion "¿Está seguro que desea finalizar todos los procesos '$nombre'?"; then
        return 1
fi

#INTENTO SUAVE (SIGTERM)
pkill -x "$nombre" &> /dev/null
sleep 2

#VERIFICAR SI TODAVIA QUEDAN PROCESOS CON ESE NOMBRE
if ! pgrep -x "$nombre" &> /dev/null; then
        echo "Proceso(s) finalizado(s) exitosamente"
        registrar_bitacora "Se finalizaron procesos con nombre '$nombre'"
        return 0
else
        echo "AVISO: algunos procesos no respondieron a la señal normal (SIGTERM)."
        if confirmar_accion "¿Desea forzar su finalización (SIGKILL)?"; then
                if pkill -9 -x "$nombre" &> /dev/null; then
                        echo "Proceso(s) finalizado(s) de forma forzada"
                        registrar_bitacora "Se forzo la finalizacion de procesos con nombre '$nombre'"
                        return 0
                else
                        echo "ERROR: NO SE PUDO FINALIZAR NI DE FORMA FORZADA"
                        return 1
                fi
        else
                echo "Operación cancelada. Algunos procesos siguen activos."
                return 1
        fi
fi

}
#===========================================================================================================================================================

#FUNCION PARA MONITOR DE PROCESOS
#===========================================================================================================================================================
monitorear_procesos() {

if command -v watch &> /dev/null; then
        echo "Monitoreo en tiempo real (Ctrl+C para salir)..."
        sleep 1
        watch -n 2 'ps aux --sort=-%cpu | head -10'
    else
        echo "El comando 'watch' no está instalado. Mostrando una sola vez:"
        ps aux --sort=-%cpu | head -10
fi

}
#===========================================================================================================================================================

#MENU PROCESOS
#===========================================================================================================================================================
menu_procesos() {
    local opcion
    while true; do
        clear
        echo "============================================"
        echo " GESTIÓN DE PROCESOS"
        echo "============================================"
        echo "1) Listar procesos activos"
        echo "2) Buscar proceso por nombre"
        echo "3) Buscar proceso por PID"
        echo "4) Ver procesos del usuario actual"
        echo "5) Ver procesos de mayor consumo"
        echo "6) Finalizar proceso por PID"
        echo "7) Finalizar proceso por nombre"
        echo "8) Monitorear procesos (tiempo real)"
        echo "0) Volver al menú principal"
        echo "============================================"
        read -rp "Opción: " opcion

        case "$opcion" in
            1) listar_procesos ;;
            2) buscar_proceso_nombre ;;
            3) buscar_proceso_pid ;;
            4) procesos_usuario_actual ;;
            5) mayor_consumo ;;
            6) finalizar_proceso_pid ;;
            7) finalizar_proceso_nombre ;;
            8) monitorear_procesos ;;
            0) return ;;
            *) echo "Opción inválida." ;;
        esac
        pausar
    done
}
