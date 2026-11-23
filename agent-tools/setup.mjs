// Run after nix-darwin activation, as the user, never as root.
import { readFileSync, writeFileSync, existsSync, mkdirSync, copyFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { homedir } from 'node:os';
import { fileURLToPath } from 'node:url';
import { execFileSync } from 'node:child_process';

if (process.getuid() === 0) throw new Error('Run agent setup as your regular user.');
const dir = dirname(fileURLToPath(import.meta.url));
const home = homedir();
const env = { ...process.env, PATH: `${dirname(process.execPath)}:${process.env.PATH}` };
const lock = readFileSync(join(dir, 'package-lock.json'), 'utf8');
const stamp = join(dir, 'node_modules/.os-config-lock.json');
if (!existsSync(stamp) || readFileSync(stamp, 'utf8') !== lock) {
  execFileSync('npm', ['ci', '--no-audit', '--no-fund'], { cwd: dir, env, stdio: 'inherit' });
  writeFileSync(stamp, lock);
}

// Install the WebKit revision matching the locked Playwright MCP dependency.
execFileSync(process.execPath, [join(dir, 'node_modules/playwright/cli.js'), 'install', 'webkit'], {
  env, stdio: 'inherit',
});

// This is a separate WebKit data directory, never a Chrome profile.
// Sign into konrad@nodestar.ai manually; the directory does not enforce account identity.
const browserProfile = join(home, 'Library/Application Support/os-config/playwright-webkit-nodestar');
mkdirSync(browserProfile, { recursive: true, mode: 0o700 });
const server = {
  command: '/etc/profiles/per-user/konrad/bin/node',
  args: [join(home, '.dotfiles/agent-tools/node_modules/@playwright/mcp/cli.js'), '--browser', 'webkit', '--user-data-dir', browserProfile],
};
// Merge just our server. Preserve credentials, other MCP servers, and preferences.
for (const relative of ['.pi/agent/mcp.json', '.claude.json', '.gemini/settings.json']) {
  const path = join(home, relative);
  const before = existsSync(path) ? readFileSync(path, 'utf8') : null;
  const config = before ? JSON.parse(before) : {};
  if (!config.mcpServers?.['playwright-chrome'] && JSON.stringify(config.mcpServers?.['playwright-webkit']) === JSON.stringify(server)) continue;
  config.mcpServers ??= {};
  delete config.mcpServers['playwright-chrome'];
  config.mcpServers['playwright-webkit'] = server;
  mkdirSync(dirname(path), { recursive: true });
  if (before !== null) copyFileSync(path, `${path}.before-agent-tools-${Date.now()}`);
  writeFileSync(path, `${JSON.stringify(config, null, 2)}\n`, { mode: 0o600 });
  console.log(`Configured Playwright WebKit in ${relative}`);
}
// Let Codex merge its own TOML, preserving desktop and unrelated settings.
const codex = join(dir, 'node_modules/.bin/codex');
const codexConfig = join(home, '.codex/config.toml');
// Back up at most once per run, and only when Codex is about to rewrite the file.
let codexBackedUp = false;
const backupCodexConfig = () => {
  if (codexBackedUp || !existsSync(codexConfig)) return;
  copyFileSync(codexConfig, `${codexConfig}.before-agent-tools-${Date.now()}`);
  codexBackedUp = true;
};
if (existsSync(codexConfig) && readFileSync(codexConfig, 'utf8').includes('playwright-chrome')) {
  backupCodexConfig();
  execFileSync(codex, ['mcp', 'remove', 'playwright-chrome'], { env, stdio: 'inherit' });
}
let current;
try {
  current = JSON.parse(execFileSync(codex, ['mcp', 'get', 'playwright-webkit', '--json'], {
    env, stdio: ['ignore', 'pipe', 'ignore'], encoding: 'utf8',
  })).transport;
} catch { /* A fresh installation has no matching server. */ }
if (current?.command !== server.command || JSON.stringify(current?.args) !== JSON.stringify(server.args)) {
  backupCodexConfig();
  execFileSync(codex, [
    'mcp', 'add', 'playwright-webkit', '--', server.command, ...server.args,
  ], { env, stdio: 'inherit' });
}
console.log(`Agent tools ready. WebKit uses only ${browserProfile}. Sign into konrad@nodestar.ai there.`);

// Desktop control is configured for Pi only; macOS permission grants stay local.
const piMcpPath = join(home, '.pi/agent/mcp.json');
const piMcpBefore = readFileSync(piMcpPath, 'utf8');
const piMcp = JSON.parse(piMcpBefore);
const peekaboo = {
  command: join(home, '.dotfiles/agent-tools/node_modules/.bin/peekaboo'),
  args: ['mcp', '--allow-foreground'],
};
if (JSON.stringify(piMcp.mcpServers.peekaboo) !== JSON.stringify(peekaboo)) {
  piMcp.mcpServers.peekaboo = peekaboo;
  copyFileSync(piMcpPath, `${piMcpPath}.before-agent-tools-${Date.now()}`);
  writeFileSync(piMcpPath, `${JSON.stringify(piMcp, null, 2)}\n`, { mode: 0o600 });
  console.log('Configured Peekaboo desktop control in Pi. Run peekaboo permissions status to check macOS grants.');
}
