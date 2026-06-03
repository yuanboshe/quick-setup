import { spawn } from "node:child_process";
import net from "node:net";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const root = dirname(dirname(fileURLToPath(import.meta.url)));
const port = 4173;
const host = "127.0.0.1";

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

if (await isPortOpen()) {
  console.log(`VitePress preview appears to already be running: http://${host}:${port}/`);
  console.log("If this is stale, stop the process listening on port 4173 and run npm run docs:preview again.");
  process.exit(0);
}

const vitepressBin = process.platform === "win32"
  ? join(root, "node_modules", ".bin", "vitepress.cmd")
  : join(root, "node_modules", ".bin", "vitepress");

const child = spawn(vitepressBin, ["preview", "docs", ...process.argv.slice(2)], {
  cwd: root,
  stdio: "inherit",
});

child.on("exit", (code, signal) => {
  if (signal) {
    process.kill(process.pid, signal);
    return;
  }
  process.exit(code ?? 0);
});
