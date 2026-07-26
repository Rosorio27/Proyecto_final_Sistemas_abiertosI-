#! /bin/bash

#SCRIPT PARA LA ADMINISTRACION DE GRUPOS

#FUNCION PARA CREACION DE GRUPOS
#==========================================================================================================================================================
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
#===========================================================================================================================================================

#FUNCION PARA LISTAR LOS GRUPOS EXISTENTES
#===========================================================================================================================================================
ver_grupos(){
    echo "GRUPOS DE TRABAJO:"
    echo "--- Grupos obligatorios de la organización ---"

    for grupo in "${GRUPOS_PRINCIPALES[@]}"; do
        if getent group "$grupo" &> /dev/null; then
            echo " - $grupo"
        else
            echo " - $grupo (no creado todavía)"
        fi
    done

    echo "--- Grupos adicionales creados ---"

    local encontrados=0

    while read -r linea; do
        local nombre="$(echo "$linea" | cut -d: -f1)"
        local gid="$(echo "$linea" | cut -d: -f3)"

        if [[ "$gid" -ge 1000 ]] && [[ "$nombre" != "nogroup" ]]; then

            # ¿Este nombre también es un usuario real del sistema?
            # Si existe en /etc/passwd, es un grupo privado de usuario, se salta.
            if getent passwd "$nombre" &> /dev/null; then
                continue
            fi

            local es_principal=0
            for principal in "${GRUPOS_PRINCIPALES[@]}"; do
                if [[ "$nombre" == "$principal" ]]; then
                    es_principal=1
                fi
            done

            if [[ "$es_principal" -eq 0 ]]; then
                echo " - $nombre"
                encontrados=1
            fi
        fi
    done < /etc/group

    if [[ "$encontrados" -eq 0 ]]; then
        echo "  (No hay grupos adicionales creados)"
    fi
}


#===========================================================================================================================================================

#FUNCION PARA VER LOS MIEMBROS
#===========================================================================================================================================================
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

local miembros
miembros="$(getent group "$nombre_grupo" | cut -d: -f4)"
echo "INTEGRANTES DE '$nombre_grupo'"

#VALIDACION DE MIEMBROS DEL GRUPO
if [[ -z "$miembros" ]]; then
	echo "ERROR: NO SE MUESTRAN MIEMBROS PARA ESTE GRUPO"
else
	echo "$miembros" | tr ',' '\n' | while read -r usuario; do
		echo   " -$usuario"
	done
fi

}
#===========================================================================================================================================================

#FUNCION PARA ELIMINAR GRUPOS
#===========================================================================================================================================================

eliminar_grupo() {
    if ! requiere_root; then
        return 1
    fi

    local nombre_grupo
    read -rp "Nombre del grupo a eliminar: " nombre_grupo

    # VALIDACION DE CAMPO VACIO
    if [[ -z "$nombre_grupo" ]]; then
        echo "ERROR: ESTE CAMPO NO PUEDE QUEDAR VACIO"
        return 1
    fi

    # VALIDACION GRUPO EXISTENTE
    if ! getent group "$nombre_grupo" &> /dev/null; then
        echo "ERROR: GRUPO NO EXISTE EN SISTEMA"
        return 1
    fi

    # VALIDACION NO ELIMINAR GRUPOS PRINCIPALES DE LA ORGANIZACIÓN
    for grupo_protegido in "${GRUPOS_PRINCIPALES[@]}"; do
        if [[ "$nombre_grupo" == "$grupo_protegido" ]]; then
            echo "ERROR: NO PUEDES ELIMINAR ESTE GRUPO (es obligatorio del sistema)"
            return 1
        fi
    done

    # VALIDACION: ¿ES EL GRUPO PRIMARIO DE ALGÚN USUARIO?
    # Buscamos el GID de este grupo, y revisamos si algún usuario
    # en /etc/passwd tiene ese mismo GID como grupo principal (campo 4)
    local gid_grupo
    gid_grupo="$(getent group "$nombre_grupo" | cut -d: -f3)"

    local usuario_afectado
    usuario_afectado="$(getent passwd | awk -F: -v gid="$gid_grupo" '$4 == gid {print $1}')"

    if [[ -n "$usuario_afectado" ]]; then
        echo "ERROR: '$nombre_grupo' es el grupo principal del usuario '$usuario_afectado'."
        echo "       No se puede eliminar mientras ese usuario tenga este grupo asignado."
        return 1
    fi

    # ADVERTENCIA ANTES DE APLICAR ACCION
    if ! confirmar_accion "¿Está seguro que desea eliminar este grupo?"; then
        return 1
    fi

    # ELIMINAR EL GRUPO PERMANENTEMENTE
    if groupdel "$nombre_grupo" &> /dev/null; then
        echo "HA ELIMINADO EL GRUPO: '$nombre_grupo'"
        registrar_bitacora "Se elimino el grupo '$nombre_grupo'"
        return 0
    else
        echo "ERROR: no se pudo eliminar el grupo."
        echo "       Verifique que no tenga usuarios ni dependencias asociadas."
        return 1
    fi
}
#===========================================================================================================================================================
menu_grupos() {
    local opcion
    while true; do
        clear
        echo "============================================"
        echo " ADMINISTRACIÓN DE GRUPOS"
        echo "============================================"
        echo "1) Crear grupo"
        echo "2) Ver grupos"
        echo "3) Ver integrantes de un grupo"
        echo "4) Eliminar grupo"
        echo "0) Volver al menú principal"
        echo "============================================"
        read -rp "Opción: " opcion

        case "$opcion" in
            1) crear_grupo ;;
            2) ver_grupos ;;
            3) ver_miembros_grupos ;;
            4) eliminar_grupo ;;
            0) return ;;
            *) echo "Opción inválida." ;;
        esac
        pausar
    done
}



