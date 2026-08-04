#! /bin/bash

#SCRIPT PARA ADMINISTRACION Y ASIGNACION DE PERMISOS

#FUNCION PARA REVISAR PERMISOS ACTUALES
#===========================================================================================================================================================
consultar_permisos() {

local ruta
read -rp "Ruta a consultar: " ruta

if [[ -z "$ruta" ]]; then
        echo "ERROR: LA RUTA NO PUEDE QUEDAR VACIA"
        return 1
fi

if [[ ! -e "$ruta" ]]; then
        echo "ERROR: LA RUTA NO EXISTE"
        return 1
fi

echo "Permisos de '$ruta': "
ls -ld "$ruta"

local permisos
permisos="$(stat -c "%A" "$ruta")"
local permisos_numericos
permisos_numericos="$(stat -c "%a" "$ruta")"

echo ""
echo "Explicación: $permisos (numérico: $permisos_numericos)"
echo "  Propietario: ${permisos:1:3}"
echo "  Grupo:       ${permisos:4:3}"
echo "  Otros:       ${permisos:7:3}"
echo ""
echo "Dueño: $(stat -c '%U' "$ruta")   Grupo dueño: $(stat -c '%G' "$ruta")"

}
#===========================================================================================================================================================

#FUNCION PARA CAMBIAR PERMISO METODO OCTAL
#===========================================================================================================================================================
cambiar_permisos_numerico() {

if ! requiere_root; then
        return 1
fi

local ruta
local permiso
read -rp "Ruta: " ruta

if [[ -z "$ruta" ]]; then
        echo "ERROR: LA RUTA NO PUEDE QUEDAR VACIA"
        return 1
fi

if [[ ! -e "$ruta" ]]; then
        echo "ERROR: LA RUTA NO EXISTE"
        return 1
fi

read -rp "Permiso numérico (ej. 750): " permiso

if [[ ! "$permiso" =~ ^[0-7]{3,4}$ ]]; then
        echo "ERROR: PERMISO INVALIDO (use 3 o 4 dígitos del 0 al 7)"
        return 1
fi

if [[ "$permiso" == "777" ]]; then
        echo "ADVERTENCIA: 777 da permisos TOTALES a TODOS los usuarios."
        echo "             Esto es un riesgo de seguridad grave."
        if ! confirmar_accion "¿Desea continuar de todas formas?"; then
            return 1
        fi
fi

#PREGUNTAR SI SE APLICA DE FORMA RECURSIVA (SOLO SI ES CARPETA)
local aplicar_recursivo=""
if [[ -d "$ruta" ]]; then
    if confirmar_accion "¿Desea aplicar el cambio a TODO el contenido dentro de la carpeta (recursivo)?"; then
        aplicar_recursivo="-R"
    fi
fi

#CAMBIAR LOS PERMISOS
if chmod $aplicar_recursivo "$permiso" "$ruta"; then
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

if ! requiere_root; then
        return 1
fi

local ruta
local permiso
read -rp "Ruta: " ruta

if [[ -z "$ruta" ]]; then
        echo "ERROR: LA RUTA NO PUEDE QUEDAR VACIA"
        return 1
fi

if [[ ! -e "$ruta" ]]; then
        echo "ERROR: LA RUTA NO EXISTE"
        return 1
fi

echo "Ejemplos de notación simbólica:"
echo "  u+x        -> agregar ejecución al dueño"
echo "  o-wx       -> quitar escritura y ejecución a otros"
echo "  g=r        -> el grupo tendrá SOLO lectura (reemplaza lo anterior)"
echo "  u+rwx,g+rx,o-rwx -> combinar varios cambios a la vez"

read -rp "Permiso simbólico: " permiso

if [[ -z "$permiso" ]]; then
        echo "ERROR: EL PERMISO NO PUEDE QUEDAR VACIO"
        return 1
fi

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

if ! requiere_root; then
        return 1
fi

local ruta
local nuevo_dueno
read -rp "Ruta: " ruta

if [[ -z "$ruta" ]]; then
        echo "ERROR: LA RUTA NO PUEDE QUEDAR VACIA"
        return 1
fi

if [[ ! -e "$ruta" ]]; then
        echo "ERROR: LA RUTA NO EXISTE"
        return 1
fi

read -rp "Nuevo propietario (usuario): " nuevo_dueno

if [[ -z "$nuevo_dueno" ]]; then
        echo "ERROR: EL USUARIO NO PUEDE QUEDAR VACIO"
        return 1
fi

if ! id "$nuevo_dueno" &> /dev/null; then
        echo "ERROR: EL USUARIO NO EXISTE"
        return 1
fi

#PREGUNTAR SI SE APLICA DE FORMA RECURSIVA (SOLO SI ES CARPETA)
local aplicar_recursivo=""
if [[ -d "$ruta" ]]; then
    if confirmar_accion "¿Desea aplicar el cambio a TODO el contenido dentro de la carpeta (recursivo)?"; then
        aplicar_recursivo="-R"
    fi
fi

if chown $aplicar_recursivo "$nuevo_dueno" "$ruta"; then
        echo "Propietario cambiado exitosamente"
        #CONFIRMACION VISUAL DEL CAMBIO
        stat -c "Nuevo Propietario: %U | Grupo: %G" "$ruta"
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

if ! requiere_root; then
        return 1
fi
local ruta
local nuevo_grupo
read -rp "Ruta: " ruta

#VALIDACION DE CAMPO VACIO (RUTA)
if [[ -z "$ruta" ]]; then
        echo "ERROR: LA RUTA NO PUEDE QUEDAR VACIA"
        return 1
fi

#VALIDACION DE LA RUTA INEXISTENTE
if [[ ! -e "$ruta" ]]; then
        echo "ERROR: LA RUTA NO EXISTE"
        return 1
fi
read -rp "Nuevo grupo propietario: " nuevo_grupo

#VALIDACION DE CAMPO VACIO (GRUPO)
if [[ -z "$nuevo_grupo" ]]; then
        echo "ERROR: EL GRUPO NO PUEDE QUEDAR VACIO"
        return 1
fi

#VALIDACION GRUPO INEXISTENTE
if ! getent group "$nuevo_grupo" &> /dev/null; then
        echo "ERROR: EL GRUPO NO EXISTE"
        return 1
fi

#PREGUNTAR SI SE APLICA DE FORMA RECURSIVA (SOLO SI ES CARPETA)
local aplicar_recursivo=""
if [[ -d "$ruta" ]]; then
    if confirmar_accion "¿Desea aplicar el cambio a TODO el contenido dentro de la carpeta (recursivo)?"; then
        aplicar_recursivo="-R"
    fi
fi

#CAMBIAR DE GRUPO
if chgrp $aplicar_recursivo "$nuevo_grupo" "$ruta"; then
        echo "Grupo propietario cambiado exitosamente"
        #CONFIRMACION VISUAL DEL CAMBIO
        stat -c "Propietario: %U | Nuevo Grupo: %G" "$ruta"
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

if ! requiere_root; then
        return 1
fi
local ruta
local grupo
read -rp "Ruta del directorio privado a crear: " ruta
read -rp "Grupo dueño (ej. infraestructura): " grupo

if [[ -z "$ruta" ]] || [[ -z "$grupo" ]]; then
        echo "ERROR: AMBOS CAMPOS SON OBLIGATORIOS"
        return 1
fi

if ! getent group "$grupo" &> /dev/null; then
        echo "ERROR: EL GRUPO NO EXISTE"
        return 1
fi

#AVISO SI LA CARPETA YA EXISTIA
if [[ -d "$ruta" ]]; then
        echo "AVISO: la carpeta ya existía. Se le aplicarán los nuevos permisos."
fi

#CREACION Y CONFIGURACION DEL ESCENARIO, VALIDANDO CADA PASO
if ! mkdir -p "$ruta"; then
        echo "ERROR: NO SE PUDO CREAR LA CARPETA"
        return 1
fi

if ! chgrp "$grupo" "$ruta"; then
        echo "ERROR: NO SE PUDO ASIGNAR EL GRUPO"
        return 1
fi

if ! chmod 770 "$ruta"; then
        echo "ERROR: NO SE PUDIERON APLICAR LOS PERMISOS"
        return 1
fi

echo "Escenario PRIVADO creado: '$ruta'"
echo "  Propietario: rwx | Grupo ($grupo): rwx | Otros: sin acceso"
registrar_bitacora "Se creo escenario privado en '$ruta' para grupo '$grupo'"
return 0

}
#===========================================================================================================================================================

#FUNCION PARA CREAR CARPETA COMPARTIDA
#===========================================================================================================================================================
crear_escenario_compartido() {

if ! requiere_root; then
        return 1
fi
local ruta
local grupo
read -rp "Ruta del directorio compartido a crear: " ruta
read -rp "Grupo con acceso (ej. desarrollo): " grupo

if [[ -z "$ruta" ]] || [[ -z "$grupo" ]]; then
        echo "ERROR: AMBOS CAMPOS SON OBLIGATORIOS"
        return 1
fi

if ! getent group "$grupo" &> /dev/null; then
        echo "ERROR: EL GRUPO NO EXISTE"
        return 1
fi

#AVISO SI LA CARPETA YA EXISTIA
if [[ -d "$ruta" ]]; then
        echo "AVISO: la carpeta ya existía. Se le aplicarán los nuevos permisos."
fi

#CREACION Y CONFIGURACION DEL ESCENARIO, VALIDANDO CADA PASO
if ! mkdir -p "$ruta"; then
        echo "ERROR: NO SE PUDO CREAR LA CARPETA"
        return 1
fi

if ! chgrp "$grupo" "$ruta"; then
        echo "ERROR: NO SE PUDO ASIGNAR EL GRUPO"
        return 1
fi

# el '2' inicial es SGID: los archivos nuevos heredan el grupo
if ! chmod 2770 "$ruta"; then
        echo "ERROR: NO SE PUDIERON APLICAR LOS PERMISOS"
        return 1
fi

echo "Escenario COMPARTIDO creado: '$ruta'"
echo "  Grupo ($grupo): lectura y escritura | Otros: sin acceso"
echo "  (Se aplico SGID para que archivos nuevos hereden el grupo '$grupo')"
registrar_bitacora "Se creo escenario compartido en '$ruta' para grupo '$grupo'"
return 0

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

if [[ -z "$ruta" ]] || [[ -z "$grupo" ]]; then
        echo "ERROR: AMBOS CAMPOS SON OBLIGATORIOS"
        return 1
fi

if ! getent group "$grupo" &> /dev/null; then
        echo "ERROR: EL GRUPO NO EXISTE"
        return 1
fi


#AVISO SI LA CARPETA YA EXISTIA
if [[ -d "$ruta" ]]; then
        echo "AVISO: la carpeta ya existía. Se le aplicarán los nuevos permisos."
fi

#CREACION Y CONFIGURACION DEL ESCENARIO, VALIDANDO CADA PASO
if ! mkdir -p "$ruta"; then
        echo "ERROR: NO SE PUDO CREAR LA CARPETA"
        return 1
fi

if ! chgrp "$grupo" "$ruta"; then
        echo "ERROR: NO SE PUDO ASIGNAR EL GRUPO"
        return 1
fi

# propietario: rwx | grupo: r-x | otros: sin acceso
if ! chmod 750 "$ruta"; then
        echo "ERROR: NO SE PUDIERON APLICAR LOS PERMISOS"
        return 1
fi

echo "Escenario de CONSULTA creado: '$ruta'"
echo "  Grupo ($grupo): solo lectura y acceso | Otros: sin acceso"
registrar_bitacora "Se creo escenario de solo lectura en '$ruta' para grupo '$grupo'"
return 0

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
        echo "7) Configurar carpeta privada"
        echo "8) Configurar carpeta compartida"
        echo "9) Configurar carpeta de solo lectura"
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
