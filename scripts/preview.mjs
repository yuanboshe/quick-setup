import { execFile, spawn } from "node:child_process";
import { existsSync } from "node:fs";
import net from "node:net";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const root = dirname(dirname(fileURLToPath(import.meta.url)));
const pagesOut = join(root, "docs", ".vitepress", "pages-dist");
const rawPreviewArgs = process.argv.slice(2);
const autoKillPort = !rawPreviewArgs.includes("--no-kill-port");
const previewArgs = rawPreviewArgs.filter((arg) => arg !== "--no-kill-port");

function readArg(name, shortName, fallback) {
  for (let i = 0; i < previewArgs.length; i += 1) {
    const arg = previewArgs[i];
    if (arg === name || (shortName && arg === shortName)) {
      return previewArgs[i + 1] || fallback;
    }
    if (arg.startsWith(`${name}=`)) {
      return arg.slice(name.length + 1);
    }
  }
  return fallback;
}

const port = Number(readArg("--port", "-p", "4173"));
const host = readArg("--host", "", "127.0.0.1");

function isPortOpen() {
  return new Promise((resolve) => {
    const socket = net.connect({ host, port });
    socket.setTimeout(800);
    socket.on("connect", () => {
      socket.destroy();
      resolve(true);
    });
    socket.on("timeout", () => {
      socket.destroy();
      resolve(false);
    });
    socket.on("error", () => resolve(false));
  });
}

function execText(command, args) {
  return new Promise((resolve, reject) => {
    execFile(command, args, { encoding: "utf8" }, (error, stdout, stderr) => {
      if (error) {
        error.stdout = stdout;
        error.stderr = stderr;
        reject(error);
        return;
      }
      resolve(stdout);
    });
  });
}

async function listeningPids() {
  if (process.platform === "win32") {
    const stdout = await execText("netstat", ["-ano", "-p", "tcp"]);
    const pids = new Set();
    for (const line of stdout.split(/\r?\n/)) {
      const columns = line.trim().split(/\s+/);
      if (columns.length < 5 || columns[0] !== "TCP") {
        continue;
      }
      const localAddress = columns[1];
      const state = columns[3];
      const pid = columns[4];
      if (state === "LISTENING" && localAddress.endsWith(`:${port}`) && pid !== String(process.pid)) {
        pids.add(pid);
      }
    }
    return Array.from(pids);
  }

  try {
    const stdout = await execText("lsof", ["-ti", `tcp:${port}`, "-sTCP:LISTEN"]);
    return stdout
      .split(/\s+/)
      .map((pid) => pid.trim())
      .filter((pid) => pid && pid !== String(process.pid));
  } catch {
    try {
      const stdout = await execText("ss", ["-ltnp", `sport = :${port}`]);
      return Array.from(stdout.matchAll(/pid=(\d+)/g))
        .map((match) => match[1])
        .filter((pid) => pid !== String(process.pid));
    } catch {
      return [];
    }
  }
}

async function waitForPortClosed() {
  for (let i = 0; i < 20; i += 1) {
    if (!(await isPortOpen())) {
      return true;
    }
    await new Promise((resolve) => setTimeout(resolve, 150));
  }
  return false;
}

async function killPortOwners() {
  const pids = await listeningPids();
  if (pids.length === 0) {
    throw new Error(`Port ${port} is in use, but the owning process could not be found.`);
  }

  console.log(`Stopping process on ${host}:${port}: ${pids.join(", ")}`);
  if (process.platform === "win32") {
    for (const pid of pids) {
      await execText("taskkill", ["/PID", pid, "/T", "/F"]);
    }
  } else {
    for (const pid of pids) {
      process.kill(Number(pid), "SIGTERM");
    }
  }

  if (!(await waitForPortClosed())) {
    throw new Error(`Port ${port} is still in use after stopping: ${pids.join(", ")}`);
  }
}

if (await isPortOpen()) {
  if (!autoKillPort) {
    console.log(`VitePress preview appears to already be running: http://${host}:${port}/`);
    console.log(`Stop the process listening on port ${port}, or run without --no-kill-port.`);
    process.exit(0);
  }

  try {
    await killPortOwners();
  } catch (error) {
    console.error(error.message);
    process.exit(1);
  }
}

if (!existsSync(pagesOut)) {
  console.error("Missing docs/.vitepress/pages-dist. Run npm run docs:build-pages before preview.");
  process.exit(1);
}

const vitepressBin = join(root, "node_modules", "vitepress", "bin", "vitepress.js");

const child = spawn(process.execPath, [vitepressBin, "preview", "docs", ...previewArgs], {
  cwd: root,
  env: {
    ...process.env,
    QS_DOCS_OUT_DIR: pagesOut,
  },
  stdio: "inherit",
});

child.on("exit", (code, signal) => {
  if (signal) {
    process.kill(process.pid, signal);
    return;
  }
  process.exit(code ?? 0);
});
