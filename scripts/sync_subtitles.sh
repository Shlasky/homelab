#!/usr/bin/env bash

# Text formatting
_N='\033[0;'    # Normal
_B='\033[1;'      # Bold
_D='\033[2;'       # Dim/Faint
_I='\033[3;'    # Italic
_U='\033[4;' # Underline
_R='\033[7;'   # Reverse (swap fg/bg)

# Regular colors
G='32m'  # Green
Y='33m'  # Yellow
R='31m'  # Red
B='34m'  # Blue
C='36m'  # Cyan
M='35m'  # Magenta
W='37m'  # White
Z='0m'     # No Color (Reset)

log(){
  local level="$1"
  shift
  local message="$*"

  case "$level" in
    DEBUG) clr="$_B$C" ;;
    SUCCESS) clr="$_B$G" ;;
    INFO) clr="$_B$B" ;;
    WARN) clr="$_B$Y" ;;
    ERROR) clr="$_B$R" ;;
    *) err "Level doesn't exists" ;;
  esac
  
  echo -e "$clr$(date "+%d-%m-%Y %T") | $level | $message"
  return 0
}

err(){
  log ERROR "$1"
  [ -n "$2" ] && exit "$2" || exit 1
}

checkvars(){
  [ -z "$1" ] && return 0

  for var in "${@}"; do
    [ -z "${!var}" ] && missing+="${var} "
  done

  [ -n "$missing" ] && err "Missing variables: $missing, can't proceed" 2
}

# --------------------------------------------------------------------------


