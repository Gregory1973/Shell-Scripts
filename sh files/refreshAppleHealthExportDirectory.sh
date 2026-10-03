#!/bin/bash
#
# refreshAppleHealthExportDirectory.sh
# Efface le répertoire DIRECTORY_TO_DELETE situé dans le même répertoire que ce script,
# puis décompresse FILE_TO_DECOMPRESS dans ce même dossier.
# Compatible macOS (bash 3.2 natif).
#
# Usage : bash refreshAppleHealthExportDirectory.sh  (ou chmod +x puis ./refreshAppleHealthExportDirectory.sh)
#
# by Grégory C.
# 3rd October 2026
#

set -euo pipefail

# Variable d'entrée
DIRECTORY_DATA_SOURCE="/Users/gregory/Downloads"
DIRECTORY_TO_DELETE="apple_health_export"
FILE_TO_DECOMPRESS="export.zip"

# Dossier contenant ce script (résolu en chemin absolu, même via un symlink)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

# Déplacement du fichier originial des données 
# Vérification de l'existence du fichier
if [ ! -f "$DIRECTORY_DATA_SOURCE/$FILE_TO_DECOMPRESS" ]; then
    echo "⚠️ Erreur : fichier introuvable : $DIRECTORY_DATA_SOURCE/$FILE_TO_DECOMPRESS" >&2
    read -r -p "Appuyez sur Entrée pour fermer cette fenêtre..." _
    exit 1
fi
# Déplacement du fichier
mv "$DIRECTORY_DATA_SOURCE/$FILE_TO_DECOMPRESS" "$SCRIPT_DIR/$FILE_TO_DECOMPRESS"


APP_H_DIR="$SCRIPT_DIR/$DIRECTORY_TO_DELETE"
ZIP_FILE="$SCRIPT_DIR/$FILE_TO_DECOMPRESS"

# 1. Effacer l'ancien répertoire DIRECTORY_TO_DELETE s'il existe
#if [ -e "$APP_H_DIR" ]; then
#    echo "Suppression de : $APP_H_DIR"
#    rm -rf "$APP_H_DIR"
#else
#    echo "Aucun répertoire $DIRECTORY_TO_DELETE à supprimer."
#    read -r -p "Appuyez sur Entrée pour fermer cette fenêtre..." _
#fi

# 2. Vérifier que FILE_TO_DECOMPRESS est présent
if [ ! -f "$ZIP_FILE" ]; then
    echo "⚠️ Erreur : fichier introuvable : $ZIP_FILE" >&2
    read -r -p "Appuyez sur Entrée pour fermer cette fenêtre..." _
    exit 1
fi

# 3. Décompresser data.zip dans le dossier du script
echo "Décompression de $ZIP_FILE vers : $SCRIPT_DIR"
unzip -o "$ZIP_FILE" -d "$SCRIPT_DIR"

# --- Fin du script ---
echo "✅ Terminé."
echo "⚠️  $DIRECTORY_TO_DELETE has been updated, $ZIP_FILE has been unziped"
read -r -p "Appuyez sur Entrée pour fermer cette fenêtre..." _



