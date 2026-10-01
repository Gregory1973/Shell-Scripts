#!/bin/bash
# ----------------------------------------------------------------------------
# Utilitaire de création et d'initialisation de fichier de script de commande
# 
# author : Grégory C.
# mail : 
# version : 1.0 Septembre 2026
# 
# ----------------------------------------------------------------------------

# Arrêt du script si une commande échoue
set -euo pipefail

# Annonce en début de l'execution du script
echo "Création et initialisation du fichier de script de commande"

# Récupération de l'emplacement en cours
CURRENT_DIRECTORY="$(dirname "$(realpath "$0")")"
echo $CURRENT_DIRECTORY

# Créer le fichier script_vYYYYMMDD_HHmmss.sh
FILE_NAME="script_v$(date +%Y%m%d_%H%M%S)"
touch "$CURRENT_DIRECTORY/$FILE_NAME.sh"

# Écrire le contenu dans le fichier
cat > $CURRENT_DIRECTORY/$FILE_NAME.sh << EOF
#!/bin/bash
# Arrêt du script si une commande échoue
set -euo pipefail

# Script : "$FILE_NAME"
# Insérez votre code ici

# --- Fin du script ---
echo "✅ Terminé."
read -r -p "⚠️  Appuyez sur Entrée pour fermer cette fenêtre..." _

EOF

# Rendre le fichier exécutable
chmod +x $CURRENT_DIRECTORY/$FILE_NAME.sh

# Renommer le fichier en .command
mv $CURRENT_DIRECTORY/$FILE_NAME.sh $CURRENT_DIRECTORY/$FILE_NAME.command


# --- Fin du script ---
echo "✅ Terminé."
echo "⚠️  $CURRENT_DIRECTORY/$FILE_NAME.command a été créé."
read -r -p "Appuyez sur Entrée pour fermer cette fenêtre..." _
