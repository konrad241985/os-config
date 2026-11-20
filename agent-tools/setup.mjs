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

// This is a separate browser data directory, never the personal Chrome profile.
// Sign into konrad@nodestar.ai manually; the directory does not enforce account identity.
const browserProfile = join(home, 'Library/Application Support/os-config/playwright-nodestar');
mkdirSync(browserProfile, { recursive: true, mode: 0o700 });
const server = {
  command: '/etc/profiles/per-user/konrad/bin/node',
  args: [join(home, '.dotfiles/agent-tools/node_modules/@playwright/mcp/cli.js'), '--browser', 'chrome', '--user-data-dir', browserProfile],
};
// Merge just our server. Preserve credentials, other MCP servers, and preferences.
for (const relative of ['.pi/agent/mcp.json', '.claude.json', '.gemini/settings.json']) {
  const path = join(home, relative);
  const before = existsSync(path) ? readFileSync(path, 'utf8') : null;
  const config = before ? JSON.parse(before) : {};
  if (JSON.stringify(config.mcpServers?.['playwright-chrome']) === JSON.stringify(server)) continue;
  config.mcpServers ??= {};
  config.mcpServers['playwright-chrome'] = server;
  mkdirSync(dirname(path), { recursive: true });
  if (before !== null) copyFileSync(path, `${path}.before-agent-tools-${Date.now()}`);
  writeFileSync(path, `${JSON.stringify(config, null, 2)}\n`, { mode: 0o600 });
  console.log(`Configured Playwright Chrome in ${relative}`);
}
// Let Codex merge its own TOML, preserving desktop and unrelated settings.
const codex = join(dir, 'node_modules/.bin/codex');
let current;
try {
  current = JSON.parse(execFileSync(codex, ['mcp', 'get', 'playwright-chrome', '--json'], {
    env, stdio: ['ignore', 'pipe', 'ignore'], encoding: 'utf8',
  })).transport;
} catch { /* A fresh installation has no matching server. */ }
if (current?.command !== server.command || JSON.stringify(current?.args) !== JSON.stringify(server.args)) {
  const path = join(home, '.codex/config.toml');
  if (existsSync(path)) copyFileSync(path, `${path}.before-agent-tools-${Date.now()}`);
  execFileSync(codex, [
    'mcp', 'add', 'playwright-chrome', '--', server.command, ...server.args,
  ], { env, stdio: 'inherit' });
}
console.log(`Agent tools ready. Chrome uses only ${browserProfile}. Sign into konrad@nodestar.ai there.`);
