#! /bin/bash

#SCRIPT PARA MANIPULAR Y ADMINISTRAR ARCHIVOS

#FUNCION PARA CREAR UN ARCHIVO
#===========================================================================================================================================================
crear_archivo() {

local ruta

read -rp "Ruta del nuevo archivo: " ruta

#VALIDACION CAMPO VACIO
if [[ -z "$ruta" ]]; then
        echo "ERROR: LA RUTA NO PUEDE QUEDAR VACIA"
        return 1
fi

#VALIDACION DE ARCHIVO EXISTENTE
if [[ -f "$ruta" ]]; then
        echo "ERROR: EL ARCHIVO YA EXISTE"
        return 1
fi

#CREACION DEL ARCHIVO
if touch "$ruta"; then
        echo "Archivo creado exitosamente: $ruta"
        registrar_bitacora "Se creo el archivo '$ruta'"
        return 0
    else
        echo "ERROR: NO SE PUDO CREAR EL ARCHIVO"
        return 1
fi

}
#===========================================================================================================================================================


#FUNCION PARA MODIFICAR UN ARCHIVO
#===========================================================================================================================================================
escribir_archivo() {

local ruta
local contenido

read -rp "Ruta del archivo: " ruta

#VALIDACION DE EXISTENCIA DE ARCHIVO
if [[ ! -f "$ruta" ]]; then
        echo "ERROR: EL ARCHIVO NO EXISTE"
        return 1
fi

#CONFIRMACION ANTES DE ESCRIBIR EN EL ARCHIVO
if [[ -s "$ruta" ]]; then
        if ! confirmar_accion "El archivo ya tiene contenido. ¿Desea sobrescribirlo?"; then
            return 1
        fi
fi

read -rp "Contenido a escribir: " contenido
echo "$contenido" > "$ruta"
echo "Contenido escrito exitosamente"
registrar_bitacora "Se escribio contenido en '$ruta'"

}

#==========================================================================================================================================================

#FUNCION AGREGAR CONTINIDO SIN SOBREESCRIBIR
agregar_contenido() {

local ruta
local contenido

read -rp "Ruta del archivo: " ruta

#VALIDACION SI ARCHIVO EXISTE
if [[ ! -f "$ruta" ]]; then
        echo "ERROR: EL ARCHIVO NO EXISTE"
        return 1
fi

read -rp "Contenido a agregar: " contenido
echo "$contenido" >> "$ruta"
echo "Contenido agregado exitosamente"
registrar_bitacora "Se agrego contenido a '$ruta'"

}

#===========================================================================================================================================================

#FUNCION PARA LEER CONTENIDO DE ARCHIBVO
#===========================================================================================================================================================
leer_archivo() {

local ruta
read -rp "Ruta del archivo: " ruta

#VALIDACION SI EXISTE EL ARCHIVO 
if [[ ! -f "$ruta" ]]; then
        echo "ERROR: EL ARCHIVO NO EXISTE"
        return 1
fi

echo "Contenido de '$ruta': "
cat "$ruta"

}
#===========================================================================================================================================================

#FUNCION PARA COPIAR UN ARCHIVO
#===========================================================================================================================================================
copiar_archivo() {

local origen
local destino

read -rp "Archivo de origen: " origen

#VALIDACION DE EXISTENCIA DE ARCHYVO
if [[ ! -f "$origen" ]]; then
        echo "ERROR: EL ARCHIVO DE ORIGEN NO EXISTE"
        return 1
fi

read -rp "Ruta de destino: " destino

#CONFIRMAICON ANTES DE COPIAR ARCHIVO
if [[ -f "$destino" ]]; then
        if ! confirmar_accion "El destino ya existe. ¿Desea sobrescribirlo?"; then
            return 1
        fi
fi

#COPIARR EL ARCHIVO
if cp "$origen" "$destino"; then
        echo "Archivo copiado exitosamente"
        registrar_bitacora "Se copio '$origen' a '$destino'"
        return 0
    else
        echo "ERROR: NO SE PUDO COPIAR"
        return 1
fi

}
#===========================================================================================================================================================

#FUNCION PARA MOVER UN ARCHIVO
#===========================================================================================================================================================
mover_archivo() {

local origen
local destino

read -rp "Archivo a mover: " origen

#VALIDACION DE EXISTENCAI DE ARCHIVO
if [[ ! -f "$origen" ]]; then
        echo "ERROR: EL ARCHIVO NO EXISTE"
        return 1
fi

read -rp "Carpeta de destino: " destino

#VALIDACION DE EXISTENCIA DE CARPETA DESTINO
if [[ ! -d "$destino" ]]; then
        echo "ERROR: LA CARPETA DE DESTINO NO EXISTE"
        return 1
fi

#MOVER ARCHIVO A NUEVA RUTA
if mv "$origen" "$destino/"; then
        echo "Archivo movido exitosamente"
        registrar_bitacora "Se movio '$origen' a '$destino'"
        return 0
    else
        echo "ERROR: NO SE PUDO MOVER"
        return 1
fi

}
#===========================================================================================================================================================

#FUNCION PARA CAMBIAR NOMBRE A UN ARCHIVO
#===========================================================================================================================================================
renombrar_archivo() {

local ruta_actual
local ruta_nueva

read -rp "Ruta actual del archivo: " ruta_actual

#VALIDACION DE EXISTENCIA DE ARCHIVO
if [[ ! -f "$ruta_actual" ]]; then
        echo "ERROR: EL ARCHIVO NO EXISTE"
        return 1
fi

read -rp "Nuevo nombre/ruta: " ruta_nueva

#VALIDACION DE NUEVA RUTA EXISTENTE
if [[ -f "$ruta_nueva" ]]; then
        echo "ERROR: YA EXISTE UN ARCHIVO CON ESE NOMBRE"
        return 1
fi

#CAMBIAR NOMBRE A UN ARCHIVO
if mv "$ruta_actual" "$ruta_nueva"; then
        echo "Archivo renombrado exitosamente"
        registrar_bitacora "Se reenombro '$ruta_actual' a '$ruta_nueva'"
        return 0
    else
        echo "ERROR: NO SE PUDO RENOMBRAR"
        return 1
fi

}
#===========================================================================================================================================================

#FUNCION PARA BUSCAR UN ARCHIVO
#===========================================================================================================================================================
buscar_archivo() {

local nombre_buscar
read -rp "Nombre de archivo a buscar: " nombre_buscar

#VALIDAR CAMPO VACIO
if [[ -z "$nombre_buscar" ]]; then
        echo "ERROR: EL NOMBRE NO PUEDE QUEDAR VACIO"
        return 1
fi

echo "Resultados de la búsqueda: "

local resultado
resultado="$(find "$RUTA_PRINCIPAL" -type f -iname "*$nombre_buscar*" 2>/dev/null)"

#
if [[ -z "$resultado" ]]; then
        echo "  (No se encontraron coincidencias)"
    else
        echo "$resultado"
    fi
}
#===========================================================================================================================================================

#FUNCION QUE MUESTRA INFORMACION DEL ARCHIVO
#===========================================================================================================================================================
info_archivo() {

local ruta
read -rp "Ruta del archivo: " ruta

#VALIDACION EXISTENCIA DEL ARCHIVO
if [[ ! -f "$ruta" ]]; then
        echo "ERROR: EL ARCHIVO NO EXISTE"
        return 1
fi

echo "Información de '$ruta': "
echo "Tipo: $(file -b "$ruta")"
echo "Tamaño: $(du -h "$ruta" | cut -f1)"

}
#===========================================================================================================================================================

#FUNCION PARA ELIMINAR UN ARCHIVO
#===========================================================================================================================================================
eliminar_archivo() {
#VALIDACION USUARIO CON PRIVILEGIOS 
if ! requiere_root; then
        return 1
fi

local ruta
read -rp "Ruta del archivo a eliminar: " ruta

#VALIDACION EXISTENCIA DEL ARCHIVO
if [[ ! -f "$ruta" ]]; then
        echo "ERROR: EL ARCHIVO NO EXISTE"
        return 1
fi

#VALIDACION ANTES DE ELIMIANR EL ARCHIVO
if ! confirmar_accion "¿Está seguro que desea eliminar '$ruta'?"; then
        return 1
fi

#ELIMINAR EL ARCHIVO PERMANENTEMENTE
if rm "$ruta"; then
        echo "Archivo eliminado exitosamente"
        registrar_bitacora "Se elimino el archivo '$ruta'"
        return 0
    else
        echo "ERROR: NO SE PUDO ELIMINAR"
        return 1
fi

}
#===========================================================================================================================================================

#FUNCION PARA COMPRIMIR ARCHIVOS
comprimir_archivo() {

local ruta
read -rp "Ruta del archivo o carpeta a comprimir: " ruta

#VALIDACION SI ARCHIVO EXISTE
if [[ ! -e "$ruta" ]]; then
        echo "ERROR: LA RUTA NO EXISTE"
        return 1
fi

local nombre_zip="${ruta}.tar.gz"

#COMPRIMIR EL ARCHIVO
if tar -czf "$nombre_zip" "$ruta" 2>/dev/null; then
        echo "Comprimido exitosamente: $nombre_zip"
        registrar_bitacora "Se comprimio '$ruta'"
        return 0
    else
        echo "ERROR: NO SE PUDO COMPRIMIR"
        return 1
fi

}
#===========================================================================================================================================================

#FUNCION PARA DESCOMPRIMIR ARCHIVO
#===========================================================================================================================================================
descomprimir_archivo() {

local ruta
read -rp "Ruta del archivo .tar.gz a descomprimir: " ruta

#VALIDACION DE EXISTENCIA DEL ARCHIVO
if [[ ! -f "$ruta" ]]; then
        echo "ERROR: EL ARCHIVO NO EXISTE"
        return 1
fi

#DESCOMPRIMIR EL ARCHIVO TAR
if tar -xzf "$ruta" 2>/dev/null; then
        echo "Descomprimido exitosamente"
        registrar_bitacora "Se descomprimio '$ruta'"
        return 0
    else
        echo "ERROR: NO SE PUDO DESCOMPRIMIR"
        return 1
fi

}
#===========================================================================================================================================================


#MENU DE ARCHIVOS
#============================================================================================================================================================
menu_archivos() {
    local opcion
    while true; do
        clear
        echo "============================================"
        echo " ADMINISTRACIÓN DE ARCHIVOS"
        echo "============================================"
        echo "1) Crear archivo"
        echo "2) Escribir contenido (sobrescribe)"
        echo "3) Agregar contenido"
        echo "4) Consultar contenido"
        echo "5) Copiar archivo"
        echo "6) Mover archivo"
        echo "7) Renombrar archivo"
        echo "8) Buscar archivo"
        echo "9) Ver info (tipo y tamaño)"
        echo "10) Comprimir archivo/carpeta"
        echo "11) Descomprimir archivo"
        echo "12) Eliminar archivo"
        echo "0) Volver al menú principal"
        echo "============================================"
        read -rp "Opción: " opcion

        case "$opcion" in
            1) crear_archivo ;;
            2) escribir_archivo ;;
            3) agregar_contenido ;;
            4) leer_archivo ;;
            5) copiar_archivo ;;
            6) mover_archivo ;;
            7) renombrar_archivo ;;
            8) buscar_archivo ;;
            9) info_archivo ;;
            10) comprimir_archivo ;;
            11) descomprimir_archivo ;;
            12) eliminar_archivo ;;
            0) return ;;
            *) echo "Opción inválida." ;;
        esac
        pausar
    done
}
