# bash completion for declutter
#   source /path/to/declutter/completions/declutter.bash
_declutter() {
  local cur prev groups opts
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"
  groups="ai-cli ai-ide ai-ml ai-model pkg-node pkg-python pkg-rust pkg-go pkg-java docker browser os xcode"
  opts="-l --level -y --yes -n --dry-run --report --json --only --skip --deep
        --projects --days --top --sudo --log --lang -q --quiet -V --version -h --help"

  case "$prev" in
    -l|--level)      COMPREPLY=( $(compgen -W "green yellow" -- "$cur") ); return ;;
    --only|--skip)   COMPREPLY=( $(compgen -W "$groups" -- "$cur") ); return ;;
    --sudo)          COMPREPLY=( $(compgen -W "yes no" -- "$cur") ); return ;;
    --lang)          COMPREPLY=( $(compgen -W "en vi" -- "$cur") ); return ;;
    --log)           COMPREPLY=( $(compgen -f -- "$cur") ); return ;;
    --projects)      COMPREPLY=( $(compgen -d -- "$cur") ); return ;;
    --days|--top)    return ;;
  esac
  COMPREPLY=( $(compgen -W "$opts" -- "$cur") )
}
complete -F _declutter declutter
