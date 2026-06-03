import { defineConfig } from "vitepress";
import { defineTeekConfig } from "vitepress-theme-teek/config";

const teekConfig = defineTeekConfig({
  teekTheme: true,
  teekHome: false,
  pageStyle: "default",
  sidebarTrigger: true,
  vitePlugins: {
    sidebar: false,
  },
});

const quickstart = [
  { text: "快速开始", link: "/quickstart/quickstart" },
  { text: "核心概念", link: "/quickstart/concept" },
];

const manual = [
  { text: "命令行", link: "/manual/cli" },
  { text: "recipe", link: "/manual/recipe" },
  { text: "template", link: "/manual/template" },
  { text: "template config", link: "/manual/template-config" },
  { text: "repo 与 component", link: "/manual/repo-component" },
  { text: "framework", link: "/manual/framework" },
  { text: "远程源缓存", link: "/manual/remote-source-cache" },
  { text: "运行记录", link: "/manual/run-record" },
  { text: "Agent 工作流", link: "/manual/agent-workflow" },
];

const releaseAssets = [
  { text: "下载", link: "/download/" },
  { text: "Skills", link: "/skills/" },
];

const stripMissingTeekIconfont = {
  name: "strip-missing-teek-iconfont",
  enforce: "pre" as const,
  transform(code: string, id: string) {
    if (!id.includes("vitepress-theme-teek") || !id.endsWith(".css")) {
      return;
    }

    return code.replace(
      /@font-face\{font-family:iconfont;src:url\(iconfont\.woff2\?t=\d+\) format\("woff2"\),url\(iconfont\.woff\?t=\d+\) format\("woff"\),url\(iconfont\.ttf\?t=\d+\) format\("truetype"\)\}/g,
      "",
    );
  },
};

export default defineConfig({
  extends: teekConfig,
  lang: "zh-CN",
  title: "quick-setup",
  description: "通过模板和配置快速生成 shell 脚本的工具",
  base: "/",
  cleanUrls: true,
  srcExclude: ["public/**"],
  rewrites: {
    "README.md": "index.md",
  },
  vite: {
    plugins: [stripMissingTeekIconfont],
  },
  themeConfig: {
    nav: [
      { text: "快速开始", link: "/quickstart/quickstart" },
      { text: "用户手册", link: "/manual/cli" },
      { text: "发布资产", link: "/download/" },
    ],
    sidebar: {
      "/": [
        {
          text: "快速开始",
          items: quickstart,
        },
        {
          text: "用户手册",
          items: manual,
        },
        {
          text: "发布资产",
          items: releaseAssets,
        },
      ],
    },
    search: {
      provider: "local",
    },
    socialLinks: [
      { icon: "github", link: "https://github.com/yuanboshe/quick-setup" },
    ],
  },
});
