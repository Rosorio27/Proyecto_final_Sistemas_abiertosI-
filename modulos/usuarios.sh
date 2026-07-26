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
