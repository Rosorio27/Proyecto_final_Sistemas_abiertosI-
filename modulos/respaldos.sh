#! /bin/bash

#SCRIPT MANEJO Y ADMINISTRACON DE RESPALDOS

#FUNCION PARA CREAR UN RESPALDO
#===========================================================================================================================================================
crear_respaldo() {

local ruta_origen

read -rp "Ruta de la carpeta a respaldar: " ruta_origen

#VALIDACION DE CAMPO VACIO
if [[ -z "$ruta_origen" ]]; then
        echo "ERROR: LA RUTA NO PUEDE QUEDAR VACIA"
        return 1
fi

#VALIDACION DE CARPETA SI EXISTE
if [[ ! -d "$ruta_origen" ]]; then
        echo "ERROR: LA CARPETA DE ORIGEN NO EXISTE"
        return 1
fi

local nombre_carpeta
nombre_carpeta="$(basename "$ruta_origen")"
local nombre_respaldo="$RUTA_RESPALDOS/respaldo_${nombre_carpeta}_$(date +%Y-%m-%d_%H%M).tar.gz"

#COMPRIMIR Y EMPAQUETAR CON TAR
if tar -czf "$nombre_respaldo" "$ruta_origen" 2>/dev/null; then
        echo "Respaldo creado exitosamente: $nombre_respaldo"
        registrar_bitacora "Se creo respaldo de '$ruta_origen' -> $nombre_respaldo"
        return 0
    else
        echo "ERROR: NO SE PUDO CREAR EL RESPALDO"
        return 1
fi

}
#===========================================================================================================================================================

#FUNCION PARA CONTAR EL NUMERO DE RESPALDOS
#===========================================================================================================================================================
listar_respaldos() {

echo "--- Respaldos disponibles ---"

local cantidad
cantidad="$(ls "$RUTA_RESPALDOS" 2>/dev/null | wc -l)"

#VALIDACION CARPETA DE RESPALDO
if [[ "$cantidad" -eq 0 ]]; then
        echo "  (No hay respaldos disponibles)"
    else
        ls -lh "$RUTA_RESPALDOS"
fi

}
#===========================================================================================================================================================

#FUNCION PARA RESTAURARN UN RESPALDO
#===========================================================================================================================================================
restaurar_respaldo() {

local nombre_archivo
read -rp "Nombre del archivo de respaldo (ej. respaldo_x_2026-07-26_1200.tar.gz): " nombre_archivo

local ruta_completa="$RUTA_RESPALDOS/$nombre_archivo"

#VALIDACION DE CAMPO VACIO
if [[ -z "$nombre_archivo" ]]; then
        echo "ERROR: EL NOMBRE NO PUEDE QUEDAR VACIO"
        return 1
fi

#VALIDACION DE ARCHIVO INEXISTENTE
if [[ ! -f "$ruta_completa" ]]; then
        echo "ERROR: EL RESPALDO NO EXISTE"
        return 1
fi

local destino
read -rp "Carpeta donde restaurar: " destino

#VALIDACION SI LA CARPETA DESTINO NO EXISTE
if [[ ! -d "$destino" ]]; then
        echo "ERROR: LA CARPETA DE DESTINO NO EXISTE"
        return 1
fi

#CONFIRMAR ANTES DE REALIZAR ACCION
if ! confirmar_accion "¿Está seguro que desea restaurar '$nombre_archivo' en '$destino'?"; then
        return 1
fi

#DESCOMPRIMIR EL ARCHIVO CON ARCHIVOS ORIGINALES
if tar -xzf "$ruta_completa" -C "$destino" 2>/dev/null; then
        echo "Respaldo restaurado exitosamente"
        registrar_bitacora "Se restauro el respaldo '$nombre_archivo' en '$destino'"
        return 0
    else
        echo "ERROR: NO SE PUDO RESTAURAR"
        return 1
fi

}
#===========================================================================================================================================================

#FUNCION PARA ELIMINAR ARCHIVOS VIEJOS
#===========================================================================================================================================================
eliminar_respaldos_antiguos() {
#VALIDACION DE USUARIO ROOT
if ! requiere_root; then
        return 1
fi

local dias
read -rp "Eliminar respaldos con más de cuántos días de antigüedad: " dias

#VALIDACION DE NUMERO VALIDO
if [[ ! "$dias" =~ ^[0-9]+$ ]]; then
        echo "ERROR: DEBE INGRESAR UN NUMERO VALIDO"
        return 1
fi

local antiguos
antiguos="$(find "$RUTA_RESPALDOS" -name "*.tar.gz" -mtime +"$dias" 2>/dev/null)"

#VALIDACION DE DIAS ATRAS PARA RESPALDOS
if [[ -z "$antiguos" ]]; then
        echo "No hay respaldos con más de $dias días de antigüedad"
        return 0
fi

echo "Se eliminarán los siguientes respaldos:"
echo "$antiguos"

#VALIDACION ANTES DE APLICAR CAMBIOS
if ! confirmar_accion "¿Confirma la eliminación?"; then
        return 1
fi

find "$RUTA_RESPALDOS" -name "*.tar.gz" -mtime +"$dias" -delete
echo "Respaldos antiguos eliminados"
registrar_bitacora "Se eliminaron respaldos con mas de $dias dias de antiguedad"

}
#===========================================================================================================================================================

#FUNCION PARA LIMPIAR CARPETA DE TEMPORALES
#===========================================================================================================================================================
limpiar_temporales() {

local cantidad
cantidad="$(ls "$RUTA_TEMPORALES" 2>/dev/null | wc -l)"

#VALIDACION SI LA CARPETA ESTA VACIA
if [[ "$cantidad" -eq 0 ]]; then
        echo "La carpeta de temporales ya está vacía"
        return 0
fi

#VALIDACION DE CONFIRMAR ANTES DE ACCION
if ! confirmar_accion "¿Desea eliminar $cantidad archivo(s) temporal(es)?"; then
        return 1
fi

rm -rf "${RUTA_TEMPORALES:?}"/*
echo "Archivos temporales eliminados"
registrar_bitacora "Se limpiaron los archivos temporales"

}
#===========================================================================================================================================================

#FUNCION PARA RESPALDO AUTOMATICO
#===========================================================================================================================================================
respaldo_automatico() {

local nombre_respaldo="$RUTA_RESPALDOS/respaldo_automatico_$(date +%Y-%m-%d_%H%M).tar.gz"
tar -czf "$nombre_respaldo" "$RUTA_DOCUMENTACION" 2>/dev/null
echo "[$(date '+%Y-%m-%d %H:%M:%S')] [cron] Respaldo automatico generado: $nombre_respaldo" >> "$ARCHIVO_BITACORA"

}
#===========================================================================================================================================================

#FUNCION PARA UTILIZANDO CRON
#===========================================================================================================================================================
configurar_tarea_cron() {
#VALIDACION USUARIO ROOT
if ! requiere_root; then
        return 1
fi

echo "Se configurará una tarea automática que respalda"
echo "la carpeta de documentación todos los días a las 2:00 AM."
echo ""

#VALIDACION ANTES DE CONFIRMAR ACCION
if ! confirmar_accion "¿Desea instalar esta tarea programada?"; then
        return 1
fi

local linea_cron="0 2 * * * $RUTA_PRINCIPAL/sistema.sh --respaldo-automatico"

#VALIDACION SI EXISTE TAREA
if crontab -l 2>/dev/null | grep -qF "$RUTA_PRINCIPAL/sistema.sh --respaldo-automatico"; then
        echo "La tarea ya estaba configurada anteriormente"
        return 0
fi

(crontab -l 2>/dev/null; echo "$linea_cron") | crontab -

echo "Tarea cron configurada exitosamente"
echo "Puede verificarla con: crontab -l"
registrar_bitacora "Se configuro tarea cron de respaldo automatico"

}
#==============================================================================================================================

#MENU RESPALDOS
#==============================================================================================================================
menu_respaldos() {
    local opcion
    while true; do
        clear
        echo "============================================"
        echo " RESPALDOS Y RESTAURACIÓN"
        echo "============================================"
        echo "1) Crear respaldo"
        echo "2) Listar respaldos"
        echo "3) Restaurar respaldo"
        echo "4) Eliminar respaldos antiguos"
        echo "5) Limpiar archivos temporales"
        echo "6) Configurar tarea automática (cron)"
        echo "0) Volver al menú principal"
        echo "============================================"
        read -rp "Opción: " opcion

        case "$opcion" in
            1) crear_respaldo ;;
            2) listar_respaldos ;;
            3) restaurar_respaldo ;;
            4) eliminar_respaldos_antiguos ;;
            5) limpiar_temporales ;;
            6) configurar_tarea_cron ;;
            0) return ;;
            *) echo "Opción inválida." ;;
        esac
        pausar
    done
}
#==============================================================================================================================
