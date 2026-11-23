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
7. Installs the locked agent tools and matching WebKit browser, and merges the `playwright-webkit` MCP connection into Pi, Codex, Claude Code, and Gemini CLI, removing the old `playwright-chrome` connection. Rebuild also runs this step, skipping package installation when the lockfile is unchanged.

Conflicting personal configuration files are backed up next to the original as `*.before-nix-darwin`. Existing backups are never deliberately overwritten; if a later manually created file conflicts with an existing backup, preserve/rename that backup before retrying. A failed activation can leave some system settings already applied; fix the reported blocker and rerun bootstrap. Normal reruns reuse Nix, the managed links, and the existing Homebrew installation.

## Managed setup

- macOS defaults: dark appearance, key repeat, hidden Dock/menu bar/desktop icons, Finder list view, visible extensions, and tap-to-click.
- Homebrew: **Herdr, WezTerm, Claude Code, Grok Build**.
- Nix/Home Manager: **ripgrep, fd, fzf, jq, lazygit, Neovim, Node.js 24, Hack Nerd Font**, zsh configuration, and Starship prompt.
- WezTerm, Neovim, Herdr, and Claude settings from `home/`.
- Shared agent instructions for Claude, Codex, and OpenCode.
- Pi settings, model overrides, themes, local extensions, and pinned extension package declarations. Pi itself is installed by the locked agent-tools setup below.

This reproduces the **declared setup**, not every app, document, login, or background process on this Mac. It does not copy credentials, browser profiles, SSH keys, agent sessions, or personal data. Authenticate tools separately. OpenCode is not installed. Install Chrome separately on each new Mac; no browser extension is required.

Nix dependencies are locked in `flake.lock`. Homebrew apps follow available upstream releases, and the initial Nix installer is fetched from its provider, so this is repeatable configuration rather than a byte-for-byte disk image. Neovim plugins need network access on first launch and use the copied plugin lockfile.

## Homebrew cleanup

**The retained `homebrew.onActivation.cleanup = "zap"` setting removes Homebrew packages and casks not declared in `configuration.nix`, potentially including application data.** Add software you want to keep to `brews` or `casks` before running either script. `autoMigrate = true` adopts existing Homebrew and keeps its packages during migration; the subsequent cleanup still enforces the declared package list.

## Daily use

Inside Herdr, Option+Left/Right switches tabs and Option+Up/Down switches workspaces directly, with no prefix. The existing Ctrl+B then P/N tab shortcuts still work. These Option+arrow chords are reserved for Herdr navigation while Herdr is focused.

Command+Option+T creates a Herdr tab; Command+Option+W closes the active Herdr tab. The existing prefix shortcuts remain available. Outside local Herdr, these combinations create/close WezTerm tabs instead. Closing a tab closes its panes and can end running commands.

In WezTerm, Command+C copies a terminal selection. When local Herdr is in the foreground and WezTerm has no selection, Command+C is forwarded to Herdr to copy its retained mouse selection: drag normally, then press Command+C. Shift-drag still selects text directly in WezTerm, including over Neovim. With no selection, Command+C leaves the clipboard intact. Command+V pastes into the active application, including the zsh prompt. Control+C remains the shell's interrupt shortcut. Command+Left/Right switches WezTerm tabs.

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

- `flake.nix`: fixed `konrad` account, `mac` host label, dependency wiring, agent skill sources, and the locked rebuild executable.
- `flake.lock`: exact Nix dependency revisions. Update intentionally using Nix commands.
- `configuration.nix`: macOS defaults, architecture, Homebrew migration and package lists.
- `home.nix`: user packages, shell, prompt, personal-config backups via the flake's Home Manager settings, and live file links.
- `bootstrap.sh`: first installation and safe adoption of existing shell configuration.
- `rebuild.sh`: subsequent activation using the same locked rebuild tool.
- `agent-tools/package.json` and `package-lock.json`: exact CLI/MCP versions and resolved dependencies; installed into ignored `agent-tools/node_modules`.
- `agent-tools/setup.mjs`: installs locked packages and merges browser MCP settings, preserving unrelated settings and credentials. Changed JSON files get timestamped local backups.
- `home/`: the copied authored configuration, not runtime data.
- `skills.nix`: agent skills from pinned flake inputs and `home/skills/`, linked into Claude Code and Agent Skills clients.
- `tests/`: the original Pi extension behavior tests.

`home/AGENTS.md` is the shared agent policy. The inherited `cc` alias runs Claude with `--dangerously-skip-permissions`; `co` runs Codex with `--full-auto`. Git identity is not configured by this repo; set your own name/email separately.

## Coding agents and WebKit

Open a new terminal after bootstrap/rebuild. Run `pi`, `codex`, `claude`, `grok`, or `gemini`. Pi is the multi-provider interface; using a Claude, OpenAI, Gemini, or Grok model inside Pi does not launch that vendor's separate CLI application.

The npm installation pins **Pi 1.6.0, Codex CLI 0.171.0, Gemini CLI 0.70.0, and Playwright MCP 0.0.86**. Claude Code and Grok Build are managed by Homebrew. Pi uses the current official `@earendil-works/pi-coding-agent` package, which includes native MCP support. No MCP adapter is needed. Use `/login` in Pi to authenticate a supported provider and `/model` to select a model. Each standalone agent has its own sign-in flow. Grok Build's login is `grok login`. Claude Code's login is `claude auth login`.

The `playwright-webkit` MCP server launches Playwright's WebKit browser (not the Safari app) with `--user-data-dir` fixed to `~/Library/Application Support/os-config/playwright-webkit-nodestar`. Sign into **konrad@nodestar.ai** manually in this dedicated browser. Cookies and login sessions persist between launches. No Chrome cookies are copied and no Chrome extension or connection is used. The old Chrome automation profile is left untouched, but no longer used. This configuration fixes the browser profile; it does not enforce an email-account restriction or sandbox the coding agent's filesystem access.

Ask an agent: "Use playwright-webkit to check my app in the Nodestar browser." In Pi, `/mcp` shows connection status and available tools. **Only one agent should use the persistent profile at a time.** Close/disconnect its browser before switching agents. Each client starts a local MCP process; no permanent background service or public network listener is configured.

User-level configuration is merged into `~/.pi/agent/mcp.json`, `~/.codex/config.toml`, `~/.claude.json`, and `~/.gemini/settings.json`. These files remain local, including existing account credentials. The dedicated browser directory is outside the repository and is never committed. Bootstrap cannot reproduce personal logins. Restart existing agent sessions after changing MCP configuration. The old Playwright extension is no longer needed and should be removed from the personal Chrome profile.

To reapply just agent installations/settings after Nix activation, run `node agent-tools/setup.mjs`. Change exact package versions deliberately and regenerate the lockfile with npm; bootstrap/rebuild use `npm ci` rather than floating `latest` installs.

Pi defaults to the `openai-codex` provider, `gpt-6-astra`, with medium reasoning, matching the Codex CLI configuration at setup time. This uses Pi's native provider, not a subprocess running Codex CLI. Authenticate once with `pi auth login openai-codex` using your Codex account; credentials remain in local `~/.pi/agent/auth.json`. Later changes to Codex CLI's model do not automatically change Pi's default.

On this Mac, the existing Codex OAuth credentials were imported into Pi locally at the user's request and verified with a model request. No credentials are stored in this repository or imported by bootstrap. This is a one-time credential copy, not shared conversation history or ongoing synchronization: subsequent refreshes or sign-outs may require Pi to authenticate again using the command above.

Zsh adds the agent-tools and Nix user binary directories in every shell, outside Home Manager's source-once environment guard. This keeps new Herdr panes working even when their long-running server inherited an old PATH. In a shell already open during an update, run `source ~/.zshenv; rehash`.

### Pi desktop control

Bootstrap and rebuild install **Peekaboo 4.9.10** from the locked agent-tools dependencies and merge its `peekaboo` MCP server into Pi. It provides native macOS screenshots and UI interaction alongside the existing WebKit browser tools. Foreground control is enabled, so requested actions can focus windows and interact with your desktop. Requires macOS 15 or later.

On each Mac, run `peekaboo permissions status`, then follow `peekaboo permissions grant` to enable Screen Recording and Accessibility for the reported process. Background keyboard input may also require `peekaboo permissions request event-synthesizing`. These macOS grants are local and cannot be restored by copying this repository. See the [Peekaboo permissions guide](https://github.com/openclaw/Peekaboo/blob/main/docs/permissions.md).

Restart Pi or run `/reload`, then use `/mcp` to check the `peekaboo` connection. Pi supplies the model for ordinary screenshot and UI tools; Peekaboo's separate agent/provider setup is not required. Installation is CLI/MCP only, without the optional Peekaboo menu-bar app.

### Additional Pi configuration

[Pi Launcher](https://github.com/kunchenguid/homebrew-tap) is also optional and installed from its owner, not declared by this config:

```sh
brew install --cask kunchenguid/tap/pi-launcher
```

Home Manager owns exactly two repository-authored Pi directories: `~/.pi/agent/themes` and `~/.pi/agent/extensions`. It also links `models.json` and `settings.json` as individual files. The local extension directory is for public, repository-authored extensions only - third-party package code never belongs there. Run `/reload` after editing a local extension or other Pi resources. The terminal-title extension shows a spinner while Pi is working, then a completion mark with the session name or current directory. The `rose-pine-moon` theme was authored clean-room from the public [Rosé Pine Moon palette](https://rosepinetheme.com/palette) and Pi's [public theme schema](https://raw.githubusercontent.com/earendil-works/pi/main/packages/coding-agent/src/modes/interactive/theme/theme-schema.json), not from a private or live theme file.

### Pi Calm

`home/.pi/agent/extensions/calm` is a standalone local Pi extension. Home Manager's existing global extensions-directory link makes Pi auto-load it without another declaration. `/calm` toggles a conversation-only presentation mode and is off by default. Its choice is stored locally in `~/.pi/agent/calm` (or the directory selected by `PI_CODING_AGENT_DIR`), not in this repository or Home Manager. Adapted from Firstmate under the bundled MIT license, Calm imports no Firstmate modules and has no Firstmate runtime dependency.

When enabled, Calm hides collapsed thinking and the call/result shells for Pi's seven built-in tools (`read`, `bash`, `edit`, `write`, `grep`, `find`, and `ls`) without leaving blank transcript rows. During an active run it replaces Pi's working row with a two-line animated blue-water, yellow-boat widget. `/calm` restores Pi's stock rendering and preserves the existing Ctrl+O tool-expansion choice.

Calm never changes prompts, tool execution, model context, session data, or ordering. `/share` and `/export` use the complete stock transcript. Generic custom tools, images, and unsupported Pi transcript classes deliberately remain visible because Pi has no safe general-purpose transcript filter. If a future Pi release no longer exports the exact collapsed-thinking rendering seam, Calm logs one diagnostic and leaves only that adapter disabled; all other behavior remains available.

Pi's package system declares four third-party sources in the linked global `settings.json`:

- `npm:pi-web-access@0.14.0` - the exact public npm release for web access.
- `npm:@ryan_nookpi/pi-extension-codex-fast-mode@0.2.6` - the exact public npm release from `ryan_nookpi`.
- `npm:grok-pi@1.5.0` - registers the `grok-cli` provider. Each turn spawns the Homebrew `grok` binary with Grok's own tools disabled, and Pi executes the tools. Sign in with `grok login`. Model metadata is read from `~/.grok/models_cache.json` when that file exists; otherwise Pi lists Grok 4.6 and Grok 4.5. Select it with `/model` under `grok-cli`. This is separate from Pi's built-in `xai` provider.
- `npm:pi-claude-bridge@0.13.0` - registers the `claude-bridge` provider through the Claude Agent SDK and the Claude Code login from `claude auth login`. Select a `claude-bridge/...` model. Pi's built-in `anthropic/...` models do not use this bridge.

The versions are immutable pins, so Pi does not move them during package updates. Deliberate updates require a new source and security audit, followed by an explicit pin change in `home/.pi/agent/settings.json`. On Pi 0.82.0, global settings declarations install missing pinned packages automatically at startup. No one-time install command is required. Pi keeps the downloaded npm package trees in its own unmanaged `~/.pi/agent/npm` runtime directory, outside Home Manager and Git tracking.

These packages execute with your full user permissions and must be trusted like any other executable code.

Home Manager deliberately does not manage `~/.pi/agent` itself, or Pi authentication, sessions, trust decisions, caches, npm/git package trees, or any other runtime state. The model overrides contain no credentials or endpoint settings. The default provider/model are set in `settings.json`; authentication stays local. Pi itself is installed by the agent-tools setup above; a launcher is not installed.

## Agent skills

`skills.nix` links agent skills into `~/.claude/skills` (Claude Code) and `~/.agents/skills` (Pi and other Agent Skills clients). Run `./rebuild.sh` to apply. Each skill is linked individually, so skills installed by other tools can share those directories.

- The `engineering` and `productivity` skills from [mattpocock/skills](https://github.com/mattpocock/skills), and the `lavish` skill from [Lavish Editor](https://github.com/kunchenguid/lavish-axi). Both sources are flake inputs pinned in `flake.lock`; update them deliberately with `nix flake update mattpocock-skills lavish-axi`. Do not also install either through a plugin or `npx skills`, or every skill appears twice.
- `home/skills/grill-with-docs` replaces the upstream skill of the same name. It runs the same interview and docs updates, then opens an HTML summary of what will be built in Lavish Editor. Annotate anything you do not like in the browser and send it; the agent reopens those decisions and regenerates the page until you approve it.

Invoke a skill with `/<name>` in Claude Code or `/skill:<name>` in Pi. `/ask-matt` explains how the skills fit together; run `/setup-matt-pocock-skills` once in each repository before the engineering flow.

The skills are pinned, but the Lavish CLI is not: the skills run it through `npx -y lavish-axi`, which executes the latest published release with your user permissions.

## Notes

The first time you launch `nvim`, it bootstraps [lazy.nvim](https://github.com/folke/lazy.nvim) by cloning plugins from GitHub.
That needs network access once; after that it's offline.
Neovim and WezTerm both use the rose-pine moon theme.
Neovim keeps italics off and uses a transparent background on macOS, Windows, and WSL so it matches the terminal setup.

## License

This repo is licensed under MIT No Attribution.
See `LICENSE`.
