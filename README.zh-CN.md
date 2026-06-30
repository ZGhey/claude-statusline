# claude-statusline

[![shellcheck](https://github.com/ZGhey/claude-statusline/actions/workflows/shellcheck.yml/badge.svg)](https://github.com/ZGhey/claude-statusline/actions/workflows/shellcheck.yml)
[![release](https://img.shields.io/github/v/release/ZGhey/claude-statusline)](https://github.com/ZGhey/claude-statusline/releases/latest)

[English](README.md) · **简体中文**

> **唯一不给订阅用户显示"幻象成本"的 Claude Code 状态栏。**

一个轻量、几乎零依赖的 [Claude Code](https://code.claude.com) 状态栏 ——
单个 POSIX `sh` 脚本,无需 Node、无后台进程,只用到 `jq` 和 `awk`。

![claude-statusline](docs/statusline.svg)

## 功能特性

- **单个 POSIX `sh` 脚本** —— 无需 Node、无后台进程、无构建步骤;只依赖 `jq` + `awk`
- **一眼看清 session 状态** —— 目录、模型、上下文 %、时长、git 分支、增删行数
- **智能成本显示** —— API/console 计费时显示真实成本,Pro/Max 订阅用户自动隐藏(可用 `STATUSLINE_SHOW_COST=1` 覆盖)
- **限额追踪** —— 5 小时与 7 天用量及重置时间,按阈值着色
- **阈值着色** —— 上下文和限额字段随用量增长 绿 → 黄 → 红
- **字段自动隐藏** —— 没有数据的字段直接消失,保持状态栏整洁
- **全平台通用** —— macOS、Linux、Windows(Git Bash / WSL)
- **一键安装** —— 合并写入 `~/.claude/settings.json`,不覆盖你已有的配置
- **易于自定义** —— 每个字段都是清晰编号的代码块,可自由重排或删除
- **shellcheck CI** —— 每次 push 自动静态检查

## 为什么又造一个 statusline?

已经有不少不错的 statusline(ccstatusline、CCometixLine 等)。这个项目存在的理由就三条:

- **它不会对订阅用户谎报成本。** `total_cost_usd` 只是个"折算成 API 的估算值"——
  Pro/Max 用户付的是固定订阅费,不是这个数。本项目会判断你的计费模式(靠订阅用户专属的
  `rate_limits` 块),在显示会误导时自动隐藏它。
- **零运行时,无 Node。** 大多数功能丰富的 statusline 都是 Node/npx 包。这个就一个 POSIX
  `sh` 文件加 `jq`/`awk` —— 不往全局装东西、不用维护更新、两分钟就能审完全部代码。
- **代码归你改。** 编号清晰的字段块 + 顶部的 ANSI 颜色,几秒钟就能重排或删除,
  不用学任何配置 DSL。

想要 powerline 主题和配置 TUI?用 ccstatusline。想要小巧、诚实、可随手改的?用这个。

## 显示内容

状态栏从左到右分三组:活跃 session 信息、暗色的限额、以及推到最右边、用 `│`
单独隔开的 git 信息。

**左组(活跃信息):**

| 字段 | 示例 | 含义 |
|------|------|------|
| 目录 | `~/.claude` | 当前工作目录(青色,`~` 缩写) |
| 模型 | `opus4.8` | 当前模型,短名形式 |
| 上下文 | `ctx:42%` | 上下文窗口用量 —— 绿 / 黄(≥50%) / 红(>80%) |
| 时长 | `1m35s` | 本次 session 的实际耗时 |
| 成本 | `$1.84` | 本次 session 成本(USD)—— **仅在 API/console 计费时显示**,订阅用户隐藏(见下文) |

**中组(暗色,限额):**

| 字段 | 示例 | 含义 |
|------|------|------|
| 5h | `5h:35%` | 5 小时限额用量 —— 绿 / 黄(≥50%) / 红(>80%) |
| 重置 | `resets:10:00` | 5 小时窗口的重置时间(近期、可操作的那个) |
| 7d | `7d:58%` | 7 天(周)限额用量,颜色阈值相同 —— 放在最后,因为时效性最弱 |

**尾组(git,最右侧):**

| 字段 | 示例 | 含义 |
|------|------|------|
| 分支 | `⎇ main` | Git 分支 —— 来自 Claude Code,它不提供时自动回退用 `git` 查询 |
| 增删行 | `+156/-23` | 本次 session 中 Claude 改动的新增/删除行数 |

数据不可用时各字段会自动隐藏,保持状态栏整洁。

## 成本与订阅

`cost.total_cost_usd` 是一个**客户端估算值**,按 Claude Code 官方文档说法
"可能与你的实际账单不同"。对 Claude.ai 的 **Pro/Max 订阅用户**而言,它只是一个
"折算成 API 大概要花多少"的数字 —— 你付的是固定订阅费,而非按 token 计费 ——
所以显示它反而有误导性。

状态栏的 JSON 里没有任何计费模式字段,但 `rate_limits` 这个块**只对订阅用户出现**。
脚本就用它作为判定信号:

- **订阅用户**(存在 `rate_limits`)→ 成本**隐藏**
- **API / console 计费**(无 `rate_limits`)→ 成本**显示**(那是你真实的账单)

如需无视判定强制显示成本,设置环境变量:

```sh
export STATUSLINE_SHOW_COST=1
```

## 安装

```sh
git clone https://github.com/ZGhey/claude-statusline.git
cd claude-statusline
./install.sh
```

固定到某个 tag 版本(`v0.2.0`),而不是跟随 `main`:

```sh
git clone --branch v0.2.0 --depth 1 https://github.com/ZGhey/claude-statusline.git
cd claude-statusline
./install.sh
```

安装脚本会把 `statusline-command.sh` 复制到 `~/.claude/`,并在
`~/.claude/settings.json` 的 `statusLine` 键下注册它(采用**合并**写入,
你已有的其它配置会被保留)。开一个新 session 即可看到。

> 如果你的 Claude 配置放在别处,脚本会尊重 `$CLAUDE_CONFIG_DIR`。

### 手动安装

如果不想跑脚本,把 `statusline-command.sh` 放到任意位置,然后在
`~/.claude/settings.json` 中加入:

```json
{
  "statusLine": {
    "type": "command",
    "command": "sh /absolute/path/to/statusline-command.sh"
  }
}
```

## 依赖

- `jq` —— 解析 Claude Code 通过 stdin 传入的状态 JSON
- `awk` —— 成本字段的浮点运算

两者在 macOS 和大多数 Linux 发行版上都自带。macOS 上若缺 `jq`:
`brew install jq`。

### 平台支持

全平台通用 —— 单个 POSIX `sh` 脚本,不依赖任何特定操作系统。唯一有平台差异的地方
(`date`:BSD 的 `-r` vs GNU 的 `-d @`)已用回退方案处理,所以重置时间在各平台都能正常显示。

| 平台 | 状态 | 说明 |
|------|------|------|
| macOS | ✅ | 开箱即用(`jq`/`awk` 自带) |
| Linux | ✅ | 需装 `jq`(`apt install jq` / `dnf install jq` 等) |
| Windows | ✅(经 Git Bash 或 WSL) | Claude Code 在那里执行 `sh` 命令;需装 `jq`(`scoop install jq` / WSL 的包管理器) |

## 自定义

所有逻辑都在 `statusline-command.sh` 里。颜色是文件顶部定义的 ANSI 转义,
每个字段都是一小段清晰编号的代码块,可自由重排或删除。

**想用 git 工作区 diff 而不是 Claude 的 session 行数?** 把第 7 段里对
`total_lines_added/removed` 的读取替换成 `git -C "$current_dir" diff --shortstat`
调用即可。(默认用 JSON 里的值,零子进程开销。)

## 许可证

MIT
