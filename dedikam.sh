#!/bin/bash
# dedikam.sh

# Constantes
readonly SOURCE=/home/christophe
readonly DESTINATION=dk002673@rsync.dedikam.com:/files
readonly TAMPON_DATE=$(date +'%Y-%m-%d')

# Fonction pour afficher le texte
# $1 : texte a afficher
afficher_texte() {
    echo ""
    echo $1
    echo "--------------------------------------------------------------------------------"
}

# Fonction de Sauvegarde (SOURCE/ et DESTINATION/ intégrés)
# $1 suffixe de la source
# $2 suffixe de la destination qui peut être vide
synchronise() {
    rsync -av --progress --delete $exclusions $SOURCE/$1 $DESTINATION/$2
}

echo "=== Sauvegarde vers serveur Dedikam ==="

afficher_texte "Documents non sensibles"
echo "Finances"
synchronise Documents/Finances Documents/Finances
synchronise Documents/Humour Documents/Humour
synchronise Documents/Loisirs Documents/Loisirs
synchronise Documents/Notices  Documents/Notices
synchronise Documents/Sacha Documents/Sacha
synchronise Documents/Vacances  Documents/Vacances
synchronise Documents/Voiture Documents/Voiture

afficher_texte "dossier Photos"
synchronise Images/ Photos/

afficher_texte "Sauvegarde des troussseaux avec tampon de date"
synchronise Trousseau.kdbx Trousseau_$TAMPON_DATE.kdbx
synchronise Trouvail.kdbx Trouvail_$TAMPON_DATE.kdbx
synchronise satoshis.kdbx satoshis_$TAMPON_DATE.kdbx

afficher_texte "Boulot (sauvegarde secondaire)"
synchronise Boulot

