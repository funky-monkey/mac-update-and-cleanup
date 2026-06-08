# mac-update-and-cleanup

Een enkel zsh-script dat je hele Mac bijwerkt én opschoont via één commando: `update`.

## Wat het doet

### Updates
| Tool | Wat er gebeurt |
|------|----------------|
| Apple Software Update | `softwareupdate --install --all` |
| Homebrew | `brew update` + `upgrade` (formulae + casks `--greedy`) |
| Mac App Store | `mas upgrade` *(vereist `brew install mas`)* |
| Node.js / npm | `npm install -g npm@latest` + `npm update -g` |
| Python / pip3 | `pip3 install --upgrade pip` + alle outdated packages |
| Ruby gems | `gem update --system` + `gem update` + `gem cleanup` |
| Rust | `rustup update` + `cargo install-update --all` *(vereist cargo-update)* |
| Oh My Zsh | `omz update --unattended` of `git pull` als fallback |

### Cleanup (CleanMyMac-stijl)
Wordt uitgevoerd **na** alle updates. **Voor elke stap vraagt het script bevestiging** (`[j/N]`) en toont de huidige grootte zodat je bewust kiest wat je verwijdert:

| Stap | Wat er verwijderd wordt |
|------|------------------------|
| `~/Library/Caches` | User app caches |
| `~/Library/Logs` | User log bestanden |
| Xcode DerivedData | Build artefacten |
| Xcode iOS DeviceSupport | Oude device firmware bestanden |
| npm cache | `npm cache clean --force` |
| pip3 cache | `pip cache purge` |
| Homebrew cache | `brew cleanup --prune=all` |
| Prullenmand | `~/.Trash` leegmaken |
| `.DS_Store` | Max. 5 niveaus diep in `~` |
| DNS cache | `dscacheutil` + `mDNSResponder` flush |

> Browser caches (Chrome, Firefox, Brave, Safari) worden bewust **niet** aangeraakt.

### Samenvatting
Na afloop toont het script een kleurgecodeerd overzicht:
- ✓ Bijgewerkt/opgeschoond
- ⊘ Overgeslagen (tool niet geïnstalleerd)
- ✗ Mislukt

## Installatie

```bash
git clone https://github.com/funky-monkey/mac-update-and-cleanup.git
cd mac-update-and-cleanup
./update.sh --install
```

Herstart je terminal en typ:

```bash
update
```

Het script installeert zichzelf naar `~/.local/bin/update` en voegt dat pad toe aan je `~/.zshrc` en `~/.bashrc`.

## Gebruik

```bash
update              # Alles updaten + opschonen
update --install    # (Her)installeer als 'update' commando
update --help       # Toon hulptekst
```

## Vereisten

- macOS met zsh (ingebouwd)
- `sudo`-rechten voor Apple Software Update en DNS cache flush
- Optioneel: Homebrew, mas, npm, pip3, gem, rustup, Oh My Zsh

Tools die niet geïnstalleerd zijn worden automatisch overgeslagen.

## Licentie

MIT
