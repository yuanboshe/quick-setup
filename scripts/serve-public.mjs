import { spawn } from "node:child_process";
import { existsSync } from "node:fs";
import { createServer } from "node:http";
import { createReadStream } from "node:fs";
import { extname, join, normalize, relative, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const root = dirname(dirname(fileURLToPath(import.meta.url)));
const publicDir = join(root, "docs", "public");
const host = process.env.QS_PUBLIC_HOST || "127.0.0.1";
const port = Number(process.env.QS_PUBLIC_PORT || 8088);

const sync = spawn(process.platform === "win32" ? "npm.cmd" : "npm", ["run", "sync-public"], {
  cwd: root,
  stdio: "inherit",
});

const syncCode = await new Promise((resolve) => sync.on("exit", resolve));
if (syncCode !== 0) {
  process.exit(syncCode ?? 1);
}

const contentTypes = new Map([
  [".html", "text/html; charset=utf-8"],
  [".md", "text/markdown; charset=utf-8"],
  [".sh", "text/x-shellscript; charset=utf-8"],
  [".txt", "text/plain; charset=utf-8"],
  [".json", "application/json; charset=utf-8"],
]);

const server = createServer((req, res) => {
  const url = new URL(req.url || "/", `http://${host}:${port}`);
  const decodedPath = decodeURIComponent(url.pathname);
  const requested = decodedPath === "/" ? "/index.html" : decodedPath;
  const filePath = normalize(join(publicDir, requested));

  if (relative(publicDir, filePath).startsWith("..")) {
    res.writeHead(403);
    res.end("forbidden");
    return;
  }

  if (!existsSync(filePath)) {
    res.writeHead(404);
    res.end("not found");
    return;
  }

  res.writeHead(200, {
    "content-type": contentTypes.get(extname(filePath)) || "application/octet-stream",
  });
  createReadStream(filePath).pipe(res);
});

server.listen(port, host, () => {
  const base = `http://${host}:${port}`;
  console.log(`Serving docs/public at ${base}/`);
  console.log("Test install script with:");
  console.log(`curl -fsSL ${base}/install.sh | QS_INSTALL_DIR="$PWD/_tmp/qs-install/bin" AGENTS_HOME="$PWD/_tmp/qs-install/.agents" QS_AGENT_SKILL_LINKS=false bash`);
});
