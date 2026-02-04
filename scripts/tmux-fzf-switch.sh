#!/usr/bin/env bash

FZF_COLORS="bg:#282c34,fg:#abb2bf,hl:#61afef,fg+:#e5c07b,bg+:#414858,hl+:#61afef,prompt:#98c379,pointer:#c678dd,marker:#e06c75,header:#5c6370,border:#495162"

VIM_KEYS="j,k,g,G,q,/,i,ctrl-d,ctrl-u,0,1,2,3,4,5,6,7,8,9"

FZF_OPTS=(
  --ansi
  --reverse
  --border rounded
  --preview-window 'right,60%'
  --color "$FZF_COLORS"
  --no-info
  --delimiter '\t'
  --disabled
  --prompt '  '
  --header-first
  --bind "j:down,k:up,g:first,G:last,ctrl-d:half-page-down,ctrl-u:half-page-up"
  --bind "enter:accept"
  --bind "q:abort"
  --bind "/:unbind($VIM_KEYS)+enable-search+clear-query+change-prompt(/ )"
  --bind "i:unbind($VIM_KEYS)+enable-search+clear-query+change-prompt(/ )"
  --bind "esc:transform:[[ \$FZF_PROMPT == '/ ' ]] && echo 'disable-search+rebind($VIM_KEYS)+clear-query+change-prompt(  )' || echo 'abort'"
  --bind "change:transform-query:[[ \$FZF_PROMPT == '/ ' ]] && echo \$FZF_QUERY || echo ''"
)

# Number keys enter search mode with the digit pre-filled
for n in {0..9}; do
  FZF_OPTS+=(--bind "$n:unbind($VIM_KEYS)+enable-search+change-prompt(/ )+change-query($n)")
done

case "$1" in
windows)
  selected=$(tmux list-windows -F $'#{window_index}\t#{window_name} #{pane_current_path} (#{window_panes} panes)' |
    fzf "${FZF_OPTS[@]}" \
      --header 'j/k:nav  /:search  q:quit' \
      --preview 'tmux capture-pane -ep -t :{1}')
  [ -n "$selected" ] && tmux select-window -t ":${selected%%	*}"
  ;;

panes)
  selected=$(tmux list-panes -s -F $'#{window_index}.#{pane_index}\t#{window_name} #{pane_current_path}' |
    fzf "${FZF_OPTS[@]}" \
      --header 'j/k:nav  /:search  q:quit' \
      --preview 'tmux capture-pane -ep -t :{1}')
  if [ -n "$selected" ]; then
    target="${selected%%	*}"
    tmux select-window -t ":${target%%.*}"
    tmux select-pane -t ":${target}"
  fi
  ;;

all)
  selected=$(tmux list-panes -a -F $'#{session_name}:#{window_index}.#{pane_index}\t#{window_name} [#{session_name}] #{pane_current_path}' |
    fzf "${FZF_OPTS[@]}" \
      --header 'j/k:nav  /:search  q:quit' \
      --preview 'tmux capture-pane -ep -t {1}')
  [ -n "$selected" ] && tmux switch-client -t "${selected%%	*}"
  ;;

*)
  echo "Usage: $0 {windows|panes|all}"
  exit 1
  ;;
esac

exit 0
