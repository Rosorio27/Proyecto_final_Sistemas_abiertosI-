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
