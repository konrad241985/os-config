# os-config

Konrad's personal Apple Silicon macOS setup, based on [Kun Chen's dotfiles](https://github.com/kunchenguid/dotfiles). This repository includes the working local configuration and installation fixes from the original checkout. Original licenses and extension attribution are preserved.

## Fresh Mac

Use an administrator account with the macOS short username **konrad** and home directory **/Users/konrad**. This setup targets Apple Silicon, not Intel Macs or other operating systems. You need internet access and Apple's Command Line Tools (Git). If Git prompts you to install the Command Line Tools, finish that installation first.

```sh
git clone https://github.com/konrad241985/os-config.git ~/github/os-config
cd ~/github/os-config
./bootstrap.sh
```

If the repository is private, authenticate GitHub before cloning. Run bootstrap as yourself, not with `sudo`; it requests your administrator password when needed. Open a new terminal after completion.

You may clone into another directory. The fixed link **`/Users/konrad/.dotfiles` points to the actual checkout directory**. It never points back to `~/github/dotfiles` unless you run the old repository's scripts. Keep the checkout on disk: live configuration files link into it.

## What bootstrap does

1. Checks that this is an Apple Silicon Mac running under the `konrad` account.
2. Finds an existing Nix installation, including when Nix is missing from PATH, or installs Determinate Nix.
3. Sets `/Users/konrad/.dotfiles` to this checkout. A conflicting real directory is preserved with a timestamped `.before-os-config-*` suffix.
4. Backs up existing regular `/etc/bashrc` and `/etc/zshrc` files with the same suffix. Existing nix-darwin symlinks are left in place.
5. Runs the **nix-darwin version pinned by this repository's `flake.lock`**, with `nix-command` and `flakes` enabled and root's home directory selected correctly.
6. Applies system settings, adopts an existing Homebrew installation, installs declared software, and links personal configuration with Home Manager.

Conflicting personal configuration files are backed up next to the original as `*.before-nix-darwin`. Existing backups are never deliberately overwritten; if a later manually created file conflicts with an existing backup, preserve/rename that backup before retrying. A failed activation can leave some system settings already applied; fix the reported blocker and rerun bootstrap. Normal reruns reuse Nix, the managed links, and the existing Homebrew installation.

## Managed setup

- macOS defaults: dark appearance, key repeat, hidden Dock/menu bar/desktop icons, Finder list view, visible extensions, and tap-to-click.
- Homebrew: **Herdr, WezTerm, Claude Code**.
- Nix/Home Manager: **ripgrep, fd, fzf, jq, lazygit, Neovim, Hack Nerd Font**, zsh configuration, and Starship prompt.
- WezTerm, Neovim, Herdr, and Claude settings from `home/`.
- Shared agent instructions for Claude, Codex, and OpenCode.
- Pi settings, model overrides, themes, local extensions, and pinned extension package declarations. Pi itself remains optional, as described below.

This reproduces the **declared setup**, not every app, document, login, or background process on this Mac. It does not copy credentials, browser profiles, SSH keys, agent sessions, or personal data. Authenticate tools separately. Codex, OpenCode, and Pi are not automatically installed merely because their settings or shell aliases exist.

Nix dependencies are locked in `flake.lock`. Homebrew apps follow available upstream releases, and the initial Nix installer is fetched from its provider, so this is repeatable configuration rather than a byte-for-byte disk image. Neovim plugins need network access on first launch and use the copied plugin lockfile.

## Homebrew cleanup

**The retained `homebrew.onActivation.cleanup = "zap"` setting removes Homebrew packages and casks not declared in `configuration.nix`, potentially including application data.** Add software you want to keep to `brews` or `casks` before running either script. `autoMigrate = true` adopts existing Homebrew and keeps its packages during migration; the subsequent cleanup still enforces the declared package list.

## Daily use

Zsh Up/Down arrows search history for the text currently typed, like Fish. For example, type `cd` and press Up to cycle through commands containing `cd`; Down returns toward newer matches. With an empty command line, the arrows browse all history. Gray autosuggestions and Ctrl+F to accept them remain available.

Mouse interaction is enabled in Neovim (editing modes, command line, help, and prompts), with a right-click context menu. Herdr captures mouse input for its interface, shows pane scrollbars, and keeps selections highlighted until explicitly copied. Option-right-click passes through Herdr to the pane application instead of opening Herdr's pane menu. WezTerm keeps its default mouse bindings; Shift-drag bypasses application mouse handling to select terminal text. Apps without native mouse controls remain keyboard-driven. Neovim needs a restart or config reload after changing these options; Herdr supports `herdr server reload-config`, and WezTerm normally reloads its configuration automatically.

```sh
cd ~/github/os-config
./rebuild.sh
```

Run this after changing package lists, Nix configuration, or macOS defaults. Files under `home/` are linked into the live configuration, so edits there are immediately available to the relevant app (which may need a reload/restart).

Commit and push configuration changes to preserve them for a future machine. A dirty Git warning means local changes are being used, not that a rebuild failed. New files must be added to Git for Nix's Git-flake source filtering to include them.

Do not run the old `~/github/dotfiles` scripts after switching to this repository: those scripts would point `~/.dotfiles` back to the old checkout.

## Validate without applying

From this repository:

```sh
bash -n bootstrap.sh rebuild.sh
nix --extra-experimental-features 'nix-command flakes' flake check --no-build
nix --extra-experimental-features 'nix-command flakes' build .#darwinConfigurations.mac.system --no-link
```

The last command builds the system closure but does not activate it or change macOS settings.

## Files

- `flake.nix`: fixed `konrad` account, `mac` host label, dependency wiring, and the locked rebuild executable.
- `flake.lock`: exact Nix dependency revisions. Update intentionally using Nix commands.
- `configuration.nix`: macOS defaults, architecture, Homebrew migration and package lists.
- `home.nix`: user packages, shell, prompt, personal-config backups via the flake's Home Manager settings, and live file links.
- `bootstrap.sh`: first installation and safe adoption of existing shell configuration.
- `rebuild.sh`: subsequent activation using the same locked rebuild tool.
- `home/`: the copied authored configuration, not runtime data.
- `tests/`: the original Pi extension behavior tests.

`home/AGENTS.md` is the shared agent policy. The inherited `cc` alias runs Claude with `--dangerously-skip-permissions`; `co` runs Codex with `--full-auto`. Git identity is not configured by this repo; set your own name/email separately.

## Optional Pi configuration

Pi is an opt-in CLI, not a dependency this repository vendors. Install it from its owner with the [official Pi instructions](https://pi.dev), for example:

```sh
npm install -g --ignore-scripts @earendil-works/pi-coding-agent
```

[Pi Launcher](https://github.com/kunchenguid/homebrew-tap) is also optional and installed from its owner, not declared by this config:

```sh
brew install --cask kunchenguid/tap/pi-launcher
```

Home Manager owns exactly two repository-authored Pi directories: `~/.pi/agent/themes` and `~/.pi/agent/extensions`. It also links `models.json` and `settings.json` as individual files. The local extension directory is for public, repository-authored extensions only - third-party package code never belongs there. Run `/reload` after editing a local extension or other Pi resources. The terminal-title extension shows a spinner while Pi is working, then a completion mark with the session name or current directory. The `rose-pine-moon` theme was authored clean-room from the public [Rosé Pine Moon palette](https://rosepinetheme.com/palette) and Pi's [public theme schema](https://raw.githubusercontent.com/earendil-works/pi/main/packages/coding-agent/src/modes/interactive/theme/theme-schema.json), not from a private or live theme file.

### Pi Calm

`home/.pi/agent/extensions/calm` is a standalone local Pi extension. Home Manager's existing global extensions-directory link makes Pi auto-load it without another declaration. `/calm` toggles a conversation-only presentation mode and is off by default. Its choice is stored locally in `~/.pi/agent/calm` (or the directory selected by `PI_CODING_AGENT_DIR`), not in this repository or Home Manager. Adapted from Firstmate under the bundled MIT license, Calm imports no Firstmate modules and has no Firstmate runtime dependency.

When enabled, Calm hides collapsed thinking and the call/result shells for Pi's seven built-in tools (`read`, `bash`, `edit`, `write`, `grep`, `find`, and `ls`) without leaving blank transcript rows. During an active run it replaces Pi's working row with a two-line animated blue-water, yellow-boat widget. `/calm` restores Pi's stock rendering and preserves the existing Ctrl+O tool-expansion choice.

Calm never changes prompts, tool execution, model context, session data, or ordering. `/share` and `/export` use the complete stock transcript. Generic custom tools, images, and unsupported Pi transcript classes deliberately remain visible because Pi has no safe general-purpose transcript filter. If a future Pi release no longer exports the exact collapsed-thinking rendering seam, Calm logs one diagnostic and leaves only that adapter disabled; all other behavior remains available.

Pi's package system declares two third-party sources in the linked global `settings.json`:

- `npm:pi-web-access@0.14.0` - the exact public npm release for web access.
- `npm:@ryan_nookpi/pi-extension-codex-fast-mode@0.2.6` - the exact public npm release from `ryan_nookpi`.

The versions are immutable pins, so Pi does not move them during package updates. Deliberate updates require a new source and security audit, followed by an explicit pin change in `home/.pi/agent/settings.json`. On Pi 0.82.0, global settings declarations install missing pinned packages automatically at startup. No one-time install command is required. Pi keeps the downloaded npm package trees in its own unmanaged `~/.pi/agent/npm` runtime directory, outside Home Manager and Git tracking.

Both packages execute with your full user permissions and must be trusted like any other executable code.

Home Manager deliberately does not manage `~/.pi/agent` itself, or Pi authentication, sessions, trust decisions, caches, npm/git package trees, or any other runtime state. The model overrides contain no credentials or endpoint settings, do not choose a default model, and only take effect after you authenticate Pi yourself. This remains an additive post-video layer: it does not install Pi, a launcher, or package source code into this repository.

## Notes

The first time you launch `nvim`, it bootstraps [lazy.nvim](https://github.com/folke/lazy.nvim) by cloning plugins from GitHub.
That needs network access once; after that it's offline.
Neovim and WezTerm both use the rose-pine moon theme.
Neovim keeps italics off and uses a transparent background on macOS, Windows, and WSL so it matches the terminal setup.

## License

This repo is licensed under MIT No Attribution.
See `LICENSE`.
