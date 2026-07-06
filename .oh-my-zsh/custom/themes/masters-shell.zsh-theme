# Masters-Shell theme
# Tree-style breadcrumb prompt: header, sliding window of the last N path
# segments as a downward tree, git branch tagged onto the repo-root segment,
# final line is just the arrow with command duration shown via RPROMPT
# once it crosses the threshold.

MASTERS_MAX_SEGMENTS=3
MASTERS_DURATION_THRESHOLD=30

zmodload zsh/datetime 2>/dev/null
autoload -Uz add-zsh-hook

_masters_preexec() {
  _masters_cmd_start=$EPOCHREALTIME
}

_masters_build_prompt() {
  local -a parts
  if [[ "$PWD" == "/" ]]; then
    parts=("/")
  else
    parts=("${(@s:/:)PWD}")
    parts=("${parts[@]:1}")
  fi

  local git_root="" git_branch=""
  git_root=$(git rev-parse --show-toplevel 2>/dev/null)
  if [[ -n "$git_root" ]]; then
    git_branch=$(git branch --show-current 2>/dev/null)
    [[ -z "$git_branch" ]] && git_branch=$(git rev-parse --short HEAD 2>/dev/null)
  fi

  local total=${#parts[@]}
  local start=1
  (( total > MASTERS_MAX_SEGMENTS )) && start=$(( total - MASTERS_MAX_SEGMENTS + 1 ))

  local out=$'%B%F{#A78BFA}Masters-Shell%f%b\n'
  local indent="" accum="/" seg line i=1

  for seg in "${parts[@]}"; do
    accum="${accum}${seg}/"
    if (( i >= start )); then
      line="${indent}%F{#6B6B8A}└─ %f%F{#FFFFFF}${seg}%f"
      if [[ -n "$git_root" && "${accum%/}" == "$git_root" ]]; then
        line="${line} %F{#7EFCA0}+ ${git_branch}%f"
      fi
      out="${out}${line}"$'\n'
      indent="${indent}   "
    fi
    (( i++ ))
  done

  out="${out}${indent}%F{#6B6B8A}└─ %f%F{#7EFCA0}>%f "
  PROMPT="$out"
}

_masters_precmd() {
  RPROMPT=""
  if [[ -n "$_masters_cmd_start" ]]; then
    local dur=$(( EPOCHREALTIME - _masters_cmd_start ))
    if (( dur >= MASTERS_DURATION_THRESHOLD )); then
      RPROMPT="%F{#6B6B8A}${dur%.*}s%f"
    fi
    unset _masters_cmd_start
  fi
  _masters_build_prompt
}

# Transient prompt: once a command is submitted, collapse the whole tree
# down to just the arrow + typed command (no tree connector), followed by
# an "output:" label before the command's own output, so scrollback stays
# compact and only the "live" prompt ever shows the full tree.
zle-line-finish() {
  local -a plines
  plines=("${(@f)PROMPT}")
  local nlines=${#plines[@]}
  print -n "\e[$(( nlines > 1 ? nlines - 1 : 0 ))F\e[J"
  print -rP "%F{#7EFCA0}>%f ${BUFFER}"
  print -n -rP "%F{#6B6B8A}output:%f"
}
zle -N zle-line-finish

add-zsh-hook preexec _masters_preexec
add-zsh-hook precmd _masters_precmd
