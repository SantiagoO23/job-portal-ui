#!/usr/bin/env bash
# Claude Code status line — repo, branch, model name + context progress bar.
# Parses the JSON Claude Code pipes in via stdin using node (no jq dependency).
node -e '
const { execSync } = require("child_process");
let s = "";
process.stdin.on("data", d => (s += d)).on("end", () => {
  let j = {};
  try { j = JSON.parse(s); } catch (e) {}

  const dir =
    (j.workspace && (j.workspace.project_dir || j.workspace.current_dir)) ||
    j.cwd ||
    process.cwd();

  // Repo name = basename of the project directory.
  const repo = dir.replace(/[\\/]+$/, "").split(/[\\/]/).pop() || "repo";

  // Current git branch (best-effort; blank if not a repo).
  let branch = "";
  try {
    branch = execSync("git rev-parse --abbrev-ref HEAD", {
      cwd: dir,
      stdio: ["ignore", "pipe", "ignore"],
    }).toString().trim();
  } catch (e) {}

  const model = (j.model && j.model.display_name) || "Unknown Model";

  const dim = "\x1b[2m";
  const cyan = "\x1b[0;36m";
  const reset = "\x1b[0m";

  let prefix = `${cyan}${repo}${reset}`;
  if (branch) prefix += ` ${dim}⎇ ${branch}${reset}`;

  const cw = j.context_window;
  if (!cw || cw.context_window_size == null) {
    process.stdout.write(`${prefix} | ${model} [--------------------] --% used`);
    return;
  }

  // Precise percentage from raw token counts (moves every turn, unlike the
  // integer-rounded used_percentage). Falls back to used_percentage.
  const tokens = cw.total_input_tokens ?? 0;
  const size = cw.context_window_size || 1;
  const pct = tokens > 0 ? (tokens / size) * 100 : (cw.used_percentage ?? 0);

  const filled = Math.max(0, Math.min(20, Math.round(pct / 5)));
  const bar = "#".repeat(filled) + "-".repeat(20 - filled);
  const color = pct >= 80 ? "\x1b[0;31m" : pct >= 50 ? "\x1b[0;33m" : "\x1b[0;32m";
  const k = (n) =>
    n >= 1000000 ? (n / 1000000).toFixed(n % 1000000 === 0 ? 0 : 1) + "M"
    : n >= 1000 ? (n / 1000).toFixed(n >= 100000 ? 0 : 1) + "k"
    : String(n);
  const usage = `${k(tokens)}/${k(size)} (${pct.toFixed(1)}%)`;
  process.stdout.write(`${prefix} | ${color}${model}${reset} [${bar}] ${usage}`);
});
'
