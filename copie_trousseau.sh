#!/bin/bash
# Fonction utilitaire de copie de trousseau KeePass avec détection de modification
#
# Ce fichier est destiné à être sourcé par d'autres scripts :
#   source "$(dirname "$0")/copie_trousseau.sh"
#
# Il nécessite que TAMPON_DATE soit défini dans le script appelant.

# Copie un trousseau KeePass UNIQUEMENT si son contenu a changé depuis le dernier backup
#
# 	$1 : nom du trousseau sans extension (ex: Trousseau)
# 	$2 : chemin du dossier source sur le disque (ex: ~ ou ~/Boulot)
# 	$3 : alias du serveur distant défini dans rclone.conf (ex: perso ou boulot)
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
# 	  est écrasé (même nom de fichier), ce qui est le comportement voulu
#
# Usage : copie_trousseau <nom> <chemin_source> <serveur_rclone>
copie_trousseau() {
	local nom="$1"
	local chemin_source="$2"
	local serveur="$3"

	local fichier_local="${chemin_source}/${nom}.kdbx"
	local fichier_hash_local="/tmp/${nom}.sha256"
	local cible_datee="${serveur}:${nom}_${TAMPON_DATE}.kdbx"
	local cible_hash="${serveur}:${nom}.sha256"

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
