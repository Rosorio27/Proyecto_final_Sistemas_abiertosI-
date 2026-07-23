#! /bin/bash
RUTA_PRINCIPAL="$(dirname "$(realpath "$0")")"

#DECLARACION DE ARCHIVO DE CONFIGURACION
ARCHIVO_CONFIG="$RUTA_PRINCIPAL/configuracion/configuracion.conf"

#VALIDACION DEL ARCHIVO DE CONFIGURACION
if [[ ! -f "$ARCHIVO_CONFIG" ]];then

   echo "ERROR AL CARGAR ARCHIVO"
   exit 1

else
#Si el archivo existe carga las variable de entorno y comienza el script 
	source "$ARCHIVO_CONFIG"
fi

#DECLARACION DE RUTAS PRINCIPALES
RUTA_MODULOS="$RUTA_PRINCIPAL/modulos"
RUTA_REPORTES="$RUTA_PRINCIPAL/reportes"
RUTA_RESPALDOS="$RUTA_PRINCIPAL/respaldos"
RUTA_BITACORAS="$RUTA_PRINCIPAL/bitacoras"
RUTA_TEMPORALES="$RUTA_PRINCIPAL/temporales"
RUTA_DOCUMENTACION="$RUTA_PRINCIPAL/documentacion"

#ARREGLO RUTAS PRINCIPALES
CARPETAS_PRINCIPALES=("$RUTA_MODULOS" "$RUTA_REPORTES" "$RUTA_RESPALDOS" "$RUTA_BITACORAS" "$RUTA_TEMPORALES" "$RUTA_DOCUMENTACION")

#DECLARACION DE RUTA PARA LA BITACORA 
ARCHIVO_BITACORA="$RUTA_BITACORAS/bitacora_$(date +%Y-%m-%d).log"

#SOURCE PARA BITACORA
source "$RUTA_MODULOS/herramientas.sh"
#SOURCE PARA MODULO GRUPOS
source "$RUTA_MODULOS/grupos.sh"

#VERIFICACION DE LAS CARPETAS PRINCIPALES 
verificar_carpetas_principales(){
for carpeta in "${CARPETAS_PRINCIPALES[@]}"; do
	if [[ ! -d "$carpeta" ]]; then
		mkdir -p "$carpeta"
		echo "Carpeta creada con exito"
	fi
done

}
#VERIFICACION DE PRIVILEGIOS 
verificar_privilegios(){
if [[ $EUID -eq 0 ]]; then
	ES_ROOT="si"
else 
	ES_ROOT="no"
fi

}

#LLAMADO DE FUNCIONES
verificar_privilegios
verificar_carpetas_principales
registrar_bitacora "BIENVENIDO A LA BITACORA DE REGISTRO DEL SISTEMA"

#Header con informacion del sistema (punto 6 del proyecto)
mostrar_header(){
    clear
    echo "=========================================="
    echo " $NOMBRE_ORGANIZACION - $NOMBRE_SISTEMA"
    echo "=========================================="
    echo "Fecha        : $(date '+%d/%m/%Y')"
    echo "Hora         : $(date '+%H:%M:%S')"
    echo "Usuario      : $(whoami)"
    echo "Equipo       : $(hostname)"
    echo "Distribucion : $(lsb_release -ds 2>/dev/null || echo 'Desconocida')"
    echo "Espacio disp.: $(df -h / | awk 'NR==2 {print $4}')"
    echo "=========================================="
}

#Menu principal del sistema
menu_principal(){
    local opcion
    while true; do
        mostrar_header
        echo "1) Administracion de usuarios"
        echo "2) Administracion de grupos"
        echo "3) Administracion de carpetas"
        echo "4) Administracion de archivos"
        echo "5) Gestion de permisos"
        echo "6) Gestion de procesos"
        echo "7) Gestion de almacenamiento"
        echo "8) Configuracion del Shell"
        echo "9) Respaldos y restauracion"
        echo "10) Generacion de reportes"
        echo "11) Consultar bitacora"
        echo "12) Informacion del sistema"
        echo "0) Salir"
        echo "=========================================="
        read -rp "Seleccione una opcion: " opcion

        case "$opcion" in
            1) echo "Modulo de usuarios (en construccion)"; ver_miembros_grupos; registrar_bitacora "Acceso a modulo de usuarios"; read -rp "Presione Enter para continuar..." ;;
            2) echo "Modulo de grupos (en construccion)"; read -rp "Presione Enter para continuar..." ;;
            3) echo "Modulo de carpetas (en construccion)"; read -rp "Presione Enter para continuar..." ;;
            4) echo "Modulo de archivos (en construccion)"; read -rp "Presione Enter para continuar..." ;;
            5) echo "Modulo de permisos (en construccion)"; read -rp "Presione Enter para continuar..." ;;
            6) echo "Modulo de procesos (en construccion)"; read -rp "Presione Enter para continuar..." ;;
            7) echo "Modulo de almacenamiento (en construccion)"; read -rp "Presione Enter para continuar..." ;;
            8) echo "Configuracion del shell (en construccion)"; read -rp "Presione Enter para continuar..." ;;
            9) echo "Modulo de respaldos (en construccion)"; read -rp "Presione Enter para continuar..." ;;
            10) echo "Modulo de reportes (en construccion)"; read -rp "Presione Enter para continuar..." ;;
            11) cat "$ARCHIVO_BITACORA"; read -rp "Presione Enter para continuar..." ;;
            12) uname -a; read -rp "Presione Enter para continuar..." ;;
            0) registrar_bitacora "Salida del sistema"; echo "Saliendo del sistema..."; exit 0 ;;
            *) echo "Opcion invalida."; read -rp "Presione Enter para continuar..." ;;
        esac
    done
}

menu_principal
