#! /bin/bash

#Script de herramientas administrativas de uso exclusivo para usuarios con privilegios 

registrar_bitacora(){

local msj="$1"
local timestamp="$(date '+%Y-%m-%d - %H:%M:%S')"

echo "$timestamp" - "$(whoami)" - "$msj" >> "$ARCHIVO_BITACORA"

}

pausar(){

echo
read -rp " Presione ENTER para continuar..."

}

requiere_root(){

if [[ "$ES_ROOT" != "si" ]]; then

	echo "Esta operacion requiere privilegios administrativos"
	return 1
fi
	return 0
}

