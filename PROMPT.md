# Setup oh-my-openagent with AGICTO Provider

## For Humans

Paste this into your LLM agent session:

```
Set up oh-my-openagent on this machine by following the instructions here:
https://raw.githubusercontent.com/neulxf/opencode-agicto-setup/main/PROMPT.md
```

## For LLM Agents

> **IMPORTANT: Use `curl` to fetch this file, NOT WebFetch.** WebFetch summarizes content and loses critical details. Always use:
>
> ```bash
> curl -fsSL https://raw.githubusercontent.com/neulxf/opencode-agicto-setup/main/PROMPT.md
> ```

If you're an LLM Agent helping set up oh-my-openagent with an AGICTO provider, welcome. You'll help your user install the harness and configure the AGICTO provider with proper model mappings.

oMoMoMoMo...

### Step 1: Check Environment

```bash
if command -v opencode &> /dev/null; then
    echo "OpenCode $(opencode --version) is installed"
else
    echo "OpenCode is not installed. Please install it first."
    echo "Ref: https://opencode.ai/docs"
fi

if command -v bun &> /dev/null; then
    echo "Bun $(bun --version) is installed"
else
    echo "Installing Bun..."
    npm install -g bun
fi
```

If OpenCode isn't installed, check the [OpenCode Installation Guide](https://opencode.ai/docs).

### Step 2: Run the Installer

```bash
bunx oh-my-openagent install --no-tui \
  --claude=no --openai=no --gemini=no --copilot=no \
  --opencode-zen=no --zai-coding-plan=no \
  --opencode-go=no --kimi-for-coding=no \
  --vercel-ai-gateway=no
```

The CLI will:
- Register the plugin in `opencode.json`
- Create the default `oh-my-openagent.json`
- Show completion summary

### Step 3: Ask User for AGICTO API Key

Ask the user:

> Please provide your AGICTO API Key (starts with `sk-...`). You can get it from https://agicto.com

If the user pastes their entire `opencode.json` with the key already in it, extract the `apiKey` value from the `agicto` provider config.

**Note**: The user does not have any official subscriptions (Claude, OpenAI, etc.) — all models are accessed via AGICTO.

### Step 4: Write opencode.json

Write the following to `~/.config/opencode/opencode.json`, replacing `<YOUR_AGICTO_API_KEY>` with the user's key:

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
          "cost": {
            "input": 5.0,
            "output": 25.0
          }
        },
        "claude-sonnet-4-6": {
          "name": "Claude Sonnet 4-6  ¥21/¥105  200Kctx",
          "cost": {
            "input": 3.0,
            "output": 15.0
          }
        },
        "claude-haiku-4-5-20251001": {
          "name": "Claude Haiku 4-5  ¥3.5/¥17.5",
          "cost": {
            "input": 0.5,
            "output": 2.5
          }
        },
        "gpt-5.5": {
          "name": "GPT-5.5  ¥35/¥210",
          "cost": {
            "input": 5.0,
            "output": 30.0
          }
        },
        "gpt-5.3-codex": {
          "name": "GPT-5.3 Codex  ¥12.25/¥98",
          "cost": {
            "input": 1.75,
            "output": 14.0
          }
        },
        "gpt-5.4": {
          "name": "GPT-5.4  ¥17.5/¥105  400Kctx",
          "cost": {
            "input": 2.5,
            "output": 15.0
          }
        },
        "gemini-3.1-pro-preview": {
          "name": "Gemini 3.1 Pro  ¥14/¥84  1Mctx",
          "cost": {
            "input": 2.0,
            "output": 12.0
          }
        },
        "gemini-3-flash-preview": {
          "name": "Gemini 3 Flash  ¥3.5/¥21",
          "cost": {
            "input": 0.5,
            "output": 3.0
          }
        },
        "kimi-k2.6": {
          "name": "Kimi K2.6  ¥6.5/¥27",
          "cost": {
            "input": 0.928571,
            "output": 3.857143
          }
        },
        "deepseek-v4-flash": {
          "name": "DeepSeek V4 Flash  ¥1/¥2",
          "cost": {
            "input": 0.142857,
            "output": 0.285714
          }
        },
        "qwen3.6-plus": {
          "name": "Qwen 3.6 Plus  ¥2/¥12",
          "cost": {
            "input": 0.285714,
            "output": 1.714286
          }
        },
        "glm-4.7": {
          "name": "GLM-4.7  ¥4/¥16",
          "cost": {
            "input": 0.571429,
            "output": 2.285714
          }
        },
        "deepseek-r1": {
          "name": "DeepSeek R1  ¥4/¥16  128Kctx",
          "cost": {
            "input": 0.571429,
            "output": 2.285714
          }
        },
        "grok-4": {
          "name": "Grok 4  ¥21/¥105  256Kctx",
          "cost": {
            "input": 3.0,
            "output": 15.0
          }
        },
        "gpt-5.4-pro": {
          "name": "GPT-5.4 Pro  ¥210/¥1260",
          "cost": {
            "input": 30.0,
            "output": 180.0
          }
        }
      }
    }
  },
  "plugin": [
    "oh-my-openagent@latest"
  ]
}
```

### Step 5: Write oh-my-openagent.json

Write the following to `~/.config/opencode/oh-my-openagent.json`:

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

### Step 6: Write tui.json

Write the following to `~/.config/opencode/tui.json`:

```json
{
  "plugin": [
    "oh-my-openagent/tui"
  ]
}
```

### Step 7: Verify

```bash
bunx oh-my-openagent doctor
```

Verify there are no errors. The only acceptable warnings are non-critical ones like "GitHub CLI not authenticated".

### Step 8: Sync Model Limits from models.dev

Run the sync-limits script to populate context/output limits from the models.dev catalog:

```bash
curl -fsSLo /tmp/sync-limits.sh \
  https://raw.githubusercontent.com/neulxf/opencode-agicto-setup/main/sync-limits.sh
bash /tmp/sync-limits.sh
```

### Step 9: Tell the User

```
  ✅ Setup complete!

  Model Usage Summary:
    Sisyphus / Prometheus / deep      → agicto/claude-opus-4-7     ¥35/¥175
    Oracle / Hephaestus / Momus        → agicto/gpt-5.5             ¥35/¥210
    atlas / metis / sisyphus-junior    → agicto/claude-sonnet-4-6   ¥21/¥105
    visual-engineering                 → agicto/gemini-3.1-pro      ¥14/¥84
    quick                              → agicto/claude-haiku-4-5    ¥3.5/¥17.5
    librarian                          → agicto/kimi-k2.6           ¥6.5/¥27
    explore / unspecified-low          → opencode/deepseek-v4-flash (free)

  Run `opencode` to start.
```
