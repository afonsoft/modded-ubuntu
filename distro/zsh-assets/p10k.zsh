# Modded Ubuntu - Powerlevel10k otimizado para tela pequena
# Dois prompts: dir + git na primeira linha, caractere na segunda;
# hora curta do lado direito; sem linha em branco; transient prompt.

[[ ! -o aliases ]] || setopt no_aliases
[[ ! -o sh_glob ]] || setopt no_sh_glob
unset -m "(POWERLEVEL9K_*)~POWERLEVEL9K_GITSTATUS_DIR"

# Modo Nerd Font v3 (instalamos MesloLGS NF)
typeset -g POWERLEVEL9K_MODE=nerdfont-v3

# Layout em duas linhas
typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(dir vcs newline prompt_char)
typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(time)

# Ocupa menos espaco
typeset -g POWERLEVEL9K_PROMPT_ADD_NEWLINE=false
typeset -g POWERLEVEL9K_SHORTEN_DIR_LENGTH=1
typeset -g POWERLEVEL9K_DIR_MAX_LENGTH=40
typeset -g POWERLEVEL9K_TRANSIENT_PROMPT=always

# Desliga instant prompt para evitar warnings em PRoot/Termux sem TTY completo
typeset -g POWERLEVEL9K_INSTANT_PROMPT=off

# Horario curto no canto direito
typeset -g POWERLEVEL9K_TIME_FORMAT='%D{%H:%M}'
typeset -g POWERLEVEL9K_TIME_UPDATE_ON_COMMAND=true

# Diretorio truncado para caber melhor em telas pequenas
typeset -g POWERLEVEL9K_DIR_HYPERLINK=false
typeset -g POWERLEVEL9K_DIR_SHOW_WRITABLE=true

# Remove os separadores powerline para economizar espaco horizontal
typeset -g POWERLEVEL9K_LEFT_SEGMENT_SEPARATOR=''
typeset -g POWERLEVEL9K_RIGHT_SEGMENT_SEPARATOR=''
typeset -g POWERLEVEL9K_LEFT_PROMPT_LAST_SEGMENT_END_SYMBOL=''
typeset -g POWERLEVEL9K_RIGHT_PROMPT_FIRST_SEGMENT_START_SYMBOL=''

# Restringe o VCS apenas ao git e limita icones extras
typeset -g POWERLEVEL9K_VCS_BACKENDS=(git)

# Desabilita o daemon gitstatus para evitar erro "gitstatus failed to initialize"
# em PRoot/Termux (falta de rede, arquitetura ou permissao para executar o binario).
# O segmento vcs passa a usar git diretamente (mais lento, mas funcional).
typeset -g POWERLEVEL9K_DISABLE_GITSTATUS=true
