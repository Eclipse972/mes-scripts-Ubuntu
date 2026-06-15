#!/usr/bin/env python3
"""
Vérifie la cohérence entre les annotations @route des contrôleurs
et les routes réellement définies dans le fichier de routes (Slim).

Ce script est générique : il lit un fichier "verifier-routes.conf" à la
racine du projet courant pour connaître les chemins spécifiques au
projet.

Format attendu dans les docblocks des contrôleurs :
    /**
     * ...
     * @route /chemin/complet
     * ...
     */
    public function maMethode(...)

Installation :
    Placer ce script une fois dans un dossier de scripts (ex: ~/bin/),
    le nommer verifier-routes.py, le rendre exécutable, et s'assurer
    que ce dossier est dans le PATH.

Utilisation :
    Depuis la racine d'un projet contenant un fichier verifier-routes.conf :
        verifier-routes.py
"""

import re
import sys
import configparser
from pathlib import Path

CONFIG_FILENAME = "verifier-routes.conf"


# ----------------------------------------------------------------------
# Configuration
# ----------------------------------------------------------------------

def load_config() -> tuple[Path, Path]:
    """Lit le fichier de config à la racine du projet courant.

    Format attendu (INI) :

        [paths]
        routes = src/config/routes.php
        controleurs = src/Controleur
    """
    config_path = Path.cwd() / CONFIG_FILENAME

    if not config_path.is_file():
        print(f"❌ Erreur : fichier '{CONFIG_FILENAME}' introuvable dans {Path.cwd()}")
        print()
        print(f"Crée un fichier {CONFIG_FILENAME} à la racine du projet, par exemple :")
        print()
        print("    [paths]")
        print("    routes = src/config/routes.php")
        print("    controleurs = src/Controleur")
        sys.exit(1)

    parser = configparser.ConfigParser()
    parser.read(config_path, encoding="utf-8")

    try:
        routes_value = parser.get("paths", "routes")
        controleurs_value = parser.get("paths", "controleurs")
    except (configparser.NoSectionError, configparser.NoOptionError) as exc:
        print(f"❌ Erreur dans {CONFIG_FILENAME} : {exc}")
        print()
        print("Le fichier doit contenir une section [paths] avec les clés"
              " 'routes' et 'controleurs', par exemple :")
        print()
        print("    [paths]")
        print("    routes = src/config/routes.php")
        print("    controleurs = src/Controleur")
        sys.exit(1)

    routes_file = Path.cwd() / routes_value
    controleur_dir = Path.cwd() / controleurs_value

    if not routes_file.is_file():
        print(f"❌ Erreur : fichier de routes introuvable : {routes_file}")
        sys.exit(1)

    if not controleur_dir.is_dir():
        print(f"❌ Erreur : dossier des contrôleurs introuvable : {controleur_dir}")
        sys.exit(1)

    return routes_file, controleur_dir


# ----------------------------------------------------------------------
# Helpers
# ----------------------------------------------------------------------

def normalize(path: str) -> str:
    if not path:
        return "/"
    if not path.startswith("/"):
        path = "/" + path
    if path != "/" and path.endswith("/"):
        path = path[:-1]
    return path


def short_class(fqcn: str) -> str:
    return fqcn.split("\\")[-1]


# ----------------------------------------------------------------------
# 1. Extraction des routes définies dans le fichier de routes
# ----------------------------------------------------------------------

ROUTE_RE = re.compile(
    r"""
    \$(?:app|group)->get\(\s*
    ['"](?P<path>[^'"]*)['"]\s*,\s*
    \[\s*(?P<class>[A-Za-z0-9_\\]+)::class\s*,\s*
    ['"](?P<method>[A-Za-z0-9_]+)['"]\s*\]
    """,
    re.VERBOSE,
)

GROUP_START_RE = re.compile(r"\$app->group\(\s*['\"](?P<prefix>[^'\"]*)['\"]")


def extract_defined_routes(content: str) -> dict[str, str]:
    routes = {}
    current_prefix = ""

    for line in content.splitlines():
        group_match = GROUP_START_RE.search(line)
        if group_match and "$app->group(" in line:
            current_prefix = group_match.group("prefix")
            continue

        match = ROUTE_RE.search(line)
        if match:
            path = match.group("path")
            ctrl = short_class(match.group("class"))
            method = match.group("method")

            if "$group->get(" in line:
                full_path = current_prefix + path
            else:
                full_path = path

            key = f"{ctrl}::{method}"
            routes[key] = normalize(full_path)

    return routes


# ----------------------------------------------------------------------
# 2. Extraction des @route dans les contrôleurs
# ----------------------------------------------------------------------

ROUTE_DOC_RE = re.compile(r"@route\s+(\S+)")
FUNCTION_RE = re.compile(r"function\s+([A-Za-z0-9_]+)\s*\(")


def extract_doc_routes(controleur_dir: Path) -> dict[str, str]:
    doc_routes = {}

    for php_file in controleur_dir.rglob("*.php"):
        class_name = php_file.stem
        pending_route = None

        for line in php_file.read_text(encoding="utf-8").splitlines():
            route_match = ROUTE_DOC_RE.search(line)
            if route_match:
                pending_route = normalize(route_match.group(1))
                continue

            if pending_route is not None:
                func_match = FUNCTION_RE.search(line)
                if func_match:
                    method = func_match.group(1)
                    key = f"{class_name}::{method}"
                    doc_routes[key] = pending_route
                    pending_route = None

    return doc_routes


# ----------------------------------------------------------------------
# 3. Comparaison
# ----------------------------------------------------------------------

def main() -> None:
    routes_file, controleur_dir = load_config()

    defined_routes = extract_defined_routes(routes_file.read_text(encoding="utf-8"))
    doc_routes = extract_doc_routes(controleur_dir)

    print(f"Projet                              : {Path.cwd()}")
    print(f"Fichier de routes                   : {routes_file}")
    print(f"Dossier des contrôleurs             : {controleur_dir}")
    print()
    print(f"Routes définies dans routes.php    : {len(defined_routes)}")
    print(f"Routes @route dans les contrôleurs : {len(doc_routes)}")
    print()

    # Index inversé : chemin -> clé(s) Controleur::methode définies dans routes.php
    defined_by_path: dict[str, list[str]] = {}
    for key, path in defined_routes.items():
        defined_by_path.setdefault(path, []).append(key)

    errors = []
    handled_doc_keys = set()

    for key, doc_path in sorted(doc_routes.items()):
        real_path = defined_routes.get(key)

        if real_path == doc_path:
            continue  # cohérent

        ctrl = key.split("::")[0]

        # Cherche si ce même chemin est défini dans routes.php, mais pour
        # une autre méthode du même contrôleur -> méthode incorrecte.
        candidates = [
            k for k in defined_by_path.get(doc_path, [])
            if k.split("::")[0] == ctrl
        ]

        if candidates:
            for candidate in candidates:
                errors.append(
                    f'[MÉTHODE INCORRECTE] {key} => @route="{doc_path}" '
                    f'correspond à "{candidate}" dans routes.php, pas à "{key}"'
                )
                handled_doc_keys.add(candidate)
            handled_doc_keys.add(key)
            continue

        if real_path is None:
            errors.append(f'[MANQUANT dans routes.php] {key} => @route="{doc_path}"')
        else:
            errors.append(
                f'[INCOHÉRENT] {key} => @route="{doc_path}" vs routes.php="{real_path}"'
            )
        handled_doc_keys.add(key)

    for key, real_path in sorted(defined_routes.items()):
        if key not in doc_routes and key not in handled_doc_keys:
            errors.append(f'[ABSENT du docblock] {key} => routes.php="{real_path}"')

    for e in errors:
        print(e)

    print()
    if not errors:
        print("✅ Tout est cohérent.")
    else:
        print(f"❌ {len(errors)} incohérence(s) trouvée(s).")


if __name__ == "__main__":
    main()
