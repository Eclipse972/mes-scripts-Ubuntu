#!/bin/bash
# Sauvegarde des dossiers importants du répertoire home sur cloud o2switch

readonly TAMPON_DATE=$(date +'%Y-%m-%d')

# Limitation des ressources réseau pour connexion 4G lente
export RCLONE_TRANSFERS=1
export RCLONE_CHECKERS=4
export RCLONE_BWLIMIT=500k

# Fonction pour afficher un texte
# $1 : texte a afficher
afficher_texte() {
	echo ""
	echo $1
	echo "--------------------------------------------------"
}

# Fonction de synchronisation de dossier
# 	$1 : source
#
# Usage : synchronise_dossier <source>
#
# Remarques :
# 	- perso : serveur webDAV défini dans rclone.conf
# 	- source ne doit pas contenir d'espaces
#	- rclone sync ne permet pas de synchroniser de fichier, il faut utiliser rclone copy à la place
synchronise_dossier() {
	rclone sync -v --progress ~/$1 perso:/$1 --delete-before
}

# Source la fonction copie_trousseau
source "$(dirname "$0")/copie_trousseau.sh"

# Programme principal
echo "======================== Sauvegarde de mon répertoire /home sur serveur de o2switch ========================"
afficher_texte "Sauvegarde des trousseaux avec tampon de date"
copie_trousseau Trousseau ~ perso
copie_trousseau Trouvail ~ perso
copie_trousseau satoshis ~ perso

# sauvegarde des dossiers non sensibles
afficher_texte "Finances"
synchronise_dossier Documents/Finances

afficher_texte "Loisirs"
synchronise_dossier Documents/Loisirs

afficher_texte "Vacances"
synchronise_dossier Documents/Vacances

afficher_texte "Voiture"
synchronise_dossier Documents/Voiture

afficher_texte "Images"
synchronise_dossier Images

afficher_texte "Musique"
synchronise_dossier Musique

afficher_texte "Vidéos"
synchronise_dossier Vidéos

afficher_texte "Boulot (sauvegarde secondaire)"
synchronise_dossier Boulot
