import { copyFileSync, mkdirSync, rmSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const root = dirname(dirname(fileURLToPath(import.meta.url)));

const copies = [
  ["scripts/install.sh", "docs/public/install.sh"],
  ["versions.json", "docs/public/versions.json"],
  ["skills/qs-cmd/SKILL.md", "docs/public/skills/qs-cmd/SKILL.md"],
  ["skills/qs-repo/SKILL.md", "docs/public/skills/qs-repo/SKILL.md"],
];

rmSync(join(root, "docs/public/skills"), { recursive: true, force: true });

for (const [source, target] of copies) {
  const targetPath = join(root, target);
  mkdirSync(dirname(targetPath), { recursive: true });
  copyFileSync(join(root, source), targetPath);
}
