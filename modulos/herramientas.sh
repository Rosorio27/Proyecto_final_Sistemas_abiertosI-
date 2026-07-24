#! /bin/bash

#Script de herramientas administrativas de uso exclusivo para usuarios con privilegios 

#REGISTRO DIARIO DE INGRESOS Y SALIDAS DEL SISTEMA
registrar_bitacora(){

local msj="$1"
local timestamp="$(date '+%Y-%m-%d - %H:%M:%S')"

echo "$timestamp" - "$(whoami)" - "$msj" >> "$ARCHIVO_BITACORA"

}

#PAUSAR LA PANTALLA
pausar(){

echo
read -rp " Presione ENTER para continuar..."

}

#VALIDACION PARA ACCIONES ADMINISTRATIVAS
requiere_root(){

if [[ "$ES_ROOT" != "si" ]]; then

	echo "Esta operacion requiere privilegios administrativos"
	return 1
fi
	return 0
}

#VALIDACION DE CONFIRMACION SI/NO
confirmar_accion(){

local mensaje="$1"
local respuesta

read -rp "$mensaje" (s/n): " respuesta

if [[ "$respuesta" == "s " ]] || [[ "$respuesta" == "S" ]]; then

	return 0
else
	echo " Cancelando operacion" 
	return 1
fi

}

