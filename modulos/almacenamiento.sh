#! /bin/bash


#SCRIPT PARA MANEJO Y ADMININSTRACION DE ALMACENAMIENTO

#FUNCION PARA VER LOS DISCOS Y PARTICIONES
#===========================================================================================================================================================
ver_discos_particiones() {

echo "Discos y particiones: "

if command -v lsblk &> /dev/null; then
        lsblk
    else
        echo "El comando 'lsblk' no está disponible."
fi

}
#===========================================================================================================================================================

#FUNCION PARA VER PUNTOS DE MONTARJE
#===========================================================================================================================================================
ver_puntos_montaje() {

echo "Puntos de montaje y sistemas de archivos: "
df -hT

}
#===========================================================================================================================================================

#FUNCION PARA VER EL UUID
ver_uuid() {

echo "UUID de particiones: "

if command -v blkid &> /dev/null; then
        blkid
    else
        echo "El comando 'blkid' no está disponible (puede requerir sudo)."
fi

}
#===========================================================================================================================================================

#FUNCION PARA VER EL ESPACIO DISPONIBLE
#===========================================================================================================================================================
ver_espacio_disco() {

echo "Espacio en disco (total, usado, disponible): "
df -h

}
#===========================================================================================================================================================

#FUNCION PARA VER LAS CARPETAS CON TAMAÑO MAS GRANDE
#===========================================================================================================================================================
tamano_carpetas_grandes() {

local ruta
read -rp "Ruta a analizar: " ruta

#VALIDACION CARPETA EXISTENTE
if [[ ! -d "$ruta" ]]; then
        echo "ERROR: LA CARPETA NO EXISTE"
        return 1
fi

echo "Carpetas que más espacio consumen en '$ruta': "
du -h "$ruta" 2>/dev/null | sort -rh | head -10

}
#===========================================================================================================================================================

#FUNCION DE ALERTA SI EL DISCO ESTA POR LLENARSE
#===========================================================================================================================================================
verificar_umbral_disco() {

echo "Verificación de uso de disco (umbral: ${UMBRAL_DISCO}%): "

#Extraemos el porcentaje de uso de la partición raíz '/'

local uso_actual
uso_actual="$(df -h / | awk 'NR==2 {print $5}' | tr -d '%')"

echo "Uso actual de '/': ${uso_actual}%"

if [[ "$uso_actual" -ge "$UMBRAL_DISCO" ]]; then
        echo "ALERTA: el uso de disco supero el umbral de ${UMBRAL_DISCO}%"
        registrar_bitacora "ALERTA: uso de disco al ${uso_actual}% (umbral: ${UMBRAL_DISCO}%)"
    else
        echo "Uso de disco dentro de parametros normales"
fi

}
#===========================================================================================================================================================

#FUNCION PARA MOSTRAR UN INFORME
#===========================================================================================================================================================
generar_reporte_almacenamiento() {

local nombre_reporte
nombre_reporte="$RUTA_REPORTES/reporte_almacenamiento_$(date +%Y-%m-%d_%H%M).txt"

    {
        echo "REPORTE DE ALMACENAMIENTO"
        echo "Organización: $NOMBRE_ORGANIZACION"
        echo "Fecha: $(date '+%d/%m/%Y %H:%M:%S')"
        echo "Generado por: $(whoami)"
        echo "----------------------------------------"
        df -h
        echo ""
        echo "Memoria RAM y Swap:"
        free -h
    } > "$nombre_reporte"

    echo "Reporte generado: $nombre_reporte"
    registrar_bitacora "Se genero reporte de almacenamiento: $nombre_reporte"
}
#===========================================================================================================================================================

#FUNCION QUE MUESTRA ESTADO DE LA MEMORIA
#===========================================================================================================================================================
ver_memoria() {

echo "Memoria RAM y Swap: "

free -h

}
#===========================================================================================================================================================

#MENU ALMACENAMIENTO
#===========================================================================================================================================================
menu_almacenamiento() {
    local opcion
    while true; do
        clear
        echo "============================================"
        echo " GESTIÓN DE ALMACENAMIENTO"
        echo "============================================"
        echo "1) Ver discos y particiones"
        echo "2) Ver puntos de montaje"
        echo "3) Ver UUID de particiones"
        echo "4) Ver espacio en disco"
        echo "5) Ver carpetas de mayor tamaño"
        echo "6) Verificar umbral de uso de disco"
        echo "7) Generar reporte de almacenamiento"
        echo "8) Ver memoria RAM y Swap"
        echo "0) Volver al menú principal"
        echo "============================================"
        read -rp "Opción: " opcion

        case "$opcion" in
            1) ver_discos_particiones ;;
            2) ver_puntos_montaje ;;
            3) ver_uuid ;;
            4) ver_espacio_disco ;;
            5) tamano_carpetas_grandes ;;
            6) verificar_umbral_disco ;;
            7) generar_reporte_almacenamiento ;;
            8) ver_memoria ;;
            0) return ;;
            *) echo "Opción inválida." ;;
        esac
        pausar
    done
}
