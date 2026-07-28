#! /bin/bash

#SCRIPT PARA ADMINISTRACION Y ASIGNACION DE PERMISOS

#FUNCION PARA REVISAR PERMISOS ACTUALES
#===========================================================================================================================================================
consultar_permisos() {

local ruta
read -rp "Ruta a consultar: " ruta

#VALIDACION DE EXISTENCIA DE LA CARPETA
if [[ ! -e "$ruta" ]]; then
        echo "ERROR: LA RUTA NO EXISTE"
        return 1
fi

#MUESTRA LOS PERMISOS DE LA CARPETA
echo "Permisos de '$ruta': "
ls -ld "$ruta"

#MOSTRAR DETALLES DE CADA PERMISO

local permisos
permisos="$(stat -c "%A" "$ruta")"

echo ""
echo "Explicación: $permisos"
echo "  Propietario: ${permisos:1:3}"
echo "  Grupo:       ${permisos:4:3}"
echo "  Otros:       ${permisos:7:3}"

}
#===========================================================================================================================================================

#FUNCION PARA CAMBIAR PERMISO METODO OCTAL
#===========================================================================================================================================================
cambiar_permisos_numerico() {
#VALIDACION DE USUARIO CON PERMISOS ROOT 
if ! requiere_root; then
        return 1
fi

local ruta
local permiso

read -rp "Ruta: " ruta

#VALIDACION DE CARPETA INEXISTENTE
if [[ ! -e "$ruta" ]]; then
        echo "ERROR: LA RUTA NO EXISTE"
        return 1
fi

read -rp "Permiso numérico (ej. 750): " permiso

#VALIDACION DE FORMATO VALIDO
if [[ ! "$permiso" =~ ^[0-7]{3,4}$ ]]; then
        echo "ERROR: PERMISO INVALIDO (use 3 o 4 dígitos del 0 al 7)"
        return 1
fi

#ADVERTENCIA OBLIGATORIA CONTRA 777
if [[ "$permiso" == "777" ]]; then

        echo "ADVERTENCIA: 777 da permisos TOTALES a TODOS los usuarios."
        echo "             Esto es un riesgo de seguridad grave."

	if ! confirmar_accion "¿Desea continuar de todas formas?"; then
            return 1
        fi
fi

#CAMBIAR LOS PERMISOS DE LA CARPETA
if chmod "$permiso" "$ruta"; then
        echo "Permisos cambiados a $permiso exitosamente"
        registrar_bitacora "Se cambiaron permisos de '$ruta' a $permiso"
        return 0
    else
        echo "ERROR: NO SE PUDIERON CAMBIAR LOS PERMISOS"
        return 1
fi

}
#===========================================================================================================================================================

#FUNCION PARA CAMBIAR PERMISO; METODO SIMBOLICO
cambiar_permisos_simbolico() {
#VALIDACION USUARIO ROOT
if ! requiere_root; then
        return 1
fi

local ruta
local permiso

read -rp "Ruta: " ruta

#VALIDACION SI CARPETA EXISTE
if [[ ! -e "$ruta" ]]; then
        echo "ERROR: LA RUTA NO EXISTE"
        return 1
fi

echo "Ejemplo de notación simbólica: u+rwx,g+rx,o-rwx"

read -rp "Permiso simbólico: " permiso

#VALIDACION DE CAMPO VACIO
if [[ -z "$permiso" ]]; then
        echo "ERROR: EL PERMISO NO PUEDE QUEDAR VACIO"
        return 1
fi

#CAMBIAR PERMISOS
if chmod "$permiso" "$ruta" 2>/dev/null; then
        echo "Permisos cambiados exitosamente"
        registrar_bitacora "Se cambiaron permisos simbolicos de '$ruta' a $permiso"
        return 0
    else
        echo "ERROR: NOTACION INVALIDA O NO SE PUDO APLICAR"
        return 1
fi

}
#===========================================================================================================================================================

#FUNCION PARA CAMBIAR EL PROPIETARIO DE LA CARPETA
#===========================================================================================================================================================
cambiar_propietario() {
#VALIDACION DE USUARIO ROOT
if ! requiere_root; then
        return 1
fi

local ruta
local nuevo_dueno

read -rp "Ruta: " ruta

#VALIDACION DE EXISTENCIA DE LA CARPETA 
if [[ ! -e "$ruta" ]]; then
        echo "ERROR: LA RUTA NO EXISTE"
        return 1
fi

read -rp "Nuevo propietario (usuario): " nuevo_dueno

#VALIDACION DE USUARIO EXISTENTE
if ! id "$nuevo_dueno" &> /dev/null; then
        echo "ERROR: EL USUARIO NO EXISTE"
        return 1
fi

#CAMBIAR DE PROPIETARIO LA CARPETA
if chown "$nuevo_dueno" "$ruta"; then
        echo "Propietario cambiado exitosamente"
        registrar_bitacora "Se cambio propietario de '$ruta' a '$nuevo_dueno'"
        return 0
    else
        echo "ERROR: NO SE PUDO CAMBIAR EL PROPIETARIO"
        return 1
fi

}
#===========================================================================================================================================================

#FUNCION PARA CAMBIAR DE GRUPO UN USUARIO
#===========================================================================================================================================================
cambiar_grupo() {
#VALIDACION DE USUAIO ROOT 
if ! requiere_root; then
        return 1
fi

local ruta
local nuevo_grupo

read -rp "Ruta: " ruta

#VALIDACION DE LA CARPETA INEXISTENTE
if [[ ! -e "$ruta" ]]; then
        echo "ERROR: LA RUTA NO EXISTE"
        return 1
fi

read -rp "Nuevo grupo propietario: " nuevo_grupo

#VALIDACION GRUPO INEXISTENTE
if ! getent group "$nuevo_grupo" &> /dev/null; then
        echo "ERROR: EL GRUPO NO EXISTE"
        return 1
fi

#CAMBIAR DE GRUPO
if chgrp "$nuevo_grupo" "$ruta"; then
        echo "Grupo propietario cambiado exitosamente"
        registrar_bitacora "Se cambio grupo de '$ruta' a '$nuevo_grupo'"
        return 0
    else
        echo "ERROR: NO SE PUDO CAMBIAR EL GRUPO"
        return 1
fi

}
#===========================================================================================================================================================

#FUNCION PARA ANALIZAR PERMISOS DEL USUARIO
#===========================================================================================================================================================
identificar_permisos_inseguros() {

local ruta
read -rp "Ruta a analizar (carpeta): " ruta

#VALIDAR EXISTENCIA DE CARPETA
if [[ ! -d "$ruta" ]]; then
        echo "ERROR: LA CARPETA NO EXISTE"
        return 1
fi

echo "Buscando permisos inseguros (777) en '$ruta': "

local resultado
resultado="$(find "$ruta" -perm 777 2>/dev/null)"

#FILTRA PERMISOS 777
if [[ -z "$resultado" ]]; then
        echo "  (No se encontraron archivos/carpetas con permisos 777)"
    else
        echo "$resultado"
fi

}
#===========================================================================================================================================================

#FUNCION PARA CREAR UNA CARPETA PRIVADA
#===========================================================================================================================================================
crear_escenario_privado() {
#VALIDACION DE CARPETA ROOT
if ! requiere_root; then
        return 1
fi

local ruta
local grupo

read -rp "Ruta del directorio privado a crear: " ruta
read -rp "Grupo dueño (ej. infraestructura): " grupo

#VALIDACION DE CAMPOS
if [[ -z "$ruta" ]] || [[ -z "$grupo" ]]; then
        echo "ERROR: AMBOS CAMPOS SON OBLIGATORIOS"
        return 1
fi

#VALIDACION DE GRUPO INEXISTENTE
if ! getent group "$grupo" &> /dev/null; then
        echo "ERROR: EL GRUPO NO EXISTE"
        return 1
fi

mkdir -p "$ruta"
chgrp "$grupo" "$ruta"
chmod 770 "$ruta"

echo "Escenario PRIVADO creado: '$ruta'"
echo "  Propietario: rwx | Grupo ($grupo): rwx | Otros: sin acceso"
registrar_bitacora "Se creo escenario privado en '$ruta' para grupo '$grupo'"

}
#===========================================================================================================================================================

#FUNCION PARA CREAR CARPETA COMPARTIDA
#===========================================================================================================================================================
crear_escenario_compartido() {
#VALIDACION DE USUARIO ROOT
if ! requiere_root; then
        return 1
fi

local ruta
local grupo

read -rp "Ruta del directorio compartido a crear: " ruta
read -rp "Grupo con acceso (ej. desarrollo): " grupo

#VALIDACION DE CAMPOS
if [[ -z "$ruta" ]] || [[ -z "$grupo" ]]; then
        echo "ERROR: AMBOS CAMPOS SON OBLIGATORIOS"
        return 1
fi

#VALIDACION DE GRUPO INEXISTENTE
if ! getent group "$grupo" &> /dev/null; then
        echo "ERROR: EL GRUPO NO EXISTE"
        return 1
fi

mkdir -p "$ruta"
chgrp "$grupo" "$ruta"
chmod 2770 "$ruta"    # el '2' inicial es SGID: los archivos nuevos heredan el grupo

echo "Escenario COMPARTIDO creado: '$ruta'"
echo "  Grupo ($grupo): lectura y escritura | Otros: sin acceso"
echo "  (Se aplico SGID para que archivos nuevos hereden el grupo '$grupo')"
registrar_bitacora "Se creo escenario compartido en '$ruta' para grupo '$grupo'"

}
#===========================================================================================================================================================

#FUNCION PARA CREAR UNA CARPETA DE SOLO LECTURA
#===========================================================================================================================================================
crear_escenario_solo_lectura() {
#VALIDACION DE USUARIO ROOT
if ! requiere_root; then
        return 1
fi

local ruta
local grupo

read -rp "Ruta del directorio de consulta a crear: " ruta
read -rp "Grupo con acceso de solo lectura (ej. soporte): " grupo

#VALIDACION DE CAMPOS VACIOS
if [[ -z "$ruta" ]] || [[ -z "$grupo" ]]; then
        echo "ERROR: AMBOS CAMPOS SON OBLIGATORIOS"
        return 1
fi

#VALIDACION DE GRUPO QUE NO EXISTE
if ! getent group "$grupo" &> /dev/null; then
        echo "ERROR: EL GRUPO NO EXISTE"
        return 1
fi

mkdir -p "$ruta"
chgrp "$grupo" "$ruta"
chmod 750 "$ruta"    # propietario: rwx | grupo: r-x | otros: sin acceso

echo "Escenario de CONSULTA creado: '$ruta'"
echo "  Grupo ($grupo): solo lectura y acceso | Otros: sin acceso"
registrar_bitacora "Se creo escenario de solo lectura en '$ruta' para grupo '$grupo'"

}
#===========================================================================================================================================================

#MENU PERMISOS
#===========================================================================================================================================================
menu_permisos() {
    local opcion
    while true; do
        clear
        echo "============================================"
        echo " GESTIÓN DE PERMISOS"
        echo "============================================"
        echo "1) Consultar permisos"
        echo "2) Cambiar permisos (numérico)"
        echo "3) Cambiar permisos (simbólico)"
        echo "4) Cambiar propietario"
        echo "5) Cambiar grupo propietario"
        echo "6) Identificar permisos inseguros (777)"
        echo "7) Crear escenario: directorio privado"
        echo "8) Crear escenario: directorio compartido"
        echo "9) Crear escenario: directorio de consulta"
        echo "0) Volver al menú principal"
        echo "============================================"
        read -rp "Opción: " opcion

        case "$opcion" in
            1) consultar_permisos ;;
            2) cambiar_permisos_numerico ;;
            3) cambiar_permisos_simbolico ;;
            4) cambiar_propietario ;;
            5) cambiar_grupo ;;
            6) identificar_permisos_inseguros ;;
            7) crear_escenario_privado ;;
            8) crear_escenario_compartido ;;
            9) crear_escenario_solo_lectura ;;
            0) return ;;
            *) echo "Opción inválida." ;;
        esac
        pausar
    done
}
