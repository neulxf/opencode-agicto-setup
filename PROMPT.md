# OpenCode + oh-my-openagent + AGICTO 配置指南

> 将此文件的原始内容粘贴给 LLM Agent，或将 raw URL 交给 LLM 自行读取。
>
> **LLM Agent 请使用 curl 获取此文件：**
> ```bash
> curl -fsSL https://raw.githubusercontent.com/neulxf/opencode-agicto-setup/main/PROMPT.md
> ```

oMoMoMoMo...

## 任务

为当前机器配置 OpenCode，安装 oh-my-openagent 插件，并将所有 agent 模型映射到 AGICTO (agicto.com) 提供商。

## 用户信息

- 用户 OpenCode 经验：有，已安装
- 模型提供商：AGICTO (https://agicto.com/model)，通过 `@ai-sdk/openai-compatible` 兼容层调用
- API 地址：`https://api.agicto.cn/v1`
- 官方订阅：无

## 步骤

### Step 1：检查环境

```bash
if command -v opencode &> /dev/null; then
    echo "OpenCode $(opencode --version) 已安装"
else
    echo "OpenCode 未安装，请先安装：https://opencode.ai/docs"
    exit 1
fi

if command -v bun &> /dev/null; then
    echo "Bun $(bun --version) 已安装"
else
    echo "正在安装 Bun..."
    npm install -g bun
fi
```

### Step 2：安装 oh-my-openagent 插件

```bash
bunx oh-my-openagent install --no-tui \
  --claude=no --openai=no --gemini=no --copilot=no \
  --opencode-zen=no --zai-coding-plan=no \
  --opencode-go=no --kimi-for-coding=no \
  --vercel-ai-gateway=no
```

### Step 3：询问用户 AGICTO API Key

> **向用户询问：**
>
> ```
> 请输入你的 AGICTO API Key (sk-...):
> ```
>
> 从用户的回答中获取 API Key。如果用户粘贴的是包含整个 opencode.json 的内容，提取其中的 `apiKey` 值。

### Step 4：写入 opencode.json

将以下内容写入 `~/.config/opencode/opencode.json`，将 `<YOUR_AGICTO_API_KEY>` 替换为用户的 API Key。

```json
{
  "$schema": "https://opencode.ai/config.json",
  "provider": {
    "agicto": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "AGICTO",
      "options": {
        "baseURL": "https://api.agicto.cn/v1",
        "apiKey": "<YOUR_AGICTO_API_KEY>"
      },
      "models": {
        "claude-opus-4-7": {
          "name": "Claude Opus 4-7  ¥35/¥175",
          "inputPrice": 35,
          "outputPrice": 175
        },
        "claude-sonnet-4-6": {
          "name": "Claude Sonnet 4-6  ¥21/¥105  200Kctx",
          "inputPrice": 21,
          "outputPrice": 105
        },
        "claude-haiku-4-5-20251001": {
          "name": "Claude Haiku 4-5  ¥3.5/¥17.5",
          "inputPrice": 3.5,
          "outputPrice": 17.5
        },
        "gpt-5.5": {
          "name": "GPT-5.5  ¥35/¥210",
          "inputPrice": 35,
          "outputPrice": 210
        },
        "gpt-5.3-codex": {
          "name": "GPT-5.3 Codex  ¥12.25/¥98",
          "inputPrice": 12.25,
          "outputPrice": 98
        },
        "gpt-5.4": {
          "name": "GPT-5.4  ¥17.5/¥105  400Kctx",
          "inputPrice": 17.5,
          "outputPrice": 105
        },
        "gemini-3.1-pro-preview": {
          "name": "Gemini 3.1 Pro  ¥14/¥84  1Mctx",
          "inputPrice": 14,
          "outputPrice": 84
        },
        "gemini-3-flash-preview": {
          "name": "Gemini 3 Flash  ¥3.5/¥21",
          "inputPrice": 3.5,
          "outputPrice": 21
        },
        "kimi-k2.6": {
          "name": "Kimi K2.6  ¥6.5/¥27",
          "inputPrice": 6.5,
          "outputPrice": 27
        },
        "deepseek-v4-flash": {
          "name": "DeepSeek V4 Flash  ¥1/¥2",
          "inputPrice": 1,
          "outputPrice": 2
        },
        "qwen3.6-plus": {
          "name": "Qwen 3.6 Plus  ¥2/¥12",
          "inputPrice": 2,
          "outputPrice": 12
        },
        "glm-4.7": {
          "name": "GLM-4.7  ¥4/¥16",
          "inputPrice": 4,
          "outputPrice": 16
        },
        "deepseek-r1": {
          "name": "DeepSeek R1  ¥4/¥16  128Kctx",
          "inputPrice": 4,
          "outputPrice": 16
        },
        "grok-4": {
          "name": "Grok 4  ¥21/¥105  256Kctx",
          "inputPrice": 21,
          "outputPrice": 105
        },
        "gpt-5.4-pro": {
          "name": "GPT-5.4 Pro  ¥210/¥1260",
          "inputPrice": 210,
          "outputPrice": 1260
        }
      }
    }
  },
  "plugin": [
    "oh-my-openagent@latest"
  ]
}
```

### Step 5：写入 oh-my-openagent.json

将以下内容写入 `~/.config/opencode/oh-my-openagent.json`：

```json
{
  "$schema": "https://raw.githubusercontent.com/code-yeongyu/oh-my-openagent/dev/assets/oh-my-opencode.schema.json",
  "agents": {
    "sisyphus": {
      "model": "agicto/claude-opus-4-7"
    },
    "prometheus": {
      "model": "agicto/claude-opus-4-7"
    },
    "atlas": {
      "model": "agicto/claude-sonnet-4-6"
    },
    "metis": {
      "model": "agicto/claude-sonnet-4-6"
    },
    "oracle": {
      "model": "agicto/gpt-5.5"
    },
    "hephaestus": {
      "model": "agicto/gpt-5.5"
    },
    "momus": {
      "model": "agicto/gpt-5.5"
    },
    "multimodal-looker": {
      "model": "agicto/gpt-5.5"
    },
    "explore": {
      "model": "opencode/deepseek-v4-flash"
    },
    "librarian": {
      "model": "agicto/kimi-k2.6"
    },
    "sisyphus-junior": {
      "model": "agicto/claude-sonnet-4-6"
    }
  },
  "categories": {
    "visual-engineering": {
      "model": "agicto/gemini-3.1-pro-preview"
    },
    "ultrabrain": {
      "model": "agicto/gpt-5.5"
    },
    "deep": {
      "model": "agicto/claude-opus-4-7"
    },
    "artistry": {
      "model": "agicto/gpt-5.5"
    },
    "quick": {
      "model": "agicto/claude-haiku-4-5-20251001"
    },
    "unspecified-low": {
      "model": "opencode/deepseek-v4-flash"
    },
    "unspecified-high": {
      "model": "agicto/claude-sonnet-4-6"
    },
    "writing": {
      "model": "agicto/claude-sonnet-4-6"
    }
  }
}
```

### Step 6：写入 tui.json

将以下内容写入 `~/.config/opencode/tui.json`：

```json
{
  "plugin": ["oh-my-openagent/tui"]
}
```

### Step 7：验证

```bash
bunx oh-my-openagent doctor
```

确认输出中无错误。只允许出现 "GitHub CLI not authenticated" 这类可选的提示。

### Step 8：告知用户

配置完成后告知用户：

```
✅ 配置完成！

模型使用概览：
  Sisyphus / Prometheus / deep      → agicto/claude-opus-4-7     ¥35/¥175
  Oracle / Hephaestus / Momus        → agicto/gpt-5.5             ¥35/¥210
  atlas / metis / sisyphus-junior    → agicto/claude-sonnet-4-6   ¥21/¥105
  visual-engineering                 → agicto/gemini-3.1-pro      ¥14/¥84
  quick                              → agicto/claude-haiku-4-5    ¥3.5/¥17.5
  librarian                          → agicto/kimi-k2.6           ¥6.5/¥27
  explore / unspecified-low          → opencode/deepseek-v4-flash (免费)

运行 opencode 即可使用。
```

如果不小心使用了其他模型，可以运行 `curl -fsSL <本文件 URL> | bunx oh-my-openagent doctor` 来对比配置是否符合预期。

> **提示：** 此 prompt 也放在 GitHub 仓库 https://github.com/neulxf/opencode-agicto-setup 中。
