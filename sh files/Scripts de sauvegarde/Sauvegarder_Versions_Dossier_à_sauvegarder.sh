#!/bin/bash

# ============================================================
# SAUVEGARDE VERSIONNÉE macOS AVEC RSYNC
# ============================================================
#
# Fonctionnalités :
#   - Snapshots versionnés
#   - rsync --link-dest
#   - Mode simulation
#   - Journalisation
#   - Vérification du disque
#   - Vérification de l'espace disponible
#   - Conservation des N dernières sauvegardes
#
# ============================================================
# by Grégory C.
# 6th October 2026

# Arrêt du script si une commande échoue
set -euo pipefail

# ------------------------------------------------------------
# CONFIGURATION
# ------------------------------------------------------------

# Dossier à sauvegarder
SOURCE_DIR=""
#"/Users/gregory/Mon Drive/OpenClassrooms_Data_Analyst"

# Dossier de destination
DESTINATION_DIR="DOSSIER_DE_DESTINATION"

# Nombre de sauvegardes à conserver
KEEP=30

# Espace minimum souhaité sur le disque Samsung (en Go)
MIN_FREE_GB=10

# Mode simulation
# true  = aucune modification
# false = sauvegarde réelle
DRY_RUN=false


# ------------------------------------------------------------
# VARIABLES
# ------------------------------------------------------------

DATE=$(date +"%Y-%m-%d_%H-%M-%S")

DISK="$(dirname "$(realpath "$0")")"
DEST_DIR="$DISK/$DESTINATION_DIR/$(basename "$SOURCE_DIR")"

NEW_BACKUP="$DEST_DIR/$DATE"

LOG_DIR="$DEST_DIR/_logs"

LOG_FILE="$LOG_DIR/backup_$DATE.log"

# ------------------------------------------------------------
# FONCTION D'AFFICHAGE
# ------------------------------------------------------------

log()
{
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}


# ------------------------------------------------------------
# DÉBUT
# ------------------------------------------------------------

mkdir -p "$LOG_DIR"

echo ""
echo "============================================================"
echo "        SAUVEGARDE VERSIONNÉE macOS"
echo "============================================================"
echo ""

log "Début de la sauvegarde."


# ------------------------------------------------------------
# VÉRIFICATION DU DISQUE DE SAUVEGARDE
# ------------------------------------------------------------

if [ ! -d "$DISK" ]; then

    log "ERREUR : le disque n'est pas monté."

    echo ""
    echo "Le disque doit être disponible ici :"
    echo "$DISK"
    echo ""

    exit 1

fi

log "Disque détecté."


# ------------------------------------------------------------
# VÉRIFICATION DU DOSSIER SOURCE
# ------------------------------------------------------------

if [ ! -d "$SOURCE_DIR" ]; then

    log "ERREUR : le dossier source n'existe pas."

    echo "$SOURCE_DIR"

    exit 1

fi

log "Dossier source OK : $SOURCE_DIR"


# ------------------------------------------------------------
# CRÉATION DU DOSSIER DESTINATION
# ------------------------------------------------------------

if [ "$DRY_RUN" = false ]; then

    mkdir -p "$DEST_DIR"

fi


# ------------------------------------------------------------
# VÉRIFICATION DE L'ESPACE DISPONIBLE
# ------------------------------------------------------------

FREE_KB=$(df -k "$DISK" | tail -1 | awk '{print $4}')

FREE_GB=$((FREE_KB / 1024 / 1024))

log "Espace disponible : ${FREE_GB} Go"

if [ "$FREE_GB" -lt "$MIN_FREE_GB" ]; then

    log "ERREUR : espace disque insuffisant."

    echo ""
    echo "Espace disponible : ${FREE_GB} Go"
    echo "Minimum requis     : ${MIN_FREE_GB} Go"
    echo ""

    exit 1

fi


# ------------------------------------------------------------
# RECHERCHE DE LA DERNIÈRE SAUVEGARDE
# ------------------------------------------------------------

LAST_BACKUP=""

if [ -d "$DEST_DIR" ]; then

    LAST_BACKUP=$(find "$DEST_DIR" \
        -mindepth 1 \
        -maxdepth 1 \
        -type d \
        | grep -v "/_logs$" \
        | sort \
        | tail -n 1)

fi


if [ -n "$LAST_BACKUP" ]; then

    log "Dernière sauvegarde : $LAST_BACKUP"

else

    log "Aucune sauvegarde précédente."

fi


# ------------------------------------------------------------
# AFFICHAGE DU MODE
# ------------------------------------------------------------

echo ""

if [ "$DRY_RUN" = true ]; then

    log "MODE SIMULATION ACTIVÉ"
    log "Aucune modification ne sera effectuée."

else

    log "MODE SAUVEGARDE RÉELLE"

fi

echo ""

log "Source      : $SOURCE_DIR"
log "Destination : $NEW_BACKUP"


# ------------------------------------------------------------
# CRÉATION DU NOUVEAU SNAPSHOT
# ------------------------------------------------------------

if [ "$DRY_RUN" = false ]; then

    mkdir -p "$NEW_BACKUP"

fi


# ------------------------------------------------------------
# CONSTRUCTION DE LA COMMANDE RSYNC
# ------------------------------------------------------------

RSYNC_OPTIONS="-avh --delete --progress"

if [ "$DRY_RUN" = true ]; then

    RSYNC_OPTIONS="$RSYNC_OPTIONS --dry-run"

fi


# ------------------------------------------------------------
# SAUVEGARDE
# ------------------------------------------------------------

echo ""

if [ -n "$LAST_BACKUP" ]; then

    log "Utilisation de --link-dest."

    rsync $RSYNC_OPTIONS \
        --link-dest="$LAST_BACKUP" \
        "$SOURCE_DIR/" \
        "$NEW_BACKUP/" \
        2>&1 | tee -a "$LOG_FILE"

else

    log "Première sauvegarde : copie complète."

    rsync $RSYNC_OPTIONS \
        "$SOURCE_DIR/" \
        "$NEW_BACKUP/" \
        2>&1 | tee -a "$LOG_FILE"

fi


RSYNC_STATUS=${PIPESTATUS[0]}


# ------------------------------------------------------------
# VÉRIFICATION DU RÉSULTAT RSYNC
# ------------------------------------------------------------

echo ""

if [ "$RSYNC_STATUS" -eq 0 ]; then

    log "rsync terminé avec succès."

else

    log "ERREUR : rsync s'est terminé avec le code $RSYNC_STATUS."

    exit "$RSYNC_STATUS"

fi


# ------------------------------------------------------------
# NETTOYAGE DES ANCIENNES SAUVEGARDES
# ------------------------------------------------------------

if [ "$DRY_RUN" = true ]; then

    log "Simulation : aucune ancienne sauvegarde supprimée."

else

    log "Vérification du nombre de sauvegardes."

    BACKUPS=$(find "$DEST_DIR" \
        -mindepth 1 \
        -maxdepth 1 \
        -type d \
        | grep -v "/_logs$" \
        | sort)

    BACKUP_COUNT=$(echo "$BACKUPS" | grep -c .)

    log "Nombre de sauvegardes : $BACKUP_COUNT"

    if [ "$BACKUP_COUNT" -gt "$KEEP" ]; then

        DELETE_COUNT=$((BACKUP_COUNT - KEEP))

        log "Suppression de $DELETE_COUNT ancienne(s) sauvegarde(s)."

        echo "$BACKUPS" \
            | head -n "$DELETE_COUNT" \
            | while read OLD_BACKUP
              do

                  log "Suppression : $OLD_BACKUP"

                  rm -rf "$OLD_BACKUP"

              done

    else

        log "Aucune ancienne sauvegarde à supprimer."

    fi

fi


# ------------------------------------------------------------
# RAPPORT FINAL
# ------------------------------------------------------------

echo ""
echo "============================================================"
echo "                    RAPPORT"
echo "============================================================"
echo ""

log "Sauvegarde terminée."

if [ "$DRY_RUN" = true ]; then

    log "ATTENTION : ceci était une SIMULATION."

    echo ""
    echo "Pour effectuer réellement la sauvegarde :"
    echo ""
    echo "DRY_RUN=false"
    echo ""

else

    log "Nouvelle sauvegarde : $NEW_BACKUP"

fi

echo ""
echo "Espace disponible sur Samsung : ${FREE_GB} Go"
echo ""
echo "Journal :"
echo "$LOG_FILE"
echo ""

echo "============================================================"

# --- Fin du script ---
echo "✅ Terminé."
read -r -p "Appuyez sur Entrée pour fermer cette fenêtre..." _
