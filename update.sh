#!/usr/bin/env zsh
# update — macOS full-system updater

set -uo pipefail

# Kleuren
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
RESET='\033[0m'

print_header() {
  echo ""
  echo "${BOLD}${BLUE}▶ $1${RESET}"
  echo "${BLUE}$(printf '─%.0s' {1..40})${RESET}"
}

print_success() {
  echo "${GREEN}✓ $1${RESET}"
}

print_skip() {
  echo "${YELLOW}⊘ $1 niet gevonden, overgeslagen${RESET}"
}

print_error() {
  echo "${RED}✗ $1${RESET}"
}

command_exists() {
  command -v "$1" &>/dev/null
}

UPDATED_TOOLS=()
SKIPPED_TOOLS=()
FAILED_TOOLS=()

INSTALL_DIR="$HOME/.local/bin"

install_script() {
  echo "${BOLD}Installeren van 'update' commando...${RESET}"

  mkdir -p "$INSTALL_DIR"

  cp "$0" "$INSTALL_DIR/update"
  chmod +x "$INSTALL_DIR/update"
  print_success "Script gekopieerd naar $INSTALL_DIR/update"

  for RC_FILE in "$HOME/.zshrc" "$HOME/.bashrc"; do
    if [[ -f "$RC_FILE" ]]; then
      if ! grep -q "$INSTALL_DIR" "$RC_FILE" 2>/dev/null; then
        echo "" >> "$RC_FILE"
        echo "# Added by update-script installer" >> "$RC_FILE"
        echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> "$RC_FILE"
        print_success "PATH toegevoegd aan $RC_FILE"
      else
        print_success "$INSTALL_DIR al in PATH van $RC_FILE"
      fi
    fi
  done

  echo ""
  echo "${GREEN}${BOLD}Klaar! Start een nieuw terminal-venster en typ 'update'.${RESET}"
  exit 0
}

case "${1:-}" in
  --install) install_script ;;
  --help|-h)
    echo "Gebruik: update [--install]"
    echo "  --install   Installeer als 'update' commando in ~/.local/bin"
    exit 0
    ;;
esac

# ============================================================
# UPDATE SECTIES
# ============================================================

# === macOS Software Update ===
update_macos() {
  print_header "Apple Software Update"
  echo "  Updates controleren..."
  if softwareupdate -l 2>&1 | grep -q "No new software available"; then
    print_success "macOS: alles up-to-date"
    UPDATED_TOOLS+=("macOS (geen updates)")
  else
    echo "  Updates installeren (kan herstart vereisen)..."
    sudo softwareupdate --install --all 2>&1 || {
      print_error "softwareupdate mislukt"
      FAILED_TOOLS+=("Apple Software Update")
      return
    }
    print_success "macOS updates geïnstalleerd"
    UPDATED_TOOLS+=("Apple Software Update")
  fi
}

# === Homebrew ===
update_homebrew() {
  if ! command_exists brew; then
    print_skip "Homebrew"
    SKIPPED_TOOLS+=("Homebrew")
    return
  fi

  print_header "Homebrew"
  echo "  brew update..."
  brew update

  echo "  brew upgrade (formulae)..."
  brew upgrade || true

  echo "  brew upgrade --cask..."
  brew upgrade --cask --greedy 2>&1 || true

  print_success "Homebrew klaar"
  UPDATED_TOOLS+=("Homebrew")
}

# === Mac App Store ===
update_mas() {
  if ! command_exists mas; then
    print_skip "mas (Mac App Store CLI)"
    SKIPPED_TOOLS+=("Mac App Store")
    return
  fi

  print_header "Mac App Store"
  mas upgrade || true
  print_success "App Store apps bijgewerkt"
  UPDATED_TOOLS+=("Mac App Store")
}

# === Node.js / npm ===
update_npm() {
  if ! command_exists npm; then
    print_skip "npm"
    SKIPPED_TOOLS+=("npm")
    return
  fi

  print_header "Node.js / npm"
  echo "  npm zelf updaten..."
  npm install -g npm@latest

  echo "  globale packages updaten..."
  npm update -g || true

  print_success "npm globals bijgewerkt"
  UPDATED_TOOLS+=("npm")
}

# === Python / pip ===
update_pip() {
  if ! command_exists pip3; then
    print_skip "pip3"
    SKIPPED_TOOLS+=("pip3")
    return
  fi

  print_header "Python / pip3"
  pip3 install --upgrade pip --quiet

  OUTDATED=$(pip3 list --outdated --format=freeze 2>/dev/null | cut -d= -f1 || true)
  if [[ -n "$OUTDATED" ]]; then
    echo "$OUTDATED" | xargs pip3 install --upgrade --quiet || true
    print_success "pip3 packages bijgewerkt"
  else
    print_success "pip3: alles up-to-date"
  fi
  UPDATED_TOOLS+=("pip3")
}

# === Ruby gems ===
update_gems() {
  if ! command_exists gem; then
    print_skip "gem"
    SKIPPED_TOOLS+=("Ruby gems")
    return
  fi

  print_header "Ruby gems"
  gem update --system || true
  gem update || true
  gem cleanup || true
  print_success "Ruby gems bijgewerkt"
  UPDATED_TOOLS+=("Ruby gems")
}

# === Rust ===
update_rust() {
  if ! command_exists rustup; then
    print_skip "rustup"
    SKIPPED_TOOLS+=("Rust")
    return
  fi

  print_header "Rust"
  rustup update

  if cargo install-update --help &>/dev/null 2>&1; then
    echo "  cargo packages updaten..."
    cargo install-update --all || true
    print_success "Rust toolchain + cargo packages bijgewerkt"
  else
    print_success "Rust toolchain bijgewerkt (cargo-update niet geïnstalleerd)"
  fi
  UPDATED_TOOLS+=("Rust")
}

# === Oh My Zsh ===
update_omz() {
  if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    print_skip "Oh My Zsh"
    SKIPPED_TOOLS+=("Oh My Zsh")
    return
  fi

  print_header "Oh My Zsh"
  zsh -c "source $HOME/.oh-my-zsh/oh-my-zsh.sh && omz update --unattended" 2>/dev/null || \
    git -C "$HOME/.oh-my-zsh" pull --rebase || true
  print_success "Oh My Zsh bijgewerkt"
  UPDATED_TOOLS+=("Oh My Zsh")
}

# === Cleanup (CleanMyMac-stijl) ===
update_cleanup() {
  print_header "Systeem Cleanup"

  # Vraag bevestiging voor een stap; toont label + grootte
  confirm_step() {
    local label="$1"
    local size="$2"
    echo -n "  ${YELLOW}?${RESET} ${label}${size:+ ($size)} — verwijderen? [j/N] "
    read -r reply </dev/tty
    [[ "$reply" =~ ^[jJyY]$ ]]
  }

  # Verwijder inhoud van een directory na bevestiging
  clean_dir() {
    local dir="$1"
    local label="$2"
    if [[ -d "$dir" ]]; then
      local size
      size=$(du -sh "$dir" 2>/dev/null | cut -f1 || echo "?")
      if confirm_step "$label" "$size"; then
        rm -rf "${dir:?}"/* 2>/dev/null || true
        print_success "$label geleegd ($size vrijgemaakt)"
      else
        echo "  ${YELLOW}⊘${RESET} $label overgeslagen"
      fi
    fi
  }

  # User caches
  clean_dir "$HOME/Library/Caches" "~/Library/Caches"

  # User logs
  clean_dir "$HOME/Library/Logs" "~/Library/Logs"

  # Xcode DerivedData
  clean_dir "$HOME/Library/Developer/Xcode/DerivedData" "Xcode DerivedData"

  # iOS Device Support (kan gigabytes zijn)
  clean_dir "$HOME/Library/Developer/Xcode/iOS DeviceSupport" "Xcode iOS DeviceSupport"

  # npm cache
  if command_exists npm; then
    if confirm_step "npm cache" ""; then
      npm cache clean --force 2>/dev/null || true
      print_success "npm cache geleegd"
    else
      echo "  ${YELLOW}⊘${RESET} npm cache overgeslagen"
    fi
  fi

  # pip cache
  if command_exists pip3; then
    local pip_size
    pip_size=$(pip3 cache info 2>/dev/null | grep -i "size" | awk '{print $NF}' || echo "?")
    if confirm_step "pip3 cache" "$pip_size"; then
      pip3 cache purge 2>/dev/null || true
      print_success "pip3 cache geleegd"
    else
      echo "  ${YELLOW}⊘${RESET} pip3 cache overgeslagen"
    fi
  fi

  # Homebrew cache
  if command_exists brew; then
    local brew_size
    brew_size=$(brew cleanup --dry-run 2>/dev/null | tail -1 | grep -oE '[0-9.]+ [KMG]B' || echo "?")
    if confirm_step "Homebrew download cache" "$brew_size"; then
      brew cleanup --prune=all 2>/dev/null || true
      print_success "Homebrew download cache geleegd"
    else
      echo "  ${YELLOW}⊘${RESET} Homebrew cache overgeslagen"
    fi
  fi

  # Prullenmand
  local trash_size
  trash_size=$(du -sh "$HOME/.Trash" 2>/dev/null | cut -f1 || echo "?")
  if confirm_step "Prullenmand" "$trash_size"; then
    rm -rf "$HOME/.Trash/"* 2>/dev/null || true
    print_success "Prullenmand geleegd ($trash_size vrijgemaakt)"
  else
    echo "  ${YELLOW}⊘${RESET} Prullenmand overgeslagen"
  fi

  # .DS_Store bestanden
  local ds_count
  ds_count=$(find "$HOME" -maxdepth 5 -name ".DS_Store" 2>/dev/null | wc -l | tr -d ' ')
  if confirm_step ".DS_Store bestanden" "$ds_count bestanden"; then
    find "$HOME" -maxdepth 5 -name ".DS_Store" -delete 2>/dev/null || true
    print_success ".DS_Store bestanden verwijderd ($ds_count stuks)"
  else
    echo "  ${YELLOW}⊘${RESET} .DS_Store overgeslagen"
  fi

  # DNS cache
  if confirm_step "DNS cache flushen" ""; then
    sudo dscacheutil -flushcache 2>/dev/null && \
      sudo killall -HUP mDNSResponder 2>/dev/null && \
      print_success "DNS cache geflushed" || \
      echo "  ${YELLOW}⊘${RESET} DNS flush overgeslagen (geen sudo)"
  else
    echo "  ${YELLOW}⊘${RESET} DNS flush overgeslagen"
  fi

  print_success "Cleanup voltooid"
  UPDATED_TOOLS+=("Systeem Cleanup")
}

# ============================================================
# AANROEPEN
# ============================================================
update_macos
update_homebrew
update_mas
update_npm
update_pip
update_gems
update_rust
update_omz
update_cleanup

# ============================================================
# SAMENVATTING
# ============================================================
print_summary() {
  echo ""
  echo "${BOLD}$(printf '═%.0s' {1..40})${RESET}"
  echo "${BOLD}  Update + Cleanup voltooid${RESET}"
  echo "${BOLD}$(printf '═%.0s' {1..40})${RESET}"

  if [[ ${#UPDATED_TOOLS[@]} -gt 0 ]]; then
    echo "${GREEN}${BOLD}Bijgewerkt/Opgeschoond:${RESET}"
    for tool in "${UPDATED_TOOLS[@]}"; do
      echo "  ${GREEN}✓${RESET} $tool"
    done
  fi

  if [[ ${#SKIPPED_TOOLS[@]} -gt 0 ]]; then
    echo "${YELLOW}${BOLD}Overgeslagen (niet geïnstalleerd):${RESET}"
    for tool in "${SKIPPED_TOOLS[@]}"; do
      echo "  ${YELLOW}⊘${RESET} $tool"
    done
  fi

  if [[ ${#FAILED_TOOLS[@]} -gt 0 ]]; then
    echo "${RED}${BOLD}Mislukt:${RESET}"
    for tool in "${FAILED_TOOLS[@]}"; do
      echo "  ${RED}✗${RESET} $tool"
    done
  fi

  echo ""
}

print_summary
