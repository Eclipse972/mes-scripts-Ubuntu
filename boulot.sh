#!/bin/bash
# sync_boulot.sh

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

synchronise Banque
synchronise Administratif
synchronise Supports
synchronise Pédagogie
synchronise Cours
synchronise Fablab
synchronise TopSolid

afficher_texte "Sauvegarde de Trouvail"
readonly TAMPON_DATE=$(date +'%Y-%m-%d')
rclone copyto -v --progress ~/Trouvail.kdbx perso:Trouvail_${TAMPON_DATE}.kdbx
