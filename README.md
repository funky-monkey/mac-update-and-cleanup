# mac-update-and-cleanup

A single zsh script that updates and cleans your entire Mac with one command: `update`.

## What it does

### Updates
| Tool | What happens |
|------|--------------|
| Apple Software Update | `softwareupdate --install --all` |
| Homebrew | `brew update` + `upgrade` (formulae + casks `--greedy`) |
| Mac App Store | `mas upgrade` *(requires `brew install mas`)* |
| Node.js / npm | `npm install -g npm@latest` + `npm update -g` |
| Python / pip3 | `pip3 install --upgrade pip` + all outdated packages |
| Ruby gems | `gem update --system` + `gem update` + `gem cleanup` |
| Rust | `rustup update` + `cargo install-update --all` *(requires cargo-update)* |
| Oh My Zsh | `omz update --unattended` or `git pull` as fallback |

### Cleanup (CleanMyMac-style)
Runs **after** all updates. **Each step asks for confirmation** (`[y/N]`) and shows the current size so you decide what gets deleted:

| Step | What gets removed |
|------|-------------------|
| `~/Library/Caches` | User app caches |
| `~/Library/Logs` | User log files |
| Xcode DerivedData | Build artifacts |
| Xcode iOS DeviceSupport | Old device firmware files |
| npm cache | `npm cache clean --force` |
| pip3 cache | `pip cache purge` |
| Homebrew cache | `brew cleanup --prune=all` |
| Trash | Empty `~/.Trash` |
| `.DS_Store` | Up to 5 levels deep in `~` |
| DNS cache | `dscacheutil` + `mDNSResponder` flush |

> Browser caches (Chrome, Firefox, Brave, Safari) are intentionally **never** touched.

### Summary
After completion the script shows a color-coded overview:
- ✓ Updated / cleaned
- ⊘ Skipped (tool not installed)
- ✗ Failed

## Installation

```bash
git clone https://github.com/funky-monkey/mac-update-and-cleanup.git
cd mac-update-and-cleanup
./update.sh --install
```

Restart your terminal and run:

```bash
update
```

The script installs itself to `~/.local/bin/update` and adds that path to your `~/.zshrc` and `~/.bashrc`.

## Usage

```bash
update              # Update and clean everything
update --install    # (Re)install as the 'update' command
update --help       # Show help
```

## Requirements

- macOS with zsh (built-in)
- `sudo` access for Apple Software Update and DNS cache flush
- Optional: Homebrew, mas, npm, pip3, gem, rustup, Oh My Zsh

Tools that are not installed are automatically skipped.

## License

MIT
