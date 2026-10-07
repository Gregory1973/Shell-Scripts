#!/bin/bash
# ----------------------------------------------------------------------------
# Script pour macOS : génère une paire de clés SSH, avec ou sans passphrase
# (option true/false), puis sauvegarde le tout dans un fichier texte.
#
# author : Grégory C.
# mail : 
# version : 1.1 Octobre 2026
# ----------------------------------------------------------------------------
# Usage : ./createSSHKeys.sh [nom_de_la_cle] [email_ou_commentaire] [true|false]
#   - 3e argument : true  -> la clé est protégée par une passphrase aléatoire
#                   false -> la clé est générée sans passphrase
#   - En double-clic (.command), sans arguments : les valeurs sont demandées.

set -euo pipefail

# --- Paramètres ---
# Valeurs par défaut (utilisées si l'utilisateur ne saisit rien)
NOM_CLE_DEFAUT="id_ed25519_$(date +%Y%m%d_%H%M%S)"
COMMENTAIRE_DEFAUT="$(whoami)@$(hostname)"
PASSPHRASE_DEFAUT="false"   # true = avec passphrase, false = sans passphrase

# En mode terminal classique, on accepte encore les arguments ($1, $2, $3).
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

# Option passphrase : true ou false
if [ -n "${3:-}" ]; then
    AVEC_PASSPHRASE="$3"
else
    read -r -p "Protéger la clé par une passphrase ? [true/false] [$PASSPHRASE_DEFAUT] : " SAISIE_PASSPHRASE
    AVEC_PASSPHRASE="${SAISIE_PASSPHRASE:-$PASSPHRASE_DEFAUT}"
fi
# Normalisation (on accepte aussi TRUE/True/1, FALSE/False/0)
case "$(echo "$AVEC_PASSPHRASE" | tr '[:upper:]' '[:lower:]')" in
    true|1|oui|yes)   AVEC_PASSPHRASE="true" ;;
    false|0|non|no)   AVEC_PASSPHRASE="false" ;;
    *)
        echo "Erreur : l'option passphrase doit valoir 'true' ou 'false' (reçu : '$AVEC_PASSPHRASE')." >&2
        exit 1
        ;;
esac

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

# --- 1. Génération d'une passphrase aléatoire (si activée) ---
# 6 mots aléatoires séparés par des tirets (facile à lire/retenir, forte entropie)
if [ "$AVEC_PASSPHRASE" = "true" ]; then
    if command -v openssl >/dev/null 2>&1; then
        PASSPHRASE=$(openssl rand -base64 24 | tr -dc 'a-zA-Z0-9' | head -c 24)
    else
        echo "Erreur : openssl n'est pas disponible." >&2
        exit 1
    fi
else
    PASSPHRASE=""
fi

# --- 2. Génération de la paire de clés SSH (ed25519, recommandé) ---
if [ -f "$CHEMIN_CLE" ]; then
    echo "Erreur : une clé nommée '$CHEMIN_CLE' existe déjà. Choisissez un autre nom." >&2
    exit 1
fi
# Génaration de la clef (-N "" = sans passphrase)
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
    echo "--- Option passphrase ---"
    if [ "$AVEC_PASSPHRASE" = "true" ]; then
        echo "Activée (true)"
        echo
        echo "--- Passphrase ---"
        echo "$PASSPHRASE"
    else
        echo "Désactivée (false) : la clé n'est PAS protégée par passphrase."
    fi
    echo
    echo "--- Clé privée ($CHEMIN_CLE) ---"
    cat "$CHEMIN_CLE"
    echo
    echo "--- Clé publique (${CHEMIN_CLE}.pub) ---"
    cat "${CHEMIN_CLE}.pub"
    echo
    echo "ATTENTION : ce fichier contient une clé privée (et la passphrase en clair si activée)."
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
echo "Passphrase activée             : $AVEC_PASSPHRASE"
echo "Dossier ssh                    : $DOSSIER_SSH"
echo "Dossier de sortie du fichier   : $DOSSIER_SORTIE"
echo "Emplacement des clés           : $CHEMIN_CLE"
echo "Fichier récapitulatif          : $FICHIER_RECAP"
if [ "$AVEC_PASSPHRASE" = "true" ]; then
    echo "Mot de passe de la clef privée : $PASSPHRASE"
else
    echo "Mot de passe de la clef privée : (aucun — passphrase désactivée)"
fi
echo "------------------------------------------------------------------------------"


# --- 5. Fin du script ---
echo "✅ Terminé."
echo "Clé privée   : $CHEMIN_CLE"
echo "Clé publique : ${CHEMIN_CLE}.pub"
echo "Récapitulatif: $FICHIER_RECAP"
echo
if [ "$AVEC_PASSPHRASE" = "true" ]; then
    echo "⚠️  Pensez à sécuriser puis supprimer le fichier récapitulatif une fois la passphrase enregistrée ailleurs."
else
    echo "⚠️  Clé générée SANS passphrase : toute personne accédant à votre machine peut l'utiliser."
fi
echo
read -r -p "Appuyez sur Entrée pour fermer cette fenêtre..." _