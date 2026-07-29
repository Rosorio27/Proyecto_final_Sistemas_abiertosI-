#! /bin/bash

#SCRIPT PARA CONFIGURACION DE SHELL DE USUARIO

#FUNCION PARA VER LAS VARIABLE DE ENTORNO
#=======================================================================================================================
ver_variables_entorno() {

echo "Variables de entorno principales: "
echo "Usuario:        $USER"
echo "Home:           $HOME"
echo "Shell actual:   $SHELL"
echo "PATH:           $PATH"
echo "Idioma:         $LANG"

}
#===========================================================================================================================================================

#FUNCION PARA VER EL ARCHIVO BASHRC
#===========================================================================================================================================================
ver_bashrc() {

local archivo="$HOME/.bashrc"

#VALIDACION SI EXISTE EL ARCHIVO
if [[ ! -f "$archivo" ]]; then
        echo "ERROR: NO SE ENCONTRO EL ARCHIVO .bashrc"
        return 1
fi

echo "--- Contenido de .bashrc (últimas 20 líneas) ---"
tail -20 "$archivo"

}
#===========================================================================================================================================================

#FUNCION PARA AGREGAR UN ALIAS
#===========================================================================================================================================================
agregar_alias() {

local nombre_alias
local comando_alias
local archivo="$HOME/.bashrc"

read -rp "Nombre del alias (ej. ll): " nombre_alias

#VALIDACION CAMPO VACIO
if [[ -z "$nombre_alias" ]]; then
        echo "ERROR: EL NOMBRE NO PUEDE QUEDAR VACIO"
        return 1
fi

#VALIDACION DE ALIAS EXISTENTE
if grep -q "alias $nombre_alias=" "$archivo" 2>/dev/null; then
        echo "ERROR: YA EXISTE UN ALIAS CON ESE NOMBRE"
        return 1
fi

read -rp "Comando que ejecutará (ej. 'ls -la'): " comando_alias

#VALIDACION CAMPO VACIO NUEVO ALIAS
if [[ -z "$comando_alias" ]]; then
        echo "ERROR: EL COMANDO NO PUEDE QUEDAR VACIO"
        return 1
fi

echo "alias $nombre_alias='$comando_alias'" >> "$archivo"
echo "Alias '$nombre_alias' agregado exitosamente a .bashrc"
echo "Ejecute 'source ~/.bashrc' o abra una nueva terminal para usarlo"
registrar_bitacora "Se agrego el alias '$nombre_alias' en .bashrc"

}
#===========================================================================================================================================================

#FUNCION PARA VER SHELL ACTUAL
#===========================================================================================================================================================
info_shell_actual() {

echo "--- Información de la Shell actual ---"
echo "Shell en uso: $SHELL"
echo "Versión de Bash: $BASH_VERSION"
echo "PID de la sesión: $$"

}
#===========================================================================================================================================================

#MENU SHELL
#===========================================================================================================================================================
menu_shell() {
    local opcion
    while true; do
        clear
        echo "============================================"
        echo " CONFIGURACIÓN DEL SHELL"
        echo "============================================"
        echo "1) Ver variables de entorno"
        echo "2) Ver contenido de .bashrc"
        echo "3) Agregar un alias"
        echo "4) Info de la Shell actual"
        echo "0) Volver al menú principal"
        echo "============================================"
        read -rp "Opción: " opcion

        case "$opcion" in
            1) ver_variables_entorno ;;
            2) ver_bashrc ;;
            3) agregar_alias ;;
            4) info_shell_actual ;;
            0) return ;;
            *) echo "Opción inválida." ;;
        esac
        pausar
    done
}
#===========================================================================================================================================================
