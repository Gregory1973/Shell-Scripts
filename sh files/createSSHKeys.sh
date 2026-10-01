#!/bin/bash
# ----------------------------------------------------------------------------
# Script pour macOS : génère une passphrase aléatoire, crée une paire de clés SSH
# protégée par cette passphrase, puis sauvegarde le tout dans un fichier texte.
#
#
# author : Grégory C.
# mail : 
# version : 1.0 Septembre 2026
# ----------------------------------------------------------------------------
# Usage : ./createSSHKeys.sh [nom_de_la_cle] [email_ou_commentaire]

set -euo pipefail

# --- Paramètres ---
# Valeurs par défaut (utilisées si l'utilisateur ne saisit rien)
NOM_CLE_DEFAUT="id_ed25519_$(date +%Y%m%d_%H%M%S)"
COMMENTAIRE_DEFAUT="$(whoami)@$(hostname)"

# En mode terminal classique, on accepte encore les arguments ($1, $2).
# En double-clic (.command), il n'y a pas d'arguments : on les demande à l'utilisateur.
if [ -n "${1:-}" ]; then
    NOM_CLE="$1"
else
    read -r -p "Nom de la clé [$NOM_CLE_DEFAUT] : " SAISIE_NOM
    NOM_CLE="${SAISIE_NOM:-$NOM_CLE_DEFAUT}"
fi

if [ -n "${2:-}" ]; then
    COMMENTAIRE="$2"
else
    read -r -p "Commentaire/email [$COMMENTAIRE_DEFAUT] : " SAISIE_COMMENTAIRE
    COMMENTAIRE="${SAISIE_COMMENTAIRE:-$COMMENTAIRE_DEFAUT}"
fi

# 
DOSSIER_SSH="$HOME/.ssh"
# DOSSIER_SORTIE="$HOME/Desktop"
# Dossier de sortie = emplacement en cours, celui de ce fichier script
DOSSIER_SORTIE="$(dirname "$(realpath "$0")")"
CHEMIN_CLE="$DOSSIER_SSH/$NOM_CLE"
FICHIER_RECAP="$DOSSIER_SORTIE/${NOM_CLE}_infos.txt"

# Creation du dossier ssh s'il n'existe pas
mkdir -p "$DOSSIER_SSH"
# Affectation des droits sur le dossier ssh
chmod 700 "$DOSSIER_SSH"

# --- 1. Génération d'une passphrase aléatoire ---
# 6 mots aléatoires séparés par des tirets (facile à lire/retenir, forte entropie)
if command -v openssl >/dev/null 2>&1; then
    PASSPHRASE=$(openssl rand -base64 24 | tr -dc 'a-zA-Z0-9' | head -c 24)
else
    echo "Erreur : openssl n'est pas disponible." >&2
    exit 1
fi

# --- 2. Génération de la paire de clés SSH (ed25519, recommandé) ---
if [ -f "$CHEMIN_CLE" ]; then
    echo "Erreur : une clé nommée '$CHEMIN_CLE' existe déjà. Choisissez un autre nom." >&2
    exit 1
fi
# Génaration de la clef
ssh-keygen -t ed25519 \
    -f "$CHEMIN_CLE" \
    -N "$PASSPHRASE" \
    -C "$COMMENTAIRE" \
    -q
# Modification des droits sur l'emplacement des clés et la clef publique
chmod 600 "$CHEMIN_CLE"
chmod 644 "${CHEMIN_CLE}.pub"

# --- 3. Écriture du fichier récapitulatif ---
{
    echo "=== Informations clé SSH générée le $(date) ==="
    echo
    echo "--- Passphrase ---"
    echo "$PASSPHRASE"
    echo
    echo "--- Clé privée ($CHEMIN_CLE) ---"
    cat "$CHEMIN_CLE"
    echo
    echo "--- Clé publique (${CHEMIN_CLE}.pub) ---"
    cat "${CHEMIN_CLE}.pub"
    echo
    echo "ATTENTION : ce fichier contient une clé privée et sa passphrase en clair."
    echo "Conservez-le en lieu sûr puis supprimez-le de ce dossier."
} > "$FICHIER_RECAP"
# Droits sur le fichier récapitulatif
chmod 600 "$FICHIER_RECAP"

# --- 4. Affichage des valeurs des variables ---

echo "------------------------------------------------------------------------------"
echo "Nom de la clé par défaut       : $NOM_CLE_DEFAUT"
echo "Commentaire par défaut         : $COMMENTAIRE_DEFAUT"
echo "Nom de la clé                  : $NOM_CLE"
echo "Commentaire                    : $COMMENTAIRE"
echo "Dossier ssh                    : $DOSSIER_SSH"
echo "Dossier de sortie du fichier   : $DOSSIER_SORTIE"
echo "Emplacement des clés           : $CHEMIN_CLE"
echo "Fichier récapitulatif          : $FICHIER_RECAP"
echo "Mot de passe de la clef privée : $PASSPHRASE"
echo "------------------------------------------------------------------------------"


# --- 5. Fin du script ---
echo "✅ Terminé."
echo "Clé privée   : $CHEMIN_CLE"
echo "Clé publique : ${CHEMIN_CLE}.pub"
echo "Récapitulatif: $FICHIER_RECAP"
echo
echo "⚠️  Pensez à sécuriser puis supprimer le fichier récapitulatif une fois la passphrase enregistrée ailleurs."
echo
read -r -p "Appuyez sur Entrée pour fermer cette fenêtre..." _




