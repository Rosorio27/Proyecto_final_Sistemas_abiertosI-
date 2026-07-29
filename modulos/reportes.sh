#! /bin/bash

#SCRIPT PARA MANEJO Y MANIPULACION DE REPORTES

#FUNCION DE EMCABEZADO PARA REPOSTES
#==============================================================================================================================
encabezado_reporte() {

local tipo="$1"
echo "REPORTE DE $tipo"
echo "Organización: $NOMBRE_ORGANIZACION"
echo "Fecha: $(date '+%d/%m/%Y')"
echo "Hora: $(date '+%H:%M:%S')"
echo "Generado por: $(whoami)"
echo "----------------------------------------"

}
#==============================================================================================================================

#FUNCION DE REPORTE DE USUARIO
#==============================================================================================================================
reporte_usuarios() {

local archivo="$RUTA_REPORTES/reporte_usuarios_$(date +%Y-%m-%d_%H%M).txt"
{
   encabezado_reporte "USUARIOS"
   listar_usuarios
} > "$archivo"

echo "Reporte generado: $archivo"
registrar_bitacora "Se genero reporte de usuarios: $archivo"

}
#==============================================================================================================================

#FUNCION REPORTES POR GRUPO
#==============================================================================================================================
reporte_grupos() {
local archivo="$RUTA_REPORTES/reporte_grupos_$(date +%Y-%m-%d_%H%M).txt"
{
  encabezado_reporte "GRUPOS"
  ver_grupos
} > "$archivo"

echo "Reporte generado: $archivo"
registrar_bitacora "Se genero reporte de grupos: $archivo"

}
#==============================================================================================================================

#FUNCION REPORTES POR PERMISOS
#==============================================================================================================================
reporte_permisos() {

local ruta
read -rp "Ruta a incluir en el reporte de permisos: " ruta

#VALIDACION CARPETA EXISTENTE
if [[ ! -e "$ruta" ]]; then
        echo "ERROR: LA RUTA NO EXISTE"
        return 1
fi

local archivo="$RUTA_REPORTES/reporte_permisos_$(date +%Y-%m-%d_%H%M).txt"
{
   encabezado_reporte "PERMISOS"
   echo "Ruta analizada: $ruta"
   ls -ld "$ruta"
   echo ""
   stat "$ruta"
} > "$archivo"
    echo "Reporte generado: $archivo"
    registrar_bitacora "Se genero reporte de permisos: $archivo"
}
#==============================================================================================================================

#FUNCION REPORTES POR ARCHIVOS Y CARPETAS
#==============================================================================================================================
reporte_archivos_carpetas() {

local ruta
read -rp "Ruta a incluir en el reporte: " ruta

#VALIDACION CARPETA EXISTE
if [[ ! -d "$ruta" ]]; then
        echo "ERROR: LA CARPETA NO EXISTE"
        return 1
fi

local archivo="$RUTA_REPORTES/reporte_archivos_$(date +%Y-%m-%d_%H%M).txt"
{
   encabezado_reporte "ARCHIVOS Y CARPETAS"
   echo "Ruta analizada: $ruta"
   echo ""
   if command -v tree &> /dev/null; then
        tree "$ruta"
      else
        ls -laR "$ruta"
   fi
} > "$archivo"

echo "Reporte generado: $archivo"
registrar_bitacora "Se genero reporte de archivos/carpetas: $archivo"

}
#==============================================================================================================================

#FUNCION REPORTE POR PROCESOS
#==============================================================================================================================
reporte_procesos() {

local archivo="$RUTA_REPORTES/reporte_procesos_$(date +%Y-%m-%d_%H%M).txt"
{
   encabezado_reporte "PROCESOS"
   ps aux --sort=-%cpu | head -20
} > "$archivo"

echo "Reporte generado: $archivo"
registrar_bitacora "Se genero reporte de procesos: $archivo"

}
#==============================================================================================================================

#FUNCION REPORTE RESPALDOS
#==============================================================================================================================
reporte_respaldos() {

local archivo="$RUTA_REPORTES/reporte_respaldos_$(date +%Y-%m-%d_%H%M).txt"
{
   encabezado_reporte "RESPALDOS"
   listar_respaldos
} > "$archivo"

echo "Reporte generado: $archivo"
registrar_bitacora "Se genero reporte de respaldos: $archivo"

}
#==============================================================================================================================

#FUNCION REPORTE GENERAL
#==============================================================================================================================
reporte_general() {

local archivo="$RUTA_REPORTES/reporte_general_$(date +%Y-%m-%d_%H%M).txt"
{
   encabezado_reporte "GENERAL DEL SISTEMA"
   echo "Usuarios: "
   listar_usuarios
   echo ""
   echo "Grupos: "
   ver_grupos
   echo ""
   echo "Almacenamiento: "
   df -h
   echo ""
   echo "Procesos (top 10): "
   ps aux --sort=-%cpu | head -10
   echo ""
   echo "Respaldos: "
   listar_respaldos
 } > "$archivo"

echo "Reporte general generado: $archivo"
registrar_bitacora "Se genero reporte general del sistema: $archivo"

}
#==============================================================================================================================

#MENU REPORTES
#==============================================================================================================================
menu_reportes() {
    local opcion
    while true; do
        clear
        echo "============================================"
        echo " GENERACIÓN DE REPORTES"
        echo "============================================"
        echo "1) Reporte de usuarios"
        echo "2) Reporte de grupos"
        echo "3) Reporte de permisos"
        echo "4) Reporte de archivos/carpetas"
        echo "5) Reporte de procesos"
        echo "6) Reporte de almacenamiento"
        echo "7) Reporte de respaldos"
        echo "8) Reporte general del sistema"
        echo "0) Volver al menú principal"
        echo "============================================"
        read -rp "Opción: " opcion

        case "$opcion" in
            1) reporte_usuarios ;;
            2) reporte_grupos ;;
            3) reporte_permisos ;;
            4) reporte_archivos_carpetas ;;
            5) reporte_procesos ;;
            6) generar_reporte_almacenamiento ;;
            7) reporte_respaldos ;;
            8) reporte_general ;;
            0) return ;;
            *) echo "Opción inválida." ;;
        esac
        pausar
    done
}
#==============================================================================================================================
