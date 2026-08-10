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

# Copie un trousseau keepass UNIQUEMENT si son contenu a changé depuis le dernier backup
#
# 	$1 : fichier sans l'extension kdbx
#
# Stratégie :
# 	1. Calculer le hash SHA256 du fichier local
# 	2. Récupérer le fichier hash (.sha256) stocké sur le cloud (quelques octets)
# 	3. Comparer les hashs — si identiques, on saute la sauvegarde
# 	4. Si différent, copier le .kdbx avec tampon de date ET mettre à jour le .sha256 sur le cloud
#
# Remarques :
# 	- Le .sha256 est créé automatiquement lors de la première sauvegarde
# 	- Une seule sauvegarde par jour : si le script tourne deux fois, seul le .kdbx
# 	  est écrasé (même nom), ce qui est le comportement voulu
#
# Usage : copie_trousseau <nom_sans_extension>
copie_trousseau() {
	local nom="$1"
	local fichier_local=~/${nom}.kdbx
	local fichier_hash_local="/tmp/${nom}.sha256"
	local cible_datee="perso:${nom}_${TAMPON_DATE}.kdbx"
	local cible_hash="perso:${nom}.sha256"

	# --- Calcul du hash du fichier local ---
	local hash_local
	hash_local=$(sha256sum "$fichier_local" | awk '{print $1}')

	# --- Récupération du hash distant (fichier léger de quelques octets) ---
	# Échoue silencieusement si le .sha256 n'existe pas encore (premier lancement)
	local hash_distant=""
	rclone copyto "$cible_hash" "$fichier_hash_local" --quiet 2>/dev/null
	if [ -f "$fichier_hash_local" ]; then
		hash_distant=$(cat "$fichier_hash_local")
		rm -f "$fichier_hash_local"
	fi

	# --- Comparaison ---
	if [ "$hash_local" = "$hash_distant" ]; then
		echo "  [SKIP] $nom : inchangé depuis le dernier backup"
		return
	fi

	# --- Modification détectée → sauvegarde ---
	echo "  [SAVE] $nom : modification détectée, sauvegarde en cours..."
	rclone copyto -v --progress "$fichier_local" "$cible_datee"

	# Mise à jour du hash distant pour la prochaine comparaison
	echo "$hash_local" | rclone rcat --quiet "$cible_hash"
}

# Programme principal
echo "======================== Sauvegarde de mon répertoire /home sur serveur de o2switch ========================"
afficher_texte "Sauvegarde des trousseaux avec tampon de date"
copie_trousseau Trousseau
copie_trousseau Trouvail
copie_trousseau satoshis

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
