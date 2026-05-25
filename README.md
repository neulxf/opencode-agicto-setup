# OpenCode + oh-my-openagent + AGICTO 配置

在新机器上快速配置 OpenCode，集成 oh-my-openagent 插件，并使用 [AGICTO](https://agicto.com/model) 作为模型提供商。

## 前置条件

- [OpenCode](https://opencode.ai/docs) 已安装
- [Bun](https://bun.sh) 已安装（`npm install -g bun`）

## 快速开始

```bash
# 克隆仓库
git clone git@github.com:neulxf/opencode-agicto-setup.git
cd opencode-agicto-setup

# 运行配置脚本（会提示输入 API Key）
./setup.sh
```

或通过环境变量提前传入：

```bash
AGICTO_API_KEY=sk-xxx ./setup.sh
```

## 脚本做了什么

1. **检查 OpenCode** 是否已安装
2. **安装 oh-my-openagent** 插件，注册到 opencode.json
3. **配置 AGICTO 提供商** — 将模板中的 API Key 占位符替换为你输入的值
4. **写入 Agent 模型映射** — 按官方最佳实践分配每个 agent 对应的模型
5. **写入 TUI 插件配置** — 激活 TUI 侧边栏
6. **运行 doctor** 验证配置

## 模型映射

### Agents

| Agent | 模型 | 价格 (输入/输出 ¥/1M) | 说明 |
|---|---|---|---|
| **Sisyphus** | `agicto/claude-opus-4-7` | ¥35/¥175 | 主编排器，最佳模型 |
| **Prometheus** | `agicto/claude-opus-4-7` | ¥35/¥175 | 战略规划 |
| **Atlas** | `agicto/claude-sonnet-4-6` | ¥21/¥105 | Todo 编排 |
| **Metis** | `agicto/claude-sonnet-4-6` | ¥21/¥105 | 计划评审 |
| **Oracle** | `agicto/gpt-5.5` | ¥35/¥210 | 架构/调试 |
| **Hephaestus** | `agicto/gpt-5.5` | ¥35/¥210 | 深度编码 |
| **Momus** | `agicto/gpt-5.5` | ¥35/¥210 | 高精度审查 |
| **Multimodal Looker** | `agicto/gpt-5.5` | ¥35/¥210 | 视觉能力 |
| **Explore** | `opencode/deepseek-v4-flash` | 免费 | 快速 grep |
| **Librarian** | `agicto/kimi-k2.6` | ¥6.5/¥27 | 文档/代码搜索 |
| **Sisyphus-Junior** | `agicto/claude-sonnet-4-6` | ¥21/¥105 | 子任务执行 |

### Categories

| 分类 | 模型 | 价格 | 说明 |
|---|---|---|---|
| **visual-engineering** | `agicto/gemini-3.1-pro-preview` | ¥14/¥84 | 前端/UI，Gemini 擅长 |
| **ultrabrain** | `agicto/gpt-5.5` | ¥35/¥210 | 高难逻辑 |
| **deep** | `agicto/claude-opus-4-7` | ¥35/¥175 | 自主深度任务 |
| **artistry** | `agicto/gpt-5.5` | ¥35/¥210 | 创造性工作 |
| **quick** | `agicto/claude-haiku-4-5-20251001` | ¥3.5/¥17.5 | 快速修改 |
| **unspecified-low** | `opencode/deepseek-v4-flash` | 免费 | 最低成本 |
| **unspecified-high** | `agicto/claude-sonnet-4-6` | ¥21/¥105 | 中等任务 |
| **writing** | `agicto/gpt-5.5` | ¥35/¥210 | 文档编写 |

## 自定义

### 修改 API Key

编辑 `~/.config/opencode/opencode.json`，替换 `apiKey` 字段。

### 修改模型分配

编辑 `~/.config/opencode/oh-my-openagent.json`，修改对应 agent 或 category 的 `model` 字段。

### 手动配置（不跑脚本）

```bash
# 1. 安装 oh-my-openagent 插件
bunx oh-my-openagent install --no-tui \
  --claude=no --openai=no --gemini=no --copilot=no \
  --opencode-zen=no --zai-coding-plan=no \
  --opencode-go=no --kimi-for-coding=no \
  --vercel-ai-gateway=no

# 2. 复制配置
cp configs/opencode.json.template ~/.config/opencode/opencode.json
# 然后手动编辑 opencode.json 填入 API Key

cp configs/oh-my-openagent.json ~/.config/opencode/oh-my-openagent.json
cp configs/tui.json ~/.config/opencode/tui.json

# 3. 验证
bunx oh-my-openagent doctor
```

## 文件结构

```
opencode-agicto-setup/
├── README.md                       # 本文件
├── setup.sh                        # 一键配置脚本
└── configs/
    ├── opencode.json.template      # 供应商配置模板（含 <YOUR_AGICTO_API_KEY> 占位）
    ├── oh-my-openagent.json        # Agent 模型映射（直接使用）
    └── tui.json                    # TUI 插件配置（直接使用）
```
