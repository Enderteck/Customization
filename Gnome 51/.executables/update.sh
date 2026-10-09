#!/bin/bash
set -e

# --- 1. Demande du mot de passe ---
echo "🔑 Le script nécessite les droits administrateur."
echo "Veuillez entrer votre mot de passe pour continuer."
sudo -v
clear 

# --- Fonction confirmation avec délai ---
confirm() {
    local prompt="$1"
    local timeout=6
    echo -n "$prompt (O,Y/N, Oui dans ${timeout}s): "
    read -t $timeout -n 1 answer || true
    echo ""  # retour ligne propre
    if [[ "$answer" =~ ^[YyOo]$ ]] || [[ -z "$answer" ]]; then
        return 0  # oui
    else
        return 1  # non
    fi
}

# --- 2. Démarrage ---
echo "🚀 Démarrage de la mise à jour..."
echo "----------------------------------------------------"
echo ""

# --- 3. Mise à jour des paquets RPM ---
echo "🔄 Mise à jour des paquets système avec DNF..."
sudo dnf upgrade -y --refresh
echo ""

# --- 4. Mise à jour Flatpak ---
echo "📦 Mise à jour des applications Flatpak..."
flatpak update -y
echo ""

# --- 6. Mises à jour complètes si -all ---
if [[ "$1" == "-all" ]]; then
    echo "----------------------------------------------------"
    echo "🔧 Mode complet (-all) activé."
    echo ""

    # Hanabi
    if confirm "Voulez-vous mettre à jour l'extension Hanabi ?"; then
        echo "🔄 Mise à jour Hanabi..."
        TEMP_DIR=$(mktemp -d)
        cd "$TEMP_DIR"
        git clone https://github.com/jeffshee/gnome-ext-hanabi.git -b gnome-51
        cd gnome-ext-hanabi
        ./run.sh install
        cd
        rm -rf "$TEMP_DIR"
        echo "✅ Hanabi mis à jour."
        echo ""
    else
        echo "⏭️  Hanabi ignoré."
    fi

    # Gale
    if confirm "Voulez-vous mettre à jour Gale ?"; then
echo "🔄 Mise à jour Gale..."
        REPO="Kesomannen/gale"
        DL_DIR="/tmp"
        INSTALLER="dnf"
        ASSET_URL=$(curl -s "https://api.github.com/repos/${REPO}/releases/latest" \
          | grep "browser_download_url" \
          | grep -E "x86_64.*\.rpm\"" \
          | cut -d '"' -f 4 \
          | head -n 1) # Ajout de head -n 1 par sécurité

        if [[ -z "$ASSET_URL" ]]; then
            echo "❌ Impossible de trouver un RPM dans la dernière release."
        else
            FILENAME=$(basename "$ASSET_URL")
            echo "🔽 Téléchargement de ${FILENAME}..."
            curl -L -o "${DL_DIR}/${FILENAME}" "$ASSET_URL"
            sudo ${INSTALLER} install -y "${DL_DIR}/${FILENAME}"
            rm -f "${DL_DIR}/${FILENAME}"
            echo "✅ Gale mis à jour."
        fi
        echo ""
    else
        echo "⏭️  Gale ignoré."
    fi


#
# Thème Gnome/GTK
#
    

    if confirm "Voulez-vous mettre à jour le thème Gnome (Orchis) ?"; then
        # --- Configuration ---
	# Modifiez ces variables pour changer le thème ou les options d'installation.
	GNOME_THEME_URL="https://github.com/vinceliuice/orchis-theme.git"
	GNOME_THEME_INSTALL_OPTIONS="-t orange -c dark -s standard -i fedora -l -f --tweaks solid black submenu"
	GNOME_THEME_SOURCE_DIR="$HOME/Orchis-theme-source"
	GNOME_THEME_COLOR_FILE_PATH="gtkrc.sh"
	GNOME_THEME_PATCHING_SCRIPT_PATH="$HOME/Git/Gnome-Theming/Gnome\ 51/.executables"
	
	# --- Début du script ---
	echo "🎨 Démarrage de l'installation du thème GTK Orchis."

	# 1. TÉLÉCHARGEMENT
	echo "🌐 Clonage de la dernière version du thème depuis GitHub..."
	
	# On supprime l'ancien dossier source s'il existe pour garantir une version propre.
	if [ -d "$GNOME_THEME_SOURCE_DIR" ]; then
	    echo "   - Ancien dossier source trouvé. Suppression..."
	    rm -rf "$GNOME_THEME_SOURCE_DIR"
	fi
	
	git clone "$GNOME_THEME_URL" "$GNOME_THEME_SOURCE_DIR"
	cd "$GNOME_THEME_SOURCE_DIR"
	echo "✅ Téléchargement terminé."
	echo "" # Ligne vide pour l'aération
	
	# 2. MODIFICATION DE LA COULEUR
	echo "🖌️  Modification de la couleur orange par défaut dans les fichiers sources..."
	# La commande 'sed' cherche et remplace les codes couleurs directement dans le fichier SCSS.
	# L'option '-i' modifie le fichier sur place.
	sed -i 's/#F57C00/#FF7800/g' "$GNOME_THEME_COLOR_FILE_PATH"
	sed -i 's/#FB8C00/#FF7800/g' "$GNOME_THEME_COLOR_FILE_PATH"
	echo "✅ Couleurs modifiées en '#FF7800'."
	echo ""
	
	# 3. INSTALLATION DU THÈME
	echo "🚀 Lancement de l'installation du thème avec les options spécifiées..."
	echo "   Options: $GNOME_THEME_INSTALL_OPTIONS"
	./install.sh $GNOME_THEME_INSTALL_OPTIONS
	echo "✅ Thème installé avec succès."
	echo ""
	
	# 4. PATCH POUR GNOME 50
	echo "Application du patch de compatibilité"
	cd "GNOME_THEME_PATCHING_SCRIPT_PATH"
	python ./Patchorchis.py
	echo "✅ Thème patché avec succès."
	
	# 4. NETTOYAGE
	echo "🧹 Nettoyage des fichiers source téléchargés..."
	cd "$HOME"
	rm -rf "$GNOME_THEME_SOURCE_DIR"
	echo "✅ Dossier source supprimé."
	echo ""
	
	# --- Fin du script ---
	echo "🎉 Terminé ! Le thème Orchis est installé et personnalisé."
        echo ""
    else
        echo "⏭️  Thème d'icônes ignoré."
    fi

#
# Thème D'icônes
#

    if confirm "Voulez-vous mettre à jour le thème d'icônes (Tela Circle) ?"; then
        # --- Configuration ---
	# Modifiez ces variables pour changer le thème ou les options d'installation.
	ICON_THEME_REPO_URL="https://github.com/vinceliuice/Tela-circle-icon-theme.git"
	ICON_THEME_INSTALL_OPTIONS="-c orange"
	ICON_THEME_SOURCE_DIR="$HOME/Tela-circle-icon-theme-source"
	CUSTOM_ICONS_DIR="$HOME/Git/Gnome-Theming/IconOverrides/scalable"
	INSTALLED_ICON_THEME_DIR="$HOME/.local/share/icons"
	
	# --- Début du script ---
	echo "🎨 Démarrage de la mise à jour du thème d'icônes Tela Circle."
	
	# 1. TÉLÉCHARGEMENT
	echo "🌐 Clonage de la dernière version du thème depuis GitHub..."
	
	# On supprime l'ancien dossier source s'il existe pour garantir une version propre.
	if [ -d "$ICON_THEME_SOURCE_DIR" ]; then
	    echo "   - Ancien dossier source trouvé. Suppression..."
	    rm -rf "$ICON_THEME_SOURCE_DIR"
	fi
	
	git clone "$ICON_THEME_REPO_URL" "$ICON_THEME_SOURCE_DIR"
	cd "$ICON_THEME_SOURCE_DIR"
	echo "✅ Téléchargement terminé."
	echo "" # Ligne vide pour l'aération
	
	# 2. MODIFICATION DE LA COULEUR
	echo "🖌️  Modification de la couleur orange par défaut dans le script d'installation..."
	# La commande 'sed' cherche et remplace le code couleur directement dans le fichier.
	# L'option '-i' modifie le fichier sur place.
	sed -i 's/#ff9800/#ff7800/g' install.sh
	echo "✅ Couleur modifiée de '#ff9800' à '#ff7800'."
	echo ""
	
	# 3. INSTALLATION DU THÈME
	echo "🚀 Lancement de l'installation du thème avec les options spécifiées..."
	echo "   Options: $ICON_THEME_INSTALL_OPTIONS"
	./install.sh $ICON_THEME_INSTALL_OPTIONS
	echo "✅ Thème installé avec succès."
	echo ""
	
	# 4. AJOUT DES ICÔNES PERSONNELLES
	echo "✨ Copie des icônes personnalisées..."
	
	# On vérifie que le dossier des icônes personnalisées existe avant de copier.
	if [ -d "$CUSTOM_ICONS_DIR" ]; then
	    # Copie dans les deux variantes du thème orange (clair et sombre)
	    cp -r "$CUSTOM_ICONS_DIR"/* "$INSTALLED_ICON_THEME_DIR/Tela-circle-orange-dark/scalable/"
	    cp -r "$CUSTOM_ICONS_DIR"/* "$INSTALLED_ICON_THEME_DIR/Tela-circle-orange/scalable/"
	    echo "✅ Icônes personnelles ajoutées."
	else
	    # Affiche un avertissement si le dossier n'est pas trouvé.
	    echo "⚠️  Attention : Le dossier d'icônes personnalisées '$CUSTOM_ICONS_DIR' n'a pas été trouvé. Cette étape est ignorée."
	fi
	echo ""
	
	# 5. NETTOYAGE
	echo "🧹 Nettoyage des fichiers source téléchargés..."
	cd "$HOME"
	rm -rf "$ICON_THEME_SOURCE_DIR"
	echo "✅ Dossier source supprimé."
	echo ""
	
	# --- Fin du script ---
	echo "🎉 Terminé ! Votre thème d'icônes est à jour et personnalisé."
        echo ""
    else
        echo "⏭️  Thème Gnome ignoré."
    fi
fi

# --- Mise à jour base applications ---
echo "⚙️  Actualisation de la base de données des applications..."
update-desktop-database -q ~/.local/share/applications
echo ""
echo "----------------------------------------------------"
echo "✅ Mise à jour terminée avec succès ! 🎉"
exit 0
