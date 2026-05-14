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
# Usage : synchronise <dossier>
#    $1 : Nom du dossier à synchroniser /!\ il ne doit pas contenir d'espace
# perso : serveur webDAV défini dans rclone.conf
synchronise() {
  rclone sync -v --progress ~/$1 perso:/$1 --delete-before
}

# Programme principal
echo "======================== Sauvegarde de mon rpertoire /home sur serveur de o2switch ========================"
# Synchronisation de chaque dossier
afficher_texte "Documents"
synchronise Documents

afficher_texte "Boulot (sauvegarde secondaire)"
synchronise Boulot

afficher_texte "Images"
synchronise Images

afficher_texte "Musique"
synchronise Musique

afficher_texte "Vidéos"
synchronise Vidéos

afficher_texte "Sauvegarde des troussseaux avec tampon de date À VENIR"
