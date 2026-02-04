#!/usr/bin/env bash

SCRIPT_PATH="$(realpath "$0")"

FZF_COLORS="bg:#282c34,fg:#abb2bf,hl:#61afef,fg+:#e5c07b,bg+:#414858,hl+:#61afef,prompt:#98c379,pointer:#c678dd,marker:#e06c75,header:#5c6370,border:#495162"

VIM_KEYS="j,k,g,G,q,/,i,x,n,?,ctrl-d,ctrl-u,0,1,2,3,4,5,6,7,8,9"

# List generator — used for initial display and fzf reload after kill
if [ "$1" = "--list" ]; then
  case "$2" in
  windows)
    tmux list-windows -F $'#{window_index}\t#{?window_active,* ,  }#{window_name} #{pane_current_path} (#{window_panes} panes)'
    ;;
  panes)
    tmux list-panes -s -F $'#{window_index}.#{pane_index}\t#{?#{&&:#{window_active},#{pane_active}},* ,  }#{window_name} #{pane_current_path}'
    ;;
  all)
    tmux list-panes -a -F $'#{session_name}:#{window_index}.#{pane_index}\t#{?#{&&:#{window_active},#{pane_active}},* ,  }#{window_name} [#{session_name}] #{pane_current_path}'
    ;;
  esac | sed -e "s|$HOME|~|g" -e $'s/\t\\* /\t\x1b[32m* /' -e $'s/$/\x1b[0m/'
  exit 0
fi

FZF_OPTS=(
  --ansi
  --reverse
  --border rounded
  --preview-window 'right,60%'
  --color "$FZF_COLORS"
  --no-info
  --delimiter '\t'
  --with-nth '2..'
  --disabled
  --prompt '  '
  --header $'j/k:nav  g/G:ends  ^d/u:page\n/:search  0-9:jump  n:new  x:kill  q/esc:quit'
  --header-first
  --bind "start:toggle-header"
  --bind "j:down,k:up,g:first,G:last,ctrl-d:half-page-down,ctrl-u:half-page-up"
  --bind "enter:accept"
  --bind "q:abort"
  --bind "/:unbind($VIM_KEYS)+enable-search+clear-query+change-prompt(/ )"
  --bind "i:unbind($VIM_KEYS)+enable-search+clear-query+change-prompt(/ )"
  --bind "esc:transform:[[ \$FZF_PROMPT == '/ ' ]] && echo 'disable-search+rebind($VIM_KEYS)+clear-query+change-prompt(  )' || echo 'abort'"
  --bind "change:transform-query:[[ \$FZF_PROMPT == '/ ' ]] && echo \$FZF_QUERY || echo ''"
  --bind "n:execute-silent(tmux new-window)+abort"
  --bind "?:toggle-header"
)

# Number keys enter search mode with the digit pre-filled
for n in {0..9}; do
  FZF_OPTS+=(--bind "$n:unbind($VIM_KEYS)+enable-search+change-prompt(/ )+change-query($n)")
done

case "$1" in
windows)
  selected=$("$SCRIPT_PATH" --list windows |
    fzf "${FZF_OPTS[@]}" \
      --preview 'tmux capture-pane -ep -t :{1}' \
      --bind "x:execute-silent(tmux kill-window -t :{1})+reload($SCRIPT_PATH --list windows)")
  [ -n "$selected" ] && tmux select-window -t ":${selected%%	*}"
  ;;

panes)
  selected=$("$SCRIPT_PATH" --list panes |
    fzf "${FZF_OPTS[@]}" \
      --preview 'tmux capture-pane -ep -t :{1}' \
      --bind "x:execute-silent(tmux kill-pane -t :{1})+reload($SCRIPT_PATH --list panes)")
  if [ -n "$selected" ]; then
    target="${selected%%	*}"
    tmux select-window -t ":${target%%.*}"
    tmux select-pane -t ":${target}"
  fi
  ;;

all)
  selected=$("$SCRIPT_PATH" --list all |
    fzf "${FZF_OPTS[@]}" \
      --preview 'tmux capture-pane -ep -t {1}' \
      --bind "x:execute-silent(tmux kill-pane -t {1})+reload($SCRIPT_PATH --list all)")
  [ -n "$selected" ] && tmux switch-client -t "${selected%%	*}"
  ;;

*)
  echo "Usage: $0 {windows|panes|all}"
  exit 1
  ;;
esac

exit 0
