#!/bin/bash
# sync_boulot.sh

# Source la fonction copie_trousseau
source "$(dirname "$0")/copie_trousseau.sh"

# Limitation des ressources réseau pour connexion 4G lente
export RCLONE_TRANSFERS=1
export RCLONE_CHECKERS=4
export RCLONE_BWLIMIT=500k

# Fonction pour afficher le texte
# $1 : texte a afficher
afficher_texte() {
    echo ""
    echo $1
    echo "--------------------------------------------------------------------------------"
}

# Fonction de synchronisation d'un dossier
# $1 : dossier source
# $2 : dossier destination (optionnel, utilise $1 par défaut)
synchronise() {
    afficher_texte $1
    rclone sync -v --progress ~/Boulot/$1/ boulot:$1/
}

# programme principal
echo "=== Synchronisation vers serveur cloud du boulot ==="

readonly TAMPON_DATE=$(date +'%Y-%m-%d')
afficher_texte "Sauvegarde des trousseaux avec tampon de date"
copie_trousseau Trouvail ~ boulot

synchronise Banque
synchronise Administratif
synchronise Supports
synchronise Pédagogie
synchronise Cours
synchronise Fablab
synchronise TopSolid

