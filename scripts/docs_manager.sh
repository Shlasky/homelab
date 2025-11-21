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

  echo -e "$clr$(date "+%d-%m-%Y %T") | $level | $message\033[0m"
  return 0
}

err(){
  log ERROR "$1"
  [ -n "$2" ] && exit "$2" || exit 1
}

checkvars(){
  [ -z "$1" ] && return 0

  log INFO "Checking for missing variables"
  for var in "${@}"; do
    [ -z "${!var}" ] && missing+="${var} "
  done

  [ -n "$missing" ] && err "Missing variables: $missing, can't proceed" 2
  log SUCCESS "No missing variables found, proceeding..."
}

# --------------------------------------------------------------------------

DOCS_DIR="/srv/docs"
MKDOCS_IMAGE="squidfunk/mkdocs-material:latest"

usage() {
  cat << EOF
MkDocs Documentation Manager

Usage: $(basename $0) <command> [options]

Commands:
  build [public|private|all]     Build static site(s)
  rebuild [public|private|all]   Clean rebuild of static site(s)
  deploy [public|private|all]    Build and restart production containers
  serve [public|private]         Start development server with live reload
  update                         Pull latest MkDocs Material image
  logs [wiki|docs|all]          View container logs
  status                         Check service status
  start [wiki|docs|all]         Start containers
  stop [wiki|docs|all]          Stop containers
  restart [wiki|docs|all]       Restart containers
  help                           Show this help message

Examples:
  $(basename $0) build all              # Build both public and private sites
  $(basename $0) deploy public          # Deploy only public wiki
  $(basename $0) serve private          # Start dev server for private docs
  $(basename $0) logs wiki              # View wiki nginx logs
  $(basename $0) restart all            # Restart all containers

EOF
  exit 0
}

build_docs() {
  local target="${1:-all}"

  cd "$DOCS_DIR" || err "Failed to change directory to $DOCS_DIR" 1

  case "$target" in
    public)
      log INFO "Building public documentation (wiki.ashlasky.com)..."
      docker run --rm -v "$DOCS_DIR:/docs" "$MKDOCS_IMAGE" build --config-file mkdocs-public.yml --clean || err "Failed to build public docs" 1
      log SUCCESS "Public documentation built successfully"
      ;;
    private)
      log INFO "Building private documentation (docs.ashlasky.com)..."
      docker run --rm -v "$DOCS_DIR:/docs" "$MKDOCS_IMAGE" build --config-file mkdocs-private.yml --clean || err "Failed to build private docs" 1
      log SUCCESS "Private documentation built successfully"
      ;;
    all)
      log INFO "Building all documentation..."
      build_docs public
      build_docs private
      log SUCCESS "All documentation built successfully"
      ;;
    *)
      err "Invalid target: $target. Use 'public', 'private', or 'all'" 1
      ;;
  esac
}

rebuild_docs() {
  local target="${1:-all}"

  log INFO "Cleaning old builds..."

  case "$target" in
    public)
      rm -rf "$DOCS_DIR/site-public"/*
      ;;
    private)
      rm -rf "$DOCS_DIR/site-private"/*
      ;;
    all)
      rm -rf "$DOCS_DIR/site-public"/* "$DOCS_DIR/site-private"/*
      ;;
  esac

  log SUCCESS "Old builds cleaned"
  build_docs "$target"
}

deploy_docs() {
  local target="${1:-all}"

  log INFO "Deploying documentation: $target"
  build_docs "$target"

  cd "$DOCS_DIR" || err "Failed to change to $DOCS_DIR" 1

  case "$target" in
    public)
      docker compose up -d wiki-nginx || err "Failed to deploy public docs" 1
      log SUCCESS "Public documentation deployed (wiki.ashlasky.com)"
      ;;
    private)
      docker compose up -d docs-nginx || err "Failed to deploy private docs" 1
      log SUCCESS "Private documentation deployed (docs.ashlasky.com)"
      ;;
    all)
      docker compose up -d wiki-nginx docs-nginx || err "Failed to deploy docs" 1
      log SUCCESS "All documentation deployed successfully"
      ;;
    *)
      err "Invalid target: $target. Use 'public', 'private', or 'all'" 1
      ;;
  esac
}

serve_docs() {
  local target="${1:-public}"

  cd "$DOCS_DIR" || err "Failed to change to $DOCS_DIR" 1

  case "$target" in
    public)
      log INFO "Starting development server for public docs..."
      log INFO "Access at: http://localhost:8000"
      docker run --rm -it -p 8000:8000 -v "$DOCS_DIR:/docs" "$MKDOCS_IMAGE" serve --dev-addr=0.0.0.0:8000 --config-file mkdocs-public.yml
      ;;
    private)
      log INFO "Starting development server for private docs..."
      log INFO "Access at: http://localhost:8000"
      docker run --rm -it -p 8000:8000 -v "$DOCS_DIR:/docs" "$MKDOCS_IMAGE" serve --dev-addr=0.0.0.0:8000 --config-file mkdocs-private.yml
      ;;
    *)
      err "Invalid target: $target. Use 'public' or 'private'" 1
      ;;
  esac
}

update_image() {
  log INFO "Pulling latest MkDocs Material image..."
  docker pull "$MKDOCS_IMAGE" || err "Failed to pull image" 1
  log SUCCESS "Image updated successfully"
}

view_logs() {
  local target="${1:-all}"

  cd "$DOCS_DIR" || err "Failed to change to $DOCS_DIR" 1

  case "$target" in
    wiki)
      docker compose logs -f wiki-nginx
      ;;
    docs)
      docker compose logs -f docs-nginx
      ;;
    all)
      docker compose logs -f
      ;;
    *)
      err "Invalid target: $target. Use 'wiki', 'docs', or 'all'" 1
      ;;
  esac
}

check_status() {
  cd "$DOCS_DIR" || err "Failed to change to $DOCS_DIR" 1

  log INFO "Documentation services status:"
  echo ""
  docker compose ps
  echo ""

  if [ -d "site-public" ] && [ "$(ls -A site-public)" ]; then
    log SUCCESS "Public site built: $(du -sh site-public | cut -f1)"
  else
    log WARN "Public site not built"
  fi

  if [ -d "site-private" ] && [ "$(ls -A site-private)" ]; then
    log SUCCESS "Private site built: $(du -sh site-private | cut -f1)"
  else
    log WARN "Private site not built"
  fi
}

manage_containers() {
  local action="$1"
  local target="${2:-all}"

  cd "$DOCS_DIR" || err "Failed to change to $DOCS_DIR" 1

  case "$target" in
    wiki)
      docker compose "$action" wiki-nginx || err "Failed to $action wiki-nginx" 1
      ;;
    docs)
      docker compose "$action" docs-nginx || err "Failed to $action docs-nginx" 1
      ;;
    all)
      docker compose "$action" wiki-nginx docs-nginx || err "Failed to $action containers" 1
      ;;
    *)
      err "Invalid target: $target. Use 'wiki', 'docs', or 'all'" 1
      ;;
  esac

  log SUCCESS "Containers ${action}ed successfully"
}

# --------------------------------------------------------------------------
# Main script

[ $# -eq 0 ] && usage

log INFO "Starting $(basename $0)"

COMMAND="$1"
shift

case "$COMMAND" in
  build)
    build_docs "$1"
    ;;
  rebuild)
    rebuild_docs "$1"
    ;;
  deploy)
    deploy_docs "$1"
    ;;
  serve)
    serve_docs "$1"
    ;;
  update)
    update_image
    ;;
  logs)
    view_logs "$1"
    ;;
  status)
    check_status
    ;;
  start)
    manage_containers start "$1"
    ;;
  stop)
    manage_containers stop "$1"
    ;;
  restart)
    manage_containers restart "$1"
    ;;
  help|--help|-h)
    usage
    ;;
  *)
    log ERROR "Unknown command: $COMMAND"
    echo ""
    usage
    ;;
esac

log SUCCESS "Operation completed successfully"
