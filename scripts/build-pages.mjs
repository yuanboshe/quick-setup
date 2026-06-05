import { spawn } from "node:child_process";
import { cpSync, existsSync, mkdtempSync, readFileSync, rmSync } from "node:fs";
import { copyFileSync, mkdirSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { tmpdir } from "node:os";

const root = dirname(dirname(fileURLToPath(import.meta.url)));
const pagesOut = join(root, "docs", ".vitepress", "pages-dist");
const versions = JSON.parse(readFileSync(join(root, "versions.json"), "utf8"));
const current = versions.current;

function vitepressBin(cwd = root) {
  return join(cwd, "node_modules", "vitepress", "bin", "vitepress.js");
}

function npmCommand(args) {
  if (process.platform === "win32") {
    return ["cmd.exe", ["/d", "/s", "/c", "npm", ...args]];
  }
  return ["npm", args];
}

function run(command, args, options = {}) {
  return new Promise((resolveRun, rejectRun) => {
    const child = spawn(command, args, {
      cwd: options.cwd || root,
      env: { ...process.env, ...(options.env || {}) },
      stdio: "inherit",
    });
    child.on("exit", (code) => {
      if (code === 0) {
        resolveRun();
        return;
      }
      rejectRun(new Error(`${command} ${args.join(" ")} exited with ${code}`));
    });
  });
}

async function gitRefExists(ref) {
  return new Promise((resolveRef) => {
    const child = spawn("git", ["rev-parse", "-q", "--verify", ref], {
      cwd: root,
      stdio: "ignore",
    });
    child.on("exit", (code) => resolveRef(code === 0));
  });
}

function copyIfExists(source, target) {
  if (!existsSync(source)) {
    return;
  }
  mkdirSync(dirname(target), { recursive: true });
  copyFileSync(source, target);
}

async function buildCurrent() {
  await run(process.execPath, [join(root, "scripts", "sync-public-assets.mjs")]);
  await run(process.execPath, [vitepressBin(), "build", "docs"], {
    env: {
      QS_DOCS_VERSION: current,
      QS_DOCS_BASE: "/",
      QS_DOCS_OUT_DIR: pagesOut,
    },
  });
}

async function buildVersion(entry) {
  if (!entry.tag || entry.url === "/") {
    return;
  }

  if (!(await gitRefExists(`refs/tags/${entry.tag}`))) {
    await run("git", ["fetch", "--tags", "--force", "origin", `refs/tags/${entry.tag}:refs/tags/${entry.tag}`]);
  }
  if (!(await gitRefExists(`refs/tags/${entry.tag}`))) {
    throw new Error(`versions.json 引用了不存在的文档 tag：${entry.tag}`);
  }

  const worktreeParent = mkdtempSync(join(tmpdir(), "qs-docs-version-"));
  const worktree = join(worktreeParent, entry.tag.replace(/[^0-9A-Za-z_.-]/g, "-"));
  const targetOut = join(pagesOut, entry.url.replace(/^\/|\/$/g, ""));

  try {
    await run("git", ["worktree", "add", "--detach", worktree, entry.tag]);
    const [npm, npmArgs] = npmCommand(["ci"]);
    await run(npm, npmArgs, { cwd: worktree });
    await run(process.execPath, [join(worktree, "scripts", "sync-public-assets.mjs")], { cwd: worktree });
    await run(process.execPath, [vitepressBin(worktree), "build", "docs"], {
      cwd: worktree,
      env: {
        QS_DOCS_VERSION: entry.version,
        QS_DOCS_BASE: entry.url,
        QS_DOCS_OUT_DIR: targetOut,
      },
    });
    if (!existsSync(targetOut)) {
      const legacyOut = join(worktree, "docs", ".vitepress", "dist");
      if (!existsSync(legacyOut)) {
        throw new Error(`文档 tag ${entry.tag} 没有生成 VitePress dist 目录。`);
      }
      cpSync(legacyOut, targetOut, { recursive: true });
    }
  } finally {
    await run("git", ["worktree", "remove", "--force", worktree]).catch(() => {});
    rmSync(worktreeParent, { recursive: true, force: true });
  }
}

rmSync(pagesOut, { recursive: true, force: true });
mkdirSync(pagesOut, { recursive: true });

await buildCurrent();

for (const entry of versions.versions || []) {
  await buildVersion(entry);
}

copyIfExists(join(root, "docs", "public", "versions.json"), join(pagesOut, "versions.json"));
