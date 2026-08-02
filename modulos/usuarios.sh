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

echo
echo "Formato permitido: solo minúsculas, números, '-' o '_'."
echo "Debe iniciar con una letra minúscula o '_'."
echo "Ejemplos válidos: carlos, admin_2, _soporte"
echo ""

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

    # VERIFICACION DE LA CARPETA HOME
    local home_usuario="/home/$nombre_usuario"

    	if [[ -d "$home_usuario" ]]; then
        	echo "Directorio personal creado: $home_usuario"
        	echo "Permisos del home: $(stat -c '%A' "$home_usuario")"
    	else
        	echo "ADVERTENCIA: el usuario se creó, pero no se detectó su directorio personal"
    	fi

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

echo
echo "Información del usuario: $nombre_usuario"
echo

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

#VER GRUPOS A LOS QUE PERTENECE
echo
echo "Grupos a los que pertenece:"
id -nG "$nombre_usuario" | tr ' ' '\n' | while read -r grupo; do
    echo "  - $grupo"
done

echo
echo "Fecha de creación / último cambio de clave:"
chage -l "$nombre_usuario" 2>/dev/null | head -1

}
#==========================================================================================================================================================

#FUNCION PARA LISTAR TODOS LOS USUARIOS
lista_usuarios(){

 echo "Lista de usuarios de la organización"
    echo "----------------------------------------"

    local encontrados=0
    local usuario_actual="$(whoami)"

    while IFS=: read -r nombre password uid gid comentario home shell; do

        # Solo usuarios reales (UID >= 1000), sin contar al que opera el sistema
        if [[ "$uid" -ge 1000 ]] && [[ "$nombre" != "$usuario_actual" ]] && [[ "$nombre" != "nobody" ]]; then

            local nombre_grupo
            nombre_grupo="$(getent group "$gid" | cut -d: -f1)"

            echo " - $nombre  |  grupo: $nombre_grupo  |  shell: $shell"
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
echo "3) Fecha de expiración de la cuenta"

local opcion_modificar
read -rp "Opción: " opcion_modificar

case "$opcion_modificar" in

1)
            local nuevo_comentario
            read -rp "Nuevo comentario (ejemplo: Juan Perez - Ventas): " nuevo_comentario
            if usermod -c "$nuevo_comentario" "$nombre_usuario" &> /dev/null; then
                echo "Comentario actualizado correctamente"
                registrar_bitacora "Se modifico el comentario del usuario '$nombre_usuario'"
            else
                echo "ERROR: NO SE PUDO ACTUALIZAR"
            fi
            ;;
        2)
            local nueva_shell
            read -rp "Nueva shell (ejemplo: /bin/bash): " nueva_shell
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
        3)
            local nueva_fecha
            read -rp "Nueva fecha de expiración (YYYY-MM-DD): " nueva_fecha

            if [[ ! "$nueva_fecha" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
                echo "ERROR: FORMATO DE FECHA INVALIDO (use YYYY-MM-DD)"
                return 1
            fi

            if usermod -e "$nueva_fecha" "$nombre_usuario" &> /dev/null; then
                echo "Fecha de expiración actualizada correctamente"
                registrar_bitacora "Se modifico fecha de expiracion del usuario '$nombre_usuario' a '$nueva_fecha'"
            else
                echo "ERROR: NO SE PUDO ACTUALIZAR (verifique el formato de fecha)"
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
        echo "Usuario $nombre_usuario bloqueado correctamente"
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
        echo "ERROR: EL USUARIO $nombre_usuario NO EXISTE"
        return 1
fi

#DESBLOQUEAR A UN USUARIO
if usermod -U "$nombre_usuario" &> /dev/null; then
        echo "Usuario $nombre_usuario desbloqueado correctamente"
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
