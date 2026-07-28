#! /bin/bash

#SCRIPT PARA REGISTRO Y ADMINISTRACION DE LOS PROCESO

#FUNCION PARA MOSTRAR 20 PROCESOS ACTIVOS
#===========================================================================================================================================================
listar_procesos() {
    echo  "Procesos activos: "
    ps aux | head -20
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

#VALIDACION DE DATO CORRRECTO
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
echo "Procesos del usuario actual ($(whoami)): "
ps -u "$(whoami)"

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
#VALIDACION USUARIO ROOT
if ! requiere_root; then
        return 1
fi

local pid
read -rp "PID a finalizar: " pid

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

#CONFIRAMAR ANTES DE ELIMINAR
if ! confirmar_accion "¿Está seguro que desea finalizar el proceso '$nombre_proceso' (PID $pid)?"; then
        return 1
fi

#ELIMINADO PROCESO
if kill "$pid" &> /dev/null; then
        echo "Proceso finalizado exitosamente"
        registrar_bitacora "Se finalizo el proceso PID $pid ($nombre_proceso)"
        return 0
    else
        echo "ERROR: NO SE PUDO FINALIZAR EL PROCESO"
        return 1
fi

}
#===========================================================================================================================================================

#FINALIZAR PROCESO POR MEDIO DE NOMBRE
#===========================================================================================================================================================
finalizar_proceso_nombre() {
#VALIDACION DE USUARIO ROOT
if ! requiere_root; then
        return 1
fi

local nombre
read -rp "Nombre del proceso a finalizar: " nombre

#VALIDAR CAMPO VACIO
if [[ -z "$nombre" ]]; then
        echo "ERROR: EL NOMBRE NO PUEDE QUEDAR VACIO"
        return 1
fi

#VALIDACION NOMBRE DEL PROCESO
if ! pgrep -x "$nombre" &> /dev/null; then
        echo "ERROR: NO EXISTE UN PROCESO CON ESE NOMBRE"
        return 1
fi

#CONFIRMAR ANTES DE ELIMINAR
if ! confirmar_accion "¿Está seguro que desea finalizar todos los procesos '$nombre'?"; then
        return 1
fi

#MOSTRAR LOS DATOS
if pkill -x "$nombre" &> /dev/null; then
        echo "Proceso(s) finalizado(s) exitosamente"
        registrar_bitacora "Se finalizaron procesos con nombre '$nombre'"
        return 0
    else
        echo "ERROR: NO SE PUDO FINALIZAR"
        return 1
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
