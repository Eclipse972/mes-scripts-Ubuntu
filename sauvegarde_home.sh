#!/bin/bash
# Sauvegarde des dossiers importants du répertoire home sur cloud o2switch

# Fonction pour afficher un texte
# $1 : texte a afficher
afficher_texte() {
	echo ""
	echo $1
	echo "--------------------------------------------------"
}

# Fonction de synchronisation
# 	$1 : Nom du dossier source /!\ il ne doit pas contenir d'espace
#	$2 : dossier destination (optionnel, utilise $1 par défaut)
#
# Usage : synchronise <source> <destination>
#
# Remarques :
# 	- perso : serveur webDAV défini dans rclone.conf
# 	- source et destination ne doivent pas contenir d'espaces
synchronise() {
	rclone sync -v --progress ~/$1 perso:/${2:-$1} --delete-before
}

# Programme principal
echo "======================== Sauvegarde de mon répertoire /home sur serveur de o2switch ========================"
# Synchronisation de chaque dossier
afficher_texte "Finances"
synchronise Documents/Finances

afficher_texte "Loisirs"
synchronise Documents/Loisirs

afficher_texte "Vacances"
synchronise Documents/Vacances

afficher_texte "Voiture"
synchronise Documents/Voiture

afficher_texte "Images"
synchronise Images

afficher_texte "Musique"
synchronise Musique

afficher_texte "Vidéos"
synchronise Vidéos

readonly TAMPON_DATE=$(date +'%Y-%m-%d')
afficher_texte "Sauvegarde des troussseaux avec tampon de date"
synchronise Trousseau.kdbx Trousseau_$TAMPON_DATE.kdbx
synchronise Trouvail.kdbx Trouvail_$TAMPON_DATE.kdbx
synchronise satoshis.kdbx satoshis_$TAMPON_DATE.kdbx

afficher_texte "Boulot (sauvegarde secondaire)"
synchronise Boulot
