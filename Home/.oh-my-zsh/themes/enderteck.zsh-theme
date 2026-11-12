# ==============================================================================
#  enderteck.zsh-theme — thème oh-my-zsh personnalisé
# ==============================================================================
#
#  Rendu visé (terminal de 89 colonnes, soit des lignes de 88 : COLUMNS - 1) :
#
#  ┌[Ghostty]─[~/Git/Customization]───────────────────────────────[user@FrameworkLaptop12]┐
#  └[20:40:30]─[git: on main 🖉]─>                                   >─[jeu. 12 nov.]─[⌁|=87%]┘
#
#  Couleurs :
#     bleu   → crochets [ ], traits ─ et coins ┌ ┐ └ ┘
#     jaune  → tout le texte placé entre crochets
#     rouge  → les chevrons >
#
#  Organisation du fichier (où modifier quoi) :
#     1. RÉGLAGES            → icônes, formats de date/heure, crochets, nom du terminal
#     2. COULEURS            → variables PR_BLUE, PR_YELLOW, PR_RED…
#     3. CARACTÈRES DE CADRE → ─ ┌ ┐ └ ┘ (avec repli si le terminal n'est pas en UTF-8)
#     4. NOM DU TERMINAL     → détection automatique (Ghostty, Kitty, iTerm2…)
#     5. BATTERIE            → lecture du niveau et de l'état de charge
#     6. GIT                 → préfixe et icônes de statut
#     7. theme_precmd        → exécutée avant CHAQUE prompt : calcule tout ce qui est
#                              dynamique (largeur du terminal, nombre de ─, git, batterie…)
#     8. PROMPT / RPROMPT / PS2 (assemblage final)
#
#  Astuce de débogage : `print -P -- "$PR_LINE1"` affiche la 1re ligne du prompt.
# ==============================================================================


# ------------------------------------------------------------------------------
# 1. RÉGLAGES
# ------------------------------------------------------------------------------

# Crochets. Leur largeur est lue automatiquement pour le calcul des ─ : on peut
# donc les changer librement (ex. "(" et ")", ou "⟦" et "⟧").
THEME_LB="["
THEME_RB="]"

# Titre affiché en haut à gauche. Vide = détection automatique (section 4).
# Pour le forcer : THEME_TERMINAL_NAME="Ghostty"
THEME_TERMINAL_NAME=""

# Formats d'heure et de date (syntaxe strftime ; %f = jour du mois sans zéro,
# extension de zsh). La date suit la langue du système (LC_TIME) :
# en fr_FR.UTF-8, « %a %f %b » donne « jeu. 12 nov. ».
THEME_TIME_FORMAT='%H:%M'
THEME_DATE_FORMAT='%a %f %b'

# Icône placée juste avant le pourcentage quand la batterie est EN CHARGE.
# Alternatives : '⚡' (emoji, occupe 2 colonnes)   '↯'   '+'   '⌁'
THEME_BATTERY_CHARGING_ICON='⌁|='

# Icônes de statut Git (affichées après le nom de la branche).
# Alternatives possibles :
#   ajouté    : ✚ + ⊕        modifié : 🖉 ✎ ~ !        supprimé : × ⌫ ⊖ −
#   renommé   : ➜ » ⇄        conflit : ═ ≠ !           non suivi : ? ◌ …
THEME_GIT_ICON_ADDED='✚'        # fichier ajouté à l'index (git add)
THEME_GIT_ICON_MODIFIED='🖉'     # fichier modifié
THEME_GIT_ICON_DELETED='×'      # fichier supprimé
THEME_GIT_ICON_RENAMED='➜'      # fichier renommé
THEME_GIT_ICON_UNMERGED='═'     # conflit de fusion
THEME_GIT_ICON_UNTRACKED='?'    # fichier non suivi


# ------------------------------------------------------------------------------
# 2. COULEURS
# ------------------------------------------------------------------------------

# Nécessaire pour que le prompt fonctionne (substitutions dans PROMPT).
setopt prompt_subst

autoload -Uz colors && colors
autoload -Uz add-zsh-hook
zmodload zsh/terminfo 2>/dev/null
zmodload zsh/langinfo 2>/dev/null

# PR_<COULEUR> = gras + couleur ; PR_LIGHT_<COULEUR> = couleur normale.
# (typeset -g : obligatoire, oh-my-zsh charge les thèmes depuis une fonction)
for color in RED GREEN YELLOW BLUE MAGENTA CYAN WHITE GREY; do
  typeset -g PR_$color="%{$terminfo[bold]$fg[${(L)color}]%}"
  typeset -g PR_LIGHT_$color="%{$fg[${(L)color}]%}"
done
PR_NO_COLOUR="%{$terminfo[sgr0]%}"

# Raccourcis utilisés partout : « crochet ouvrant bleu + texte en jaune »
# puis « crochet fermant bleu ». Tout segment s'écrit ${PR_OPEN}texte${PR_CLOSE}.
PR_OPEN="${PR_BLUE}${THEME_LB}${PR_YELLOW}"
PR_CLOSE="${PR_BLUE}${THEME_RB}"


# ------------------------------------------------------------------------------
# 3. CARACTÈRES DE CADRE
# ------------------------------------------------------------------------------

if [[ "${langinfo[CODESET]}" = UTF-8 ]]; then
  PR_SET_CHARSET=""
  PR_HBAR="─"
  PR_ULCORNER="┌"
  PR_LLCORNER="└"
  PR_LRCORNER="┘"
  PR_URCORNER="┐"
else
  # Repli pour les terminaux non UTF-8 : jeu de caractères alternatif (ACS).
  typeset -g -A altchar
  set -A altchar ${(s..)terminfo[acsc]}
  PR_SET_CHARSET="%{$terminfo[enacs]%}"
  PR_SHIFT_IN="%{$terminfo[smacs]%}"
  PR_SHIFT_OUT="%{$terminfo[rmacs]%}"
  PR_HBAR="${PR_SHIFT_IN}${altchar[q]:--}${PR_SHIFT_OUT}"
  PR_ULCORNER="${PR_SHIFT_IN}${altchar[l]:--}${PR_SHIFT_OUT}"
  PR_LLCORNER="${PR_SHIFT_IN}${altchar[m]:--}${PR_SHIFT_OUT}"
  PR_LRCORNER="${PR_SHIFT_IN}${altchar[j]:--}${PR_SHIFT_OUT}"
  PR_URCORNER="${PR_SHIFT_IN}${altchar[k]:--}${PR_SHIFT_OUT}"
fi


# ------------------------------------------------------------------------------
# 4. NOM DU TERMINAL (titre en haut à gauche)
# ------------------------------------------------------------------------------
# Détection, dans l'ordre :
#   1. variables d'environnement propres à chaque émulateur (GHOSTTY_RESOURCES_DIR…)
#   2. TERM_PROGRAM, puis TERM (ex. « xterm-ghostty »)
#   3. remontée de l'arbre des processus jusqu'au premier ancêtre qui n'est pas un shell
#   4. à défaut, la valeur de $TERM
# Exécutée UNE SEULE FOIS au chargement du thème (pas à chaque prompt).
# Pour ajouter un terminal : une ligne dans le tableau ci-dessous
# (clé en minuscules = valeur de TERM_PROGRAM ou nom du processus).

typeset -gA _enderteck_terminals
_enderteck_terminals=(
  'ghostty'               'Ghostty'
  'kitty'                 'Kitty'
  'wezterm'               'WezTerm'
  'wezterm-gui'           'WezTerm'
  'alacritty'             'Alacritty'
  'foot'                  'Foot'
  'konsole'               'Konsole'
  'gnome-terminal'        'GNOME Terminal'
  'gnome-terminal-server' 'GNOME Terminal'
  'kgx'                   'GNOME Console'
  'ptyxis'                'Ptyxis'
  'ptyxis-agent'          'Ptyxis'
  'tilix'                 'Tilix'
  'terminator'            'Terminator'
  'xfce4-terminal'        'Xfce Terminal'
  'lxterminal'            'LXTerminal'
  'xterm'                 'XTerm'
  'urxvt'                 'URxvt'
  'rxvt-unicode'          'URxvt'
  'st'                    'st'
  'iterm.app'             'iTerm2'
  'apple_terminal'        'Terminal'
  'vscode'                'VS Code'
  'hyper'                 'Hyper'
  'warpterminal'          'Warp'
  'windows-terminal'      'Terminal Windows'
  'tmux'                  'Tmux'
)

function _enderteck_terminal_name {
  local key="" cand

  # 0. Nom forcé dans les réglages
  if [[ -n $THEME_TERMINAL_NAME ]]; then
    print -r -- "$THEME_TERMINAL_NAME"
    return
  fi

  # 1. Variables propres à chaque émulateur
  if   [[ -n $GHOSTTY_RESOURCES_DIR ]];                    then key=ghostty
  elif [[ -n $KITTY_WINDOW_ID ]];                          then key=kitty
  elif [[ -n $WEZTERM_EXECUTABLE || -n $WEZTERM_PANE ]];   then key=wezterm
  elif [[ -n $ALACRITTY_SOCKET || -n $ALACRITTY_LOG ]];    then key=alacritty
  elif [[ -n $KONSOLE_VERSION ]];                          then key=konsole
  elif [[ -n $TILIX_ID ]];                                 then key=tilix
  elif [[ -n $TERMINATOR_UUID ]];                          then key=terminator
  elif [[ -n $WT_SESSION ]];                               then key=windows-terminal
  fi

  # 2. Clé trouvée ci-dessus, puis TERM_PROGRAM, puis TERM sans le préfixe « xterm- »
  for cand in $key ${(L)TERM_PROGRAM} ${${(L)TERM}#xterm-}; do
    if [[ -n ${_enderteck_terminals[$cand]} ]]; then
      print -r -- "${_enderteck_terminals[$cand]}"
      return
    fi
  done

  # 3. Arbre des processus : on saute les shells et multiplexeurs
  local pid=$PPID ppid comm found=""
  local -i depth
  for (( depth = 0; depth < 8 && pid > 1; depth++ )); do
    read -r ppid comm <<< "$(command ps -o ppid= -o comm= -p $pid 2>/dev/null)"
    comm=${(L)${comm:t}}   # sans chemin (macOS), en minuscules
    comm=${comm#-}         # shell de login : « -zsh » → « zsh »
    case $comm in
      ''|zsh|bash|sh|dash|fish|ksh|tcsh|csh|nu|xonsh|elvish|su|sudo|doas|login|script|env|screen|byobu*|tmux*)
        pid=$ppid ;;
      *)
        found=$comm
        break ;;
    esac
  done
  if [[ -n $found ]]; then
    if [[ -n ${_enderteck_terminals[$found]} ]]; then
      print -r -- "${_enderteck_terminals[$found]}"
      return
    fi
    # Connexion SSH, systemd… : ce n'est pas un terminal, on passe au repli
    if [[ $found != (sshd*|mosh*|systemd*|init) ]]; then
      print -r -- "${(C)found}"
      return
    fi
  fi

  # 4. Repli
  print -r -- "${TERM:-shell}"
}

# « % » est spécial dans un prompt : on le double par sécurité.
PR_TERMNAME=$(_enderteck_terminal_name)
PR_TERMNAME=${PR_TERMNAME//\%/%%}


# ------------------------------------------------------------------------------
# 5. BATTERIE
# ------------------------------------------------------------------------------
# Remplit deux variables à chaque prompt :
#   _THEME_BAT_PCT       pourcentage ; VIDE si l'appareil n'a pas de batterie
#   _THEME_BAT_CHARGING  1 si la batterie est en charge, 0 sinon
#
# Le thème lit la batterie lui-même (donc le plugin « battery » n'est plus
# nécessaire, et le pourcentage reste visible pendant la charge).
#   - Linux : /sys/class/power_supply (aucun processus lancé, très rapide)
#   - macOS : pmset
# Autre système : rien n'est affiché (ajouter un « case » ici si besoin).
#
# Pour afficher aussi l'icône quand le secteur est branché mais que la charge est
# stoppée (seuil de charge, batterie pleine), remplacer le test sur « Charging »
# par : [[ $(<$bat/status) == (Charging|Full|Not charging) ]]

function _enderteck_battery {
  _THEME_BAT_PCT=""
  _THEME_BAT_CHARGING=0

  case $OSTYPE in
    linux*)
      local bat
      for bat in /sys/class/power_supply/*(N); do
        # Les adaptateurs secteur n'ont ni « capacity » ni « status » : ignorés
        [[ -r $bat/capacity && -r $bat/status ]] || continue
        # Ignore les batteries de périphériques (souris, casque…) : scope = Device
        [[ -r $bat/scope && $(<$bat/scope) != System ]] && continue
        _THEME_BAT_PCT=$(<$bat/capacity)
        [[ $(<$bat/status) == Charging ]] && _THEME_BAT_CHARGING=1
        break
      done
      ;;
    darwin*)
      local out
      out=$(pmset -g batt 2>/dev/null)
      if [[ $out =~ '([0-9]+)%' ]]; then
        _THEME_BAT_PCT=${match[1]}
        [[ $out == *'; charging;'* || $out == *'finishing charge'* ]] && _THEME_BAT_CHARGING=1
      fi
      ;;
  esac
}


# ------------------------------------------------------------------------------
# 6. GIT
# ------------------------------------------------------------------------------
# Texte produit par git_prompt_info : <PREFIX><branche><SUFFIX>
# → dans le prompt : [git: on main 🖉]
ZSH_THEME_GIT_PROMPT_PREFIX="git: on "
ZSH_THEME_GIT_PROMPT_SUFFIX=""
ZSH_THEME_GIT_PROMPT_DIRTY=""
ZSH_THEME_GIT_PROMPT_CLEAN=""

# Icônes de statut (git_prompt_status). Chaque icône est précédée d'un espace.
# %{%G…%} = « ce caractère occupe 1 colonne » : évite les décalages quand un
# glyphe vient d'une police de secours (ex. 🖉 absent de Monocraft).
# Tout est jaune (comme le reste du texte entre crochets) ; pour colorer un statut
# à part, remplacer ${PR_YELLOW} par ${PR_RED}, ${PR_GREEN}, ${PR_CYAN}…
ZSH_THEME_GIT_PROMPT_ADDED="${PR_YELLOW} %{%G${THEME_GIT_ICON_ADDED}%}"
ZSH_THEME_GIT_PROMPT_MODIFIED="${PR_YELLOW} %{%G${THEME_GIT_ICON_MODIFIED}%}"
ZSH_THEME_GIT_PROMPT_DELETED="${PR_YELLOW} %{%G${THEME_GIT_ICON_DELETED}%}"
ZSH_THEME_GIT_PROMPT_RENAMED="${PR_YELLOW} %{%G${THEME_GIT_ICON_RENAMED}%}"
ZSH_THEME_GIT_PROMPT_UNMERGED="${PR_YELLOW} %{%G${THEME_GIT_ICON_UNMERGED}%}"
ZSH_THEME_GIT_PROMPT_UNTRACKED="${PR_YELLOW} %{%G${THEME_GIT_ICON_UNTRACKED}%}"

# Environnements virtualenv / conda / ruby : le thème ajoute lui-même les crochets
# (section 7), donc on neutralise leurs préfixes/suffixes par défaut.
ZSH_THEME_VIRTUALENV_PREFIX=""
ZSH_THEME_VIRTUALENV_SUFFIX=""
ZSH_THEME_CONDA_PREFIX=""
ZSH_THEME_CONDA_SUFFIX=""
ZSH_THEME_RUBY_PROMPT_PREFIX=""
ZSH_THEME_RUBY_PROMPT_SUFFIX=""


# ------------------------------------------------------------------------------
# 7. theme_precmd — exécutée avant CHAQUE prompt
# ------------------------------------------------------------------------------
# Construit PR_LINE1 (ligne du haut), PR_LINE2 (ligne du bas, partie gauche),
# PR_GITSEG et PR_BATSEG (utilisés par le prompt de droite).
#
# CALCUL DES ─ (le point qui posait problème) :
#   largeur utile = COLUMNS - ZLE_RPROMPT_INDENT   (le RPROMPT s'arrête là aussi)
#   ligne du haut = ┌[titre]─[chemin]─[env]…  ─────  [user@host]┐
#   → on additionne la largeur VISIBLE de chaque élément fixe (« fixed »), puis
#     fill = largeur utile - fixed - largeur du chemin.
#   Si on ajoute ou retire un élément visible sur la ligne du haut, il suffit de
#   modifier la liste « fixed » ci-dessous, en ajoutant sa largeur.
#   (La mise en forme est recalculée à chaque prompt ; redimensionner la fenêtre
#   s'applique donc au prompt suivant.)

function theme_precmd {
  local TERMWIDTH=$(( COLUMNS - ${ZLE_RPROMPT_INDENT:-1} ))
  local fn name
  local -a envs

  # (a) Environnements actifs (virtualenv, conda, ruby) → texte brut sans crochets
  for fn in virtualenv_prompt_info conda_prompt_info ruby_prompt_info; do
    (( $+functions[$fn] )) || continue
    name=$($fn)
    [[ -n $name ]] && envs+=("$name")
  done

  # (b) Batterie : affichée seulement si une batterie existe
  _enderteck_battery
  PR_BATSEG=""
  if [[ -n $_THEME_BAT_PCT ]]; then
    local bat_icon=""
    (( _THEME_BAT_CHARGING )) && bat_icon=$THEME_BATTERY_CHARGING_ICON
    PR_BATSEG="${PR_BLUE}${PR_HBAR}${PR_OPEN}${bat_icon}${_THEME_BAT_PCT}%%${PR_CLOSE}"
  fi

  # (c) Git : segment affiché seulement dans un dépôt
  PR_GITSEG=""
  if (( $+functions[git_prompt_info] )); then
    local git_info
    git_info=$(git_prompt_info)
    [[ -n $git_info ]] && PR_GITSEG="─${PR_OPEN}${git_info}$(git_prompt_status)${PR_CLOSE}"
  fi

  # (d) Largeur des éléments FIXES de la ligne du haut (en colonnes visibles)
  local uh=${(%):-%n@%m}                          # texte de « user@host »
  local -i bp=$(( ${#THEME_LB} + ${#THEME_RB} ))   # largeur d'une paire de crochets
  local -i fixed=0
  (( fixed += 1 ))                                # ┌
  (( fixed += bp + ${#PR_TERMNAME} ))             # [Ghostty]
  (( fixed += 1 + bp ))                           # ─[ ]  (le chemin est compté à part)
  for name in $envs; do
    (( fixed += 1 + bp + ${#name} ))              # ─[venv]
  done
  (( fixed += bp + ${#uh} ))                      # [user@host]
  (( fixed += 1 ))                                # ┐

  # (e) Chemin : tronqué (…) seulement s'il ne reste pas au moins 1 « ─ » de remplissage
  local -i pwdsize=${#${(%):-%~}}
  local -i room=$(( TERMWIDTH - fixed ))          # place pour chemin + remplissage
  local -i pwdlen=$pwdsize fill
  if (( pwdsize + 1 > room )); then
    pwdlen=$(( room - 1 ))
    (( pwdlen < 4 )) && pwdlen=4
  fi
  fill=$(( room - pwdlen ))
  (( fill < 0 )) && fill=0

  # (f) Barre de remplissage
  PR_FILLBAR=""
  if (( fill > 0 )); then
    if [[ "${langinfo[CODESET]}" = UTF-8 ]]; then
      PR_FILLBAR="${(l:$fill::─:)}"
    else
      PR_FILLBAR="${PR_SHIFT_IN}${(l:$fill::${altchar[q]:--}:)}${PR_SHIFT_OUT}"
    fi
  fi

  # (g) Assemblage de la ligne du haut :  ┌[titre]─[chemin]─[env]──────[user@host]┐
  local envs_str=""
  for name in $envs; do
    envs_str+="${PR_BLUE}${PR_HBAR}${PR_OPEN}${name}${PR_CLOSE}"
  done

  PR_LINE1="${PR_BLUE}${PR_ULCORNER}${PR_OPEN}${PR_TERMNAME}${PR_CLOSE}"
  PR_LINE1+="${PR_BLUE}${PR_HBAR}${PR_OPEN}%${pwdlen}<...<%~%<<${PR_CLOSE}"
  PR_LINE1+="${envs_str}"
  PR_LINE1+="${PR_BLUE}${PR_FILLBAR}"
  PR_LINE1+="${PR_OPEN}%(!.%SROOT%s.%n)@%m${PR_CLOSE}${PR_BLUE}${PR_URCORNER}"

  # (h) Ligne du bas (gauche) :  └[heure]─[git: on main 🖉]─>
  PR_LINE2="${PR_BLUE}${PR_LLCORNER}${PR_OPEN}%D{${THEME_TIME_FORMAT}}${PR_CLOSE}"
  PR_LINE2+="${PR_GITSEG}"
  PR_LINE2+="${PR_BLUE}${PR_HBAR}${PR_RED}>${PR_NO_COLOUR} "
}

function theme_preexec {
  setopt local_options extended_glob
  if [[ "$TERM" = "screen" ]]; then
    local CMD=${1[(wr)^(*=*|sudo|-*)]}
    echo -n "\ek$CMD\e\\"
  fi
}

add-zsh-hook precmd  theme_precmd
add-zsh-hook preexec theme_preexec


# ------------------------------------------------------------------------------
# 8. TITRE DE FENÊTRE ET PROMPTS
# ------------------------------------------------------------------------------

# Titre de la fenêtre / de l'onglet (invisible dans le prompt)
case $TERM in
  xterm*)
    PR_TITLEBAR=$'%{\e]0;%(!.-=*[ROOT]*=- | .)%n@%m:%~ | ${COLUMNS}x${LINES} | %y\a%}'
    ;;
  screen)
    PR_TITLEBAR=$'%{\e_screen \005 (\005t) | %(!.-=[ROOT]=- | .)%n@%m:%~ | ${COLUMNS}x${LINES} | %y\e\\%}'
    ;;
  *)
    PR_TITLEBAR=""
    ;;
esac

# Titre de fenêtre pour GNU screen (invisible, vide ailleurs)
if [[ "$TERM" = "screen" ]]; then
  PR_STITLE=$'%{\ekzsh\e\\%}'
else
  PR_STITLE=""
fi

# Prompt principal : 2 lignes, construites dans theme_precmd (PR_LINE1 / PR_LINE2)
PROMPT='${PR_SET_CHARSET}${(e)PR_TITLEBAR}${PR_STITLE}${PR_LINE1}
${PR_LINE2}'

# Prompt de droite (affiché sur la 2e ligne), de gauche à droite :
#   code de retour si ≠ 0 · > · [date] · [icône de charge + pourcentage] · ┘
return_code="%(?..%{$fg[red]%}%? ↵ %{$reset_color%})"
RPROMPT=' ${return_code}${PR_RED}>${PR_BLUE}${PR_HBAR}${PR_OPEN}%D{${THEME_DATE_FORMAT}}${PR_CLOSE}${PR_BATSEG}${PR_BLUE}${PR_LRCORNER}${PR_NO_COLOUR}'

# Prompt de continuation (commande sur plusieurs lignes)
PS2='${PR_BLUE}${PR_HBAR}${PR_HBAR}${PR_OPEN}%_${PR_CLOSE}${PR_BLUE}${PR_HBAR}${PR_HBAR}${PR_NO_COLOUR} '
