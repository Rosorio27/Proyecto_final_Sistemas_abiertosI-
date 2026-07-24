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
	registrar_bitacora "Se creo el grupo '$nombre_grupo'"
	return 0
   else
	echo "No se pudo crear grupo. Verifique sus permisos de usuario"
	return 1
   fi

}

#FUNCION PARA LISTAR LOS GRUPOS EXISTENTES
ver_grupos(){
echo  "GRUPOS DE TRABAJO:"
local filtrado

filtrado="$(grep -E "^(desarrollo|infraestructura|seguridad|soporte)" /etc/group | cut -d: -f1)"
	if [[ -z "$filtrado" ]]; then 
		echo "Error al leer los grupos" 
	else 

		echo "$filtrado" | while read -r grupo; do 
			echo " - $grupo"
	done

	fi
}

#FUNCION PARA VER LOS MIEMBROS 
ver_miembros_grupos(){

local nombre_grupo

read -rp "Nombre del grupo a consultar: " nombre_grupo

#VALLIDAD CAMPO VACIO 
if [[ -z "$nombre_grupo" ]]; then
	echo "ERROR: ESTO CAMPO NO PUEDE QUEDAR VACIO"
	return 1
fi

#VALIDAD SI GRUPO NO EXISTE
if ! getent group "$nombre_grupo" &> /dev/null; then 
	echo "ERROR: GRUPO NO EXISTE"
	return 1
fi

local mmiembros
miembros="$(getent group "$nombre_grupo" | cut -d: -f4)"
echo "INTEGRANTES DE '$nombre_grupo'"

#VALIDACION DE MIEMBRE DEL GRUPO
if [[ -z "$miembreso" ]]; then
	echo "ERROR: NO SE MUESTRAN MIEMBROS PARA ESTE GRUPO"
else
	echo "$miembros" | tr ',' '\n' | while read -r usuario; do
		echo   " -$usuario"
	done
fi

}



