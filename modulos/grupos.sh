#! /bin/bash

#SCRIPT PARA LA ADMINISTRACION DE GRUPOS

#FUNCION PARA CREACION DE GRUPOS
crear_grupo(){

#BANDERA SI ES USUARIO ROOT
if ! requiere_root; then
	return 1
fi

local nombre_grupo

read -rp "Escriba nombre del nuevo grupo: " nombre_grupo

#VALIDACION DE CAMPO VACIO
   if [[ -z "$nombre_grupo" ]]; then
	echo "ERROR: ESTE CAMPO NO PUEDE QUEDAR VACIO"
	return 1
   fi

#VALIDACION GRUPO DUPLICADO
   if getent group "$nombre_grupo" &> /dev/null; then
	echo "ERROR: GRUPO '$nombre_grupo' YA EXISTE"
	return 1
   fi

#CREACION DEL NUEVO GRUPO
   if groupadd "$nombre_grupo" &> /dev/null; then
	echo "Grupo creado exitosamente"
	return 0
   else
	echo "No se pudo crear grupo. Verifique sus permisos de usuario"
	return 1
   fi


}
