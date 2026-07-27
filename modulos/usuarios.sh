#! /bin/bash

#SCRIPT PARA MANEJO Y ADMINISTRACION DE USUARIOS 

#CREACION DE NUEVOS USUARIOS
#===========================================================================================================================================================
crear_usuarios(){

#VALIDACION DE ADMINISTRADOR CON PRIVILEGIOS
if ! requiere_root; then 
	return 1
fi

local nombre_usuario
local grupo_asignado

read -rp "Nombre del nuevo usuario: " nombre_usuario

#VALIDACION DE CAMPO VACIO 
if [[ -z "$nombre_usuario" ]];then
	echo "ERROR: EL NOMBRE NO PUEDE QUEDAR VACIO"
	return 1
fi

#VALIDACION DE NOMBRE VALIDO
if [[ ! "$nombre_usuario" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
        echo "ERROR: nombre inválido. Use solo minúsculas, números, '-' o '_',"
        echo "       y debe iniciar con una letra minúscula o '_'."
        return 1
fi

#VALIDACION USUARIO DUPLICADO
if id "$nombre_usuario" &> /dev/null; then
        echo "ERROR: EL USUARIO '$nombre_usuario' YA EXISTE"
        return 1
fi

read -rp "Grupo al que pertenecerá: " grupo_asignado

#VALIDACION GRUPO ASIGNADO VACIO
if [[ -z "$grupo_asignado" ]]; then
        echo "ERROR: EL GRUPO NO PUEDE QUEDAR VACIO"
        return 1
fi

#VALIDACION GRUPO INEXISTENTE
if ! getent group "$grupo_asignado" &> /dev/null; then
        echo "ERROR: EL GRUPO '$grupo_asignado' NO EXISTE"
        return 1
fi

#CREACION DEL USUARIO 
if useradd -m -g "$grupo_asignado" "$nombre_usuario" &> /dev/null; then
	echo "Usuario '$nombre_usuario' creado exitosamente en el grupo '$grupo_asignado'"
        registrar_bitacora "Se creo el usuario '$nombre_usuario' en el grupo '$grupo_asignado'"
        return 0
    else
        echo "ERROR: NO SE PUDO CREAR USUARIO"
        return 1
fi

}
#===========================================================================================================================================================


#FUNCION QUE MUESTRA INFORMACION DEL USUARIO
#===========================================================================================================================================================
ver_info(){

local nombre_usuario
local info_passwd
local home_usuario
local shell_usuario

read -rp "Nombre del usuario a consultar: " nombre_usuario

#VALIDACION DE CAMPO VACIO
if [[ -z "$nombre_usuario" ]]; then
        echo "ERROR: EL NOMBRE NO PUEDE QUEDAR VACIO"
        return 1
fi

#VALIDACION DE USUARIO QUE EXISTA EN SISTEMA
if ! id "$nombre_usuario" &> /dev/null; then
        echo "ERROR: EL USUARIO '$nombre_usuario' NO EXISTE"
        return 1
fi

echo "Información de '$nombre_usuario: "

id "$nombre_usuario"
info_passwd="$(getent passwd "$nombre_usuario")"
home_usuario="$(echo "$info_passwd" | cut -d: -f6)"
shell_usuario="$(echo "$info_passwd" | cut -d: -f7)"

echo "Directorio personal: $home_usuario"
echo "Shell asignada: $shell_usuario"

#VERIFICAR SI EXISTE SU DIRECTORIO PERSONAL 
if [[ -d "$home_usuario" ]]; then
    	echo "Estado del home: EXISTE en el sistema ($home_usuario)"
else
    	echo "Estado del home: NO EXISTE en el sistema (ruta esperada: $home_usuario)"
fi

}
#==========================================================================================================================================================

#FUNCION PARA LISTAR TODOS LOS USUARIOS
lista_usuarios(){

echo "Lista de todos los usuarios del Sistema"

local encontrados=0
local usuario_actual="$(whoami)"

    while read -r linea; do
        local nombre="$(echo "$linea" | cut -d: -f1)"
        local uid="$(echo "$linea" | cut -d: -f3)"
        local grupo_gid="$(echo "$linea" | cut -d: -f4)"

        if [[ "$uid" -ge 1000 ]] && [[ "$nombre" != "nobody" ]] && [[ "$nombre" != "$usuario_actual" ]]; then
            local nombre_grupo
            nombre_grupo="$(getent group "$grupo_gid" | cut -d: -f1)"
            echo " - $nombre (grupo: $nombre_grupo)"
            encontrados=1
        fi
    done < /etc/passwd

    if [[ "$encontrados" -eq 0 ]]; then
        echo "  (Aún no se ha creado ningún usuario)"
    fi

}
#===========================================================================================================================================================
#FUNCION PARA MODIFICAR LA INFORMACION DE LOS USUARIOS 

modificar_usuario(){

if ! requiere_root; then
        return 1
fi

local nombre_usuario
read -rp "Nombre del usuario a modificar: " nombre_usuario

#VALIDACION CAMPO VACIO 
if [[ -z "$nombre_usuario" ]]; then
        echo "ERROR: EL NOMBRE NO PUEDE QUEDAR VACIO"
        return 1
fi

#VALIDACION DE USUARIO EXISTENTE 
if ! id "$nombre_usuario" &> /dev/null; then
        echo "ERROR: EL USUARIO '$nombre_usuario' NO EXISTE"
        return 1
fi

echo "¿Qué desea modificar?"
echo "1) Comentario / nombre completo"
echo "2) Shell asignada"

local opcion_modificar
read -rp "Opción: " opcion_modificar

case "$opcion_modificar" in

	1)
            local nuevo_comentario
            read -rp "Nuevo comentario: " nuevo_comentario

		if usermod -c "$nuevo_comentario" "$nombre_usuario" &> /dev/null; then
                	echo "Comentario actualizado correctamente"
                	registrar_bitacora "Se modifico el comentario del usuario '$nombre_usuario'"
            	else
                	echo "ERROR: NO SE PUDO ACTUALIZAR"
            	fi
            ;;
        2)
            local nueva_shell
            read -rp "Nueva shell (ej. /bin/bash): " nueva_shell

		if [[ ! -f "$nueva_shell" ]]; then
 	               echo "ERROR: esa shell no existe en el sistema"
        	        return 1
            	fi

		if usermod -s "$nueva_shell" "$nombre_usuario" &> /dev/null; then
	                echo "Shell actualizada correctamente"
        	        registrar_bitacora "Se modifico la shell del usuario '$nombre_usuario'"
            	else
                	echo "ERROR: NO SE PUDO ACTUALIZAR"
            	fi
            ;;
        *)
            echo "ERROR: OPCION INVALIDA"
            return 1
            ;;
    esac
}

#===========================================================================================================================================================
#FUNCION PARA BLOQUEAR UN USUARIO

bloquear_usuario() {

if ! requiere_root; then
        return 1
fi

local nombre_usuario
read -rp "Nombre del usuario a bloquear: " nombre_usuario

#VALIDACION DE CAMPO VACIO
if [[ -z "$nombre_usuario" ]]; then
        echo "ERROR: EL NOMBRE NO PUEDE QUEDAR VACIO"
        return 1
fi

#VALIDACION DE EXISTENCIA DE USUARIO
if ! id "$nombre_usuario" &> /dev/null; then
        echo "ERROR: EL USUARIO '$nombre_usuario' NO EXISTE"
        return 1
fi
#BLOQUEAR UN USUARIO
if usermod -L "$nombre_usuario" &> /dev/null; then
        echo "Usuario '$nombre_usuario' bloqueado correctamente"
        registrar_bitacora "Se bloqueo el usuario '$nombre_usuario'"
        return 0
    else
        echo "ERROR: NO SE PUDO BLOQUEAR EL USUARIO"
        return 1
fi

}
#===========================================================================================================================================================

#FUNCION PARA DESBLOQUEAR UN USUARIO 


desbloquear_usuario() {

if ! requiere_root; then
        return 1
fi

local nombre_usuario
read -rp "Nombre del usuario a desbloquear: " nombre_usuario

#VALIDACION DE UN CAMPO VACIO 

if [[ -z "$nombre_usuario" ]]; then
        echo "ERROR: EL NOMBRE NO PUEDE QUEDAR VACIO"
        return 1
fi

#VALIDACION SI EXISTE EL USUARIO 
if ! id "$nombre_usuario" &> /dev/null; then
        echo "ERROR: EL USUARIO '$nombre_usuario' NO EXISTE"
        return 1
fi

#DESBLOQUEAR A UN USUARIO
if usermod -U "$nombre_usuario" &> /dev/null; then
        echo "Usuario '$nombre_usuario' desbloqueado correctamente"
        registrar_bitacora "Se desbloqueo el usuario '$nombre_usuario'"
        return 0
    else
        echo "ERROR: NO SE PUDO DESBLOQUEAR EL USUARIO"
        return 1
fi

}
#===========================================================================================================================================================


#FUNCION PARA ELIMINAR UN USUARIO 

eliminar_usuario() {

if ! requiere_root; then
        return 1
fi

local nombre_usuario
read -rp "Nombre del usuario a eliminar: " nombre_usuario

#VALIDACION DE CAMPO VACIO 
if [[ -z "$nombre_usuario" ]]; then
        echo "ERROR: EL NOMBRE NO PUEDE QUEDAR VACIO"
        return 1
fi

#VALIDACION SI USUARIO NO EXISTE 
if ! id "$nombre_usuario" &> /dev/null; then
        echo "ERROR: EL USUARIO '$nombre_usuario' NO EXISTE"
        return 1
fi

#VALIDACION CONFIRAMA LA OPERACION ANTES DE REALIZAR EL CAMBIO
if ! confirmar_accion "¿Está seguro que desea eliminar al usuario '$nombre_usuario'?"; then
        return 1
fi

if userdel -r "$nombre_usuario" &> /dev/null; then
        echo "Usuario '$nombre_usuario' eliminado correctamente"
        registrar_bitacora "Se elimino el usuario '$nombre_usuario'"
        return 0
    else
        echo "ERROR: NO SE PUDO ELIMINAR EL USUARIO"
        return 1
fi

}

#===========================================================================================================================================================


#FUNCION PARA AGREDAR UN USUARIO A UN GRUPO

agregar_usuario_a_grupo() {

if ! requiere_root; then
        return 1
fi

local nombre_usuario
local nombre_grupo

read -rp "Nombre del usuario: " nombre_usuario
read -rp "Nombre del grupo: " nombre_grupo

#VALIDACION DE CAMPOS VACIOS
if [[ -z "$nombre_usuario" ]] || [[ -z "$nombre_grupo" ]]; then
        echo "ERROR: AMBOS CAMPOS SON OBLIGATORIOS"
        return 1
fi

#VALIDACION DE USUARIO INEXISTENTE
if ! id "$nombre_usuario" &> /dev/null; then
        echo "ERROR: EL USUARIO NO EXISTE"
        return 1
fi

#VALIDACION DE GRUPO INEXISTENTE
if ! getent group "$nombre_grupo" &> /dev/null; then
        echo "ERROR: EL GRUPO NO EXISTE"
        return 1
fi

#AGREGAR UN USUARIO A UN GRUPO
if usermod -aG "$nombre_grupo" "$nombre_usuario" &> /dev/null; then
        echo "Usuario agregado al grupo correctamente"
        registrar_bitacora "Se agrego '$nombre_usuario' al grupo '$nombre_grupo'"
        return 0
    else
        echo "ERROR: NO SE PUDO AGREGAR"
        return 1
fi

}

#===========================================================================================================================================================

#FUNCION PARA ELIMINAR DE UN GRUPO UN USUARIO

retirar_usuario_de_grupo() {

if ! requiere_root; then
        return 1
fi

local nombre_usuario
local nombre_grupo

read -rp "Nombre del usuario: " nombre_usuario
read -rp "Nombre del grupo: " nombre_grupo

#VALIDACION DE CAMPOS VACIOS
if [[ -z "$nombre_usuario" ]] || [[ -z "$nombre_grupo" ]]; then
        echo "ERROR: AMBOS CAMPOS SON OBLIGATORIOS"
        return 1
fi

#RETIRAR DEL GRUPO UN USUARIO
if gpasswd -d "$nombre_usuario" "$nombre_grupo" &> /dev/null; then
        echo "Usuario retirado del grupo correctamente"
        registrar_bitacora "Se retiro '$nombre_usuario' del grupo '$nombre_grupo'"
        return 0
    else
        echo "ERROR: NO SE PUDO RETIRAR (verifique que pertenezca a ese grupo)"
        return 1
fi

}
#===========================================================================================================================================================


#MENU DE USUARIO
#===========================================================================================================================================================
menu_usuarios() {
    local opcion
    while true; do
        clear
        echo "============================================"
        echo " ADMINISTRACIÓN DE USUARIOS"
        echo "============================================"
        echo "1) Crear usuario"
        echo "2) Ver información de un usuario"
        echo "3) Listar usuarios"
        echo "4) Modificar usuario"
        echo "5) Bloquear usuario"
        echo "6) Desbloquear usuario"
        echo "7) Eliminar usuario"
        echo "8) Agregar usuario a grupo"
        echo "9) Retirar usuario de grupo"
        echo "0) Volver al menú principal"
        echo "============================================"
        read -rp "Opción: " opcion

        case "$opcion" in
            1) crear_usuarios ;;
            2) ver_info;;
            3) lista_usuarios ;;
            4) modificar_usuario ;;
            5) bloquear_usuario ;;
            6) desbloquear_usuario ;;
            7) eliminar_usuario ;;
            8) agregar_usuario_a_grupo ;;
            9) retirar_usuario_de_grupo ;;
            0) return ;;
            *) echo "Opción inválida." ;;
        esac
        pausar
    done
}

#===========================================================================================================================================================
