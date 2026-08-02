#! /bin/bash

#SCRIPT DE MANIPULACION Y ADMINISTRACION DE CARPETAS

#FUNCION PARA CREAR CARPETAS
#===========================================================================================================================================================
crear_carpeta() {

local ruta_nueva
read -rp "Ruta de la nueva carpeta: " ruta_nueva

if [[ -z "$ruta_nueva" ]]; then
        echo "ERROR: LA RUTA NO PUEDE QUEDAR VACIA"
        return 1
fi

#VALIDACION: EXIGIR RUTA ABSOLUTA
if [[ "$ruta_nueva" != /* ]]; then
        echo "ERROR: debe ingresar una ruta absoluta (que empiece con /)"
        return 1
fi

if [[ -d "$ruta_nueva" ]]; then
        echo "ERROR: LA CARPETA YA EXISTE"
        return 1
fi

if mkdir -p "$ruta_nueva"; then
        echo "Carpeta creada exitosamente: $ruta_nueva"
        registrar_bitacora "Se creo la carpeta '$ruta_nueva'"
        return 0
    else
        echo "ERROR: NO SE PUDO CREAR LA CARPETA"
        return 1
fi

}
#=========================================================================================================================================================

#FUNCION PARA VER LA RUTA DE LAS CARPETAS
#========================================================================================================================================================
ver_carpeta() {

local ruta
read -rp "Ruta a listar: " ruta

#VALIDAR CAMPO VACIO
if [[ -z "$ruta" ]]; then
        echo "ERROR: LA RUTA NO PUEDE QUEDAR VACIA"
        return 1
fi

#VALIDAR CARPETA EXISTENTE
if [[ ! -d "$ruta" ]]; then
        echo "ERROR: LA CARPETA NO EXISTE"
        return 1
fi

#VALIDAR PERMISOS DE LECTURA Y EJECUCION
if [[ ! -r "$ruta" ]] || [[ ! -x "$ruta" ]]; then
        echo "ERROR: no tiene permisos suficientes (lectura/ejecución) para ver esta carpeta"
        return 1
fi

#MOSTRAR LA RUTA Y DETALLES DE LA CARPETA
    echo "Detalles de '$ruta': "
    if command -v tree &> /dev/null; then
        tree "$ruta"
    else
        ls -lah "$ruta"
    fi

}
#===========================================================================================================================================================

#FUNCION PARA BUSCAR UNA CARPETA
#===========================================================================================================================================================
buscar_carpeta() {

local nombre_buscar
local ruta_base

read -rp "Nombre de carpeta a buscar: " nombre_buscar

if [[ -z "$nombre_buscar" ]]; then
        echo "ERROR: EL NOMBRE NO PUEDE QUEDAR VACIO"
        return 1
fi

read -rp "Ruta donde buscar (Enter para buscar en todo el sistema, más lento): " ruta_base

if [[ -z "$ruta_base" ]]; then
    ruta_base="/"
fi

if [[ ! -d "$ruta_base" ]]; then
    echo "ERROR: LA RUTA BASE NO EXISTE"
    return 1
fi

echo "Buscando '$nombre_buscar' dentro de '$ruta_base'..."
local resultado
resultado="$(find "$ruta_base" -type d -iname "*$nombre_buscar*" 2>/dev/null)"

if [[ -z "$resultado" ]]; then
        echo "  (No se encontraron coincidencias)"
    else
        echo "$resultado"
fi

}
#===========================================================================================================================================================

#FUNCION PARA CAMBIAR NOMBRE DE LA CARPETA
#===========================================================================================================================================================

cambiar_nombre_carpeta() {

local ruta_actual
local ruta_nueva
read -rp "Ruta actual de la carpeta: " ruta_actual

if [[ ! -d "$ruta_actual" ]]; then
        echo "ERROR: LA CARPETA NO EXISTE"
        return 1
fi

read -rp "Nuevo nombre/ruta: " ruta_nueva

if [[ -z "$ruta_nueva" ]]; then
        echo "ERROR: EL NUEVO NOMBRE NO PUEDE QUEDAR VACIO"
        return 1
fi

if [[ -d "$ruta_nueva" ]]; then
        echo "ERROR: YA EXISTE UNA CARPETA CON ESE NOMBRE"
        return 1
fi

#VALIDACION DE PERMISOS DE ESCRITURA EN LA CARPETA PADRE
local carpeta_padre
carpeta_padre="$(dirname "$ruta_actual")"
if [[ ! -w "$carpeta_padre" ]]; then
        echo "ERROR: no tiene permisos de escritura en '$carpeta_padre'"
        return 1
fi

#NUEVO NOMBRE DE LA CARPETA (-n como capa extra de seguridad)
if mv -n "$ruta_actual" "$ruta_nueva"; then
        echo "Carpeta renombrada exitosamente"
        registrar_bitacora "Se renombro '$ruta_actual' a '$ruta_nueva'"
        return 0
    else
        echo "ERROR: NO SE PUDO RENOMBRAR"
        return 1
fi

}
#===========================================================================================================================================================

#FUNCION PARA MOVER UNA CARPETA A OTRA RUTA
#===========================================================================================================================================================
mover_carpeta() {

local origen
local destino
read -rp "Carpeta a mover: " origen

if [[ -z "$origen" ]]; then
        echo "ERROR: LA RUTA DE ORIGEN NO PUEDE QUEDAR VACIA"
        return 1
fi

if [[ ! -d "$origen" ]]; then
        echo "ERROR: LA CARPETA DE ORIGEN NO EXISTE"
        return 1
fi

read -rp "Carpeta de destino: " destino

if [[ -z "$destino" ]]; then
        echo "ERROR: EL DESTINO NO PUEDE QUEDAR VACIO"
        return 1
fi

#SI EL DESTINO NO EXISTE, OFRECER CREARLO
if [[ ! -d "$destino" ]]; then
        if confirmar_accion "El destino '$destino' no existe. ¿Desea crearlo?"; then
                mkdir -p "$destino"
        else
                echo "Operación cancelada."
                return 1
        fi
fi

#MOVER LA CARPETA A OTRA RUTA DESTINO
if mv "$origen" "$destino/"; then
        echo "Carpeta movida exitosamente a '$destino'"
        registrar_bitacora "Se movio '$origen' a '$destino'"
        return 0
    else
        echo "ERROR: NO SE PUDO MOVER"
        return 1
fi

}
#===========================================================================================================================================================

#FUNCION PARA COPIAR UNA CARPETA
#===========================================================================================================================================================
copiar_carpeta() {

local origen
local destino
read -rp "Carpeta de origen: " origen

if [[ -z "$origen" ]]; then
        echo "ERROR: LA RUTA DE ORIGEN NO PUEDE QUEDAR VACIA"
        return 1
fi

if [[ ! -d "$origen" ]]; then
        echo "ERROR: LA CARPETA DE ORIGEN NO EXISTE"
        return 1
fi

read -rp "Carpeta de destino: " destino

if [[ -z "$destino" ]]; then
        echo "ERROR: EL DESTINO NO PUEDE QUEDAR VACIO"
        return 1
fi

if [[ -d "$destino" ]]; then
    if ! confirmar_accion "El destino '$destino' ya existe. ¿Desea continuar y posiblemente combinar/sobrescribir contenido?"; then
        return 1
    fi
fi

#COPIA EN MODO ARCHIVO: preserva permisos, dueño y fechas originales
if cp -a "$origen" "$destino"; then
        echo "Carpeta copiada exitosamente (con permisos y propietarios preservados)"
        registrar_bitacora "Se copio '$origen' a '$destino'"
        return 0
    else
        echo "ERROR: NO SE PUDO COPIAR"
        return 1
fi

}
#===========================================================================================================================================================

#FUNCION PARA VER EL TAMAÑO DE UNA CARPETA
#===========================================================================================================================================================
ver_size_carpeta() {

local ruta
read -rp "Ruta de la carpeta: " ruta

#VALIDACION DE CAMPO VACIO
if [[ -z "$ruta" ]]; then
        echo "ERROR: LA RUTA NO PUEDE QUEDAR VACIA"
        return 1
fi

#VALIDACION DE CARPETA EXISTENTE
if [[ ! -d "$ruta" ]]; then
        echo "ERROR: LA CARPETA NO EXISTE"
        return 1
fi

echo "Tamaño de '$ruta':"
du -sh "$ruta"

}
#===========================================================================================================================================================

#FUNCION PARA ELIMINAR UNA CARPETA
#===========================================================================================================================================================
eliminar_carpeta() {

if ! requiere_root; then
        return 1
fi
local ruta
read -rp "Ruta de la carpeta a eliminar: " ruta

if [[ -z "$ruta" ]]; then
        echo "ERROR: LA RUTA NO PUEDE QUEDAR VACIA"
        return 1
fi

#VALIDACION: EXIGIR RUTA ABSOLUTA
if [[ "$ruta" != /* ]]; then
        echo "ERROR: debe ingresar una ruta absoluta (que empiece con /)"
        return 1
fi

if [[ ! -d "$ruta" ]]; then
        echo "ERROR: LA CARPETA NO EXISTE"
        return 1
fi

case "$ruta" in
     "/" | "/etc" | "/home" | "/usr" | "/bin" | "/var" | "/root" | "/boot" | "/sbin" | "/lib" | "/dev" | "/proc" | "/sys")
     echo "ERROR: NO SE PUEDE ELIMINAR UNA CARPETA CRITICA DEL SISTEMA"
     return 1
        ;;
    esac

if ! confirmar_accion "¿Está seguro que desea eliminar '$ruta' y todo su contenido?"; then
        return 1
fi

if rm -rf "$ruta"; then
        echo "Carpeta eliminada exitosamente"
        registrar_bitacora "Se elimino la carpeta '$ruta'"
        return 0
    else
        echo "ERROR: NO SE PUDO ELIMINAR"
        return 1
fi

}
#===========================================================================================================================================================

#MENU DE LAS CARPETAS
#===========================================================================================================================================================

menu_carpetas() {
    local opcion
    while true; do
        clear
        echo "============================================"
        echo " ADMINISTRACIÓN DE CARPETAS"
        echo "============================================"
        echo "1) Crear carpeta"
        echo "2) Listar contenido"
        echo "3) Buscar carpeta"
        echo "4) Renombrar carpeta"
        echo "5) Mover carpeta"
        echo "6) Copiar carpeta"
        echo "7) Ver tamaño de una carpeta"
        echo "8) Eliminar carpeta"
        echo "0) Volver al menú principal"
        echo "============================================"
        read -rp "Opción: " opcion

        case "$opcion" in
            1) crear_carpeta ;;
            2) ver_carpeta ;;
            3) buscar_carpeta ;;
            4) cambiar_nombre_carpeta ;;
            5) mover_carpeta ;;
            6) copiar_carpeta ;;
            7) ver_size_carpeta ;;
            8) eliminar_carpeta ;;
            0) return ;;
            *) echo "Opción inválida." ;;
        esac
        pausar
    done
}
