# zsh-which-key.plugin.zsh
# Ctrl-O: searchable list of the keys bound in the current keymap.
#
# Descriptions come from `man zshzle` and `man zshcompsys` rather than a
# hand-written table: they are extracted once into a cache, so starting a
# shell costs nothing. Only plugin widgets, which no manual documents, are
# described by hand below.
#
# The cache lives in $ZSH_CACHE_DIR and NOT in $ZSH_CACHE_DIR/completions:
# that one is on the fpath and belongs to the completion generator.

_which_key_cache="${ZSH_CACHE_DIR:-$HOME/.cache/zsh}/which-key-desc"

# One line per widget: <name> TAB <full description, newlines folded away>.
_which_key_build() {
  mkdir -p "${_which_key_cache:h}"
  { man zshzle; man zshcompsys } 2>/dev/null | col -b | awk '
    match($0, /^ {3,7}[a-z_][a-zA-Z0-9_-]*( \(|$)/) {
      name=$1
      if (name in seen) next
      seen[name]=1
      text=""
      while ((getline d) > 0) {
        gsub(/^[[:space:]]+|[[:space:]]+$/,"",d)
        if (d == "") { if (text != "") break; else continue }
        text = (text == "") ? d : text " " d
      }
      gsub(/\t/," ",text)
      print name "\t" text
    }' > "$_which_key_cache"
  printf '%s\t%s\n' \
    which-key-search              "this list" \
    self-insert                   "Insert the typed character." \
    fzf-completion                "fzf: interactive completion." \
    fzf-file-widget               "fzf: pick a file and insert it at the cursor." \
    fzf-cd-widget                 "fzf: pick a directory and cd into it." \
    atuin-search                  "atuin: fuzzy search through shell history." \
    atuin-search-viins            "atuin: fuzzy search through shell history." \
    history-substring-search-up   "Search history backwards for lines starting with what you typed." \
    history-substring-search-down "Search history forwards for lines starting with what you typed." \
    >> "$_which_key_cache"
}

# Emits: <padded, coloured display> TAB <full description>.
# fzf shows and matches the first field only; the second feeds the preview.
#
# Raw sequences become key names, and self-insert, undefined-key and the -R
# ranges are skipped: those are the keys that do nothing, and the question
# this list answers is "what can I press".
#
# `wide` compensates printf, which counts bytes: each arrow takes three of
# them but a single column. Colour is added after padding, for the same
# reason.
_which_key_list() {
  bindkey -L | awk -v C="$_which_key_cache" '
    BEGIN { while ((getline l < C) > 0) { n=index(l,"\t"); d[substr(l,1,n-1)]=substr(l,n+1) } }
    /^bindkey -R / { next }
    {
      w=$NF
      if (w == "self-insert" || w == "undefined-key") next
      k=$0; sub(/^bindkey +/,"",k); sub(/^-M [a-z.]+ +/,"",k)
      sub(/[ \t]+[^ \t]+$/,"",k); gsub(/"/,"",k)
      r=k; wide=0
      if (r == "^[") r="Esc"
      else {
        wide+=2*gsub(/\^\[\[1;3D/,"Option-←",r); wide+=2*gsub(/\^\[\[1;3C/,"Option-→",r)
        gsub(/\^\[\[200~/,"paste",r)
        wide+=2*gsub(/\^\[\[A/,"↑",r); wide+=2*gsub(/\^\[\[B/,"↓",r)
        wide+=2*gsub(/\^\[\[C/,"→",r); wide+=2*gsub(/\^\[\[D/,"←",r)
        wide+=2*gsub(/\^\[OA/,"↑ (app)",r); wide+=2*gsub(/\^\[OB/,"↓ (app)",r)
        wide+=2*gsub(/\^\[OC/,"→ (app)",r); wide+=2*gsub(/\^\[OD/,"← (app)",r)
        gsub(/\^\[/,"Option-",r); gsub(/\^\?/,"Backspace",r)
        gsub(/\^I/,"Tab",r); gsub(/\^M/,"Enter",r)
        gsub(/\^X/,"Ctrl-X ",r); gsub(/\^/,"Ctrl-",r)
      }
      full = (w in d) ? d[w] : ""
      short = (length(full) > 64) ? substr(full, 1, 63) "…" : full
      printf "\033[1;36m%-*s\033[0m \033[38;5;245m%-30s\033[0m %s\t%s\n", \
             16+wide, r, w, short, full
    }' | sort
}

_which_key_search() {
  emulate -L zsh
  [[ -s $_which_key_cache ]] || _which_key_build

  zle -I
  _which_key_list | fzf \
    --ansi --layout=reverse --height=70% --info=inline \
    --delimiter=$'\t' --with-nth=1 \
    --border=rounded --border-label=' which-key ' --border-label-pos=3 \
    --header='type to filter · esc to close' --header-first \
    --prompt='  ' --pointer='▌' \
    --preview='printf "%s\n" {2}' --preview-window=down,3,wrap,border-top \
    --color='label:bold,header:italic,preview-border:dim' \
    >/dev/null
  zle reset-prompt
}

zle -N which-key-search _which_key_search

bindkey -M viins '^O' which-key-search
bindkey -M vicmd '^O' which-key-search
bindkey -M emacs '^O' which-key-search
