#!/bin/bash

# by Grégory C.
# 6th October 2026

# Arrêt du script si une commande échoue
set -euo pipefail

# Dossier de destination
DESTINATION_DIRECTORY="DOSSIER_DE_DESTINATION"

# Liste des dossiers à sauvegarder
directories_to_backup=(
    #"/Users/gregory/Mon Drive/OpenClassrooms_Data_Analyst"
)


# Fonction pour copier un dossier source vers une destination sur la clé USB
backup_directory_to_usb_key() {
    local SOURCE_DIR="$1"
    local DESTINATION_DIR="$2"

    # Récupère automatiquement le chemin (où se trouve ce script)
    local USB_DIR="$(dirname "$(realpath "$0")")"

    # Nom du dossier de destination
    local DEST_DIR="$USB_DIR/$DESTINATION_DIR/$(basename "$SOURCE_DIR")"

    # Vérifie que le dossier source existe
    if [ ! -d "$SOURCE_DIR" ]; then
        echo "Erreur : Le dossier source n'existe pas : $SOURCE_DIR"
        exit 1
    fi

    # Vérifie que la clé USB est accessible
    if [ ! -d "$USB_DIR" ]; then
        echo "Erreur : Impossible de trouver le chemin de la clé USB."
        exit 1
    fi

    # Crée le dossier $DESTINATION_DIR s'il n'existe pas
    mkdir -p "$USB_DIR/$DESTINATION_DIR"

    # Commande rsync pour copier et conserver les anciennes versions
    rsync -av --delete --progress --backup --backup-dir="$DEST_DIR/../Versions/$(date +%Y-%m-%d_%H-%M-%S)" "$SOURCE_DIR/" "$DEST_DIR/"

    echo "Copie terminée avec succès vers : $DEST_DIR"
}

# Boucle pour sauvegarder chaque dossier
for dir in "${directories_to_backup[@]}"; do
    backup_directory_to_usb_key "$dir" "$DESTINATION_DIRECTORY"
done

# --- Fin du script ---
echo "✅ Terminé."
read -r -p "Appuyez sur Entrée pour fermer cette fenêtre..." _