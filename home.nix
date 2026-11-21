{ config, pkgs, user, ... }:

let
  dotfiles = "${config.home.homeDirectory}/.dotfiles";
in

{
  home.username = user;
  home.homeDirectory = "/Users/${user}";
  home.stateVersion = "24.11";
  home.packages = with pkgs; [
    # cli i use constantly
    ripgrep   # fast search
    fd        # fast find
    fzf       # fuzzy finder
    jq        # json on the command line
    lazygit
    neovim
    nodejs_24 # Runtime for Pi, Codex, Gemini, and Playwright MCP
    # the font everything renders in
    nerd-fonts.hack
  ];
  fonts.fontconfig.enable = true;
  home.sessionVariables.EDITOR = "nvim";
  home.sessionPath = [ "${dotfiles}/agent-tools/node_modules/.bin" ];

  programs.zsh = {
    enable = true;
    # Long-running Herdr servers can inherit Home Manager's source-once marker
    # with an older PATH. Apply this in each shell, outside that guarded script.
    envExtra = ''
      typeset -U path PATH
      path=("$HOME/.dotfiles/agent-tools/node_modules/.bin" "/etc/profiles/per-user/${user}/bin" $path)
      export PATH
    '';
    autosuggestion.enable = true;      # ghost text from history
    syntaxHighlighting.enable = true;  # commands turn green when valid
    historySubstringSearch = {
      enable = true;
      # Normal and application cursor-key sequences (WezTerm/Herdr).
      searchUpKey = [ "^[[A" "^[OA" ];
      searchDownKey = [ "^[[B" "^[OB" ];
    };
    initContent = ''
      bindkey '^f' autosuggest-accept
      # Ctrl-W deletes a whole whitespace-delimited word, including paths.
      autoload -Uz backward-kill-word-match
      zle -N backward-kill-space-word backward-kill-word-match
      zstyle ':zle:backward-kill-space-word' word-style whitespace
      bindkey -M emacs '^W' backward-kill-space-word
      bindkey -M viins '^W' backward-kill-space-word
      # Ctrl-arrows move across the same whitespace-delimited words.
      autoload -Uz backward-word-match forward-word-match
      zle -N backward-space-word backward-word-match
      zle -N forward-space-word forward-word-match
      zstyle ':zle:backward-space-word' word-style whitespace
      zstyle ':zle:forward-space-word' word-style whitespace
      bindkey -M emacs '^[[1;5D' backward-space-word
      bindkey -M emacs '^[[1;5C' forward-space-word
      bindkey -M viins '^[[1;5D' backward-space-word
      bindkey -M viins '^[[1;5C' forward-space-word
    '';
    shellAliases = {
      ".." = "cd ..";
      add = "git add .";
      push = "git push";
      pull = "git pull";
      m = "git switch main";
      cc = "claude --dangerously-skip-permissions";
      co = "codex --full-auto";
    };
  };

  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      format = "$directory$git_branch$git_status$cmd_duration$line_break$character";
      character = {
        success_symbol = "[❯](purple)";
        error_symbol = "[❯](red)";
      };
      cmd_duration.format = "[$duration]($style) ";
    };
  };

  # Edit-in-place: the real file stays in my repo, ~/.config just points at it.
  home.file.".config/wezterm".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/wezterm";
  home.file.".config/nvim".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/nvim";
  home.file.".config/herdr".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/herdr";
  home.file.".claude/settings.json".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.claude/settings.json";

  # Keep Pi's credential and runtime state local by linking only authored files and directories.
  home.file.".pi/agent/themes".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.pi/agent/themes";
  home.file.".pi/agent/extensions".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.pi/agent/extensions";
  home.file.".pi/agent/models.json".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.pi/agent/models.json";
  home.file.".pi/agent/settings.json".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.pi/agent/settings.json";

  home.file.".claude/CLAUDE.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
  home.file.".codex/AGENTS.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
  home.file.".config/opencode/AGENTS.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
}
