#! /bin/bash
RUTA_PRINCIPAL="$(dirname "$(realpath "$0")")"

echo "La ruta base del proyecto es: ${RUTA_PRINCIPAL}"

ARCHIVO_CONFIG="$RUTA_PRINCIPAL/configuracion/configuracion.conf"


#si el archivo no existe: exit 1 y sale del script 
if [[ ! -f "$ARCHIVO_CONFIG" ]];then

   echo "ERROR AL CARGAR ARCHIVO"
   exit 1

else
#Si el archivo existe carga las variable de entorno y comienza el script 
	source "$ARCHIVO_CONFIG"

fi

#Parte del header: informacion principal del sistema
echo "$NOMBRE_ORGANIZACION - $NOMBRE_SISTEMA"

#DECLARACION DE RUTAS PRINCIPALES
RUTA_MODULOS="$RUTA_PRICIPAL/modulos"
RUTA_REPORTES="$RUTA_PRINCIPAL/reportes"
RUTA_RESPALDOS="$RUTA_PRINCIPAL/respaldos"
RUTA_BITACORAS="$RUTA_PRINCIPAL/bitacoras"
RUTA_TEMPORALES="$RUTA_PRINCIPAL/temporales"
RUTA_DOCUMENTACION="$RUTA_PRINCIPAL/documentacion"

#ARREGLO RUTAS PRINCIPALES
CARPETAS_PRINCIPALES("RUTA_MODULOS" "RUTA_REPORTES" "RUTA_RESPALDOS" "RUTA_BITACORAS" "RUTA_TEMPORALES" "RUTA_DOCUMENTACION")

#VERIFICACION DE LAS CARPETAS PRINCIPALES 
verificar_carpetas_principales(){
for carpeta in "${CARPETAS_PRINCIPALES[@]}"; do
	if [[ ! -d "$carpeta" ]]; then
		mkdir -p "$carpeta"
		echo "Carpeta creada con exito"
	fi
done
}




