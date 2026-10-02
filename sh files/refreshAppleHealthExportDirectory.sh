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
# 2nd October 2026
#

set -euo pipefail

# Variable d'entrée
DIRECTORY_TO_DELETE="apple_health_export"
FILE_TO_DECOMPRESS="export.zip"

# Dossier contenant ce script (résolu en chemin absolu, même via un symlink)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

APP_H_DIR="$SCRIPT_DIR/$DIRECTORY_TO_DELETE"
ZIP_FILE="$SCRIPT_DIR/$FILE_TO_DECOMPRESS"

# 1. Effacer l'ancien répertoire DIRECTORY_TO_DELETE s'il existe
if [ -e "$APP_H_DIR" ]; then
    echo "Suppression de : $APP_H_DIR"
    rm -rf "$APP_H_DIR"
else
    echo "Aucun répertoire $DIRECTORY_TO_DELETE à supprimer."
fi

# 2. Vérifier que FILE_TO_DECOMPRESS est présent
if [ ! -f "$ZIP_FILE" ]; then
    echo "Erreur : fichier introuvable : $ZIP_FILE" >&2
    exit 1
fi

# 3. Décompresser data.zip dans le dossier du script
echo "Décompression de $ZIP_FILE vers : $SCRIPT_DIR"
unzip -o "$ZIP_FILE" -d "$SCRIPT_DIR"

# --- Fin du script ---
echo "✅ Terminé."
echo "⚠️  $DIRECTORY_TO_DELETE has been updated, $ZIP_FILE has been unziped"
read -r -p "Appuyez sur Entrée pour fermer cette fenêtre..." _