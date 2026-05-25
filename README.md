# opencode-agicto-setup

Set up oh-my-openagent with the AGICTO provider, plus a mode switcher utility.

## Quick Setup — LLM Prompt

Paste this into any LLM agent session:

```
Set up oh-my-openagent on this machine by following the instructions here:
https://raw.githubusercontent.com/neulxf/opencode-agicto-setup/main/PROMPT.md
```

The agent will install the plugin, configure the AGICTO provider, map all agents to the recommended models, and verify the setup.

## Mode Switcher

A utility script to switch between OpenCode modes.

Save to a file first, then run:

```bash
# Save the script
curl -fsSLo /tmp/opencode-switcher.sh \
  https://raw.githubusercontent.com/neulxf/opencode-agicto-setup/main/opencode-switcher.sh

# Make executable and run
chmod +x /tmp/opencode-switcher.sh
bash /tmp/opencode-switcher.sh
```

Or install to PATH for easy access later:

```bash
sudo curl -fsSLo /usr/local/bin/opencode-switcher \
  https://raw.githubusercontent.com/neulxf/opencode-agicto-setup/main/opencode-switcher.sh
sudo chmod +x /usr/local/bin/opencode-switcher
opencode-switcher
```

| Option | What it does |
|---|---|
| **1) Vanilla OpenCode** | Removes oh-my-openagent plugin, restores vanilla OpenCode |
| **2) Recommended** | Enables oh-my-openagent with AGICTO model mappings (Sisyphus → Opus 4-7, Oracle → GPT-5.5, etc.) |
| **3) Custom** | Enables oh-my-openagent with a single model for all agents (e.g. `opencode/deepseek-v4-flash`) |
| **4) Exit** | Quit |

The script automatically backs up your current config when switching away from a mode, and restores it when switching back.

## Uninstalling oh-my-openagent

To fully remove oh-my-openagent:

```bash
# 1. Remove the plugin from opencode.json
jq '.plugin = [.plugin[] | select(. != "oh-my-openagent" and . != "oh-my-opencode")]' \
    ~/.config/opencode/opencode.json > /tmp/oc.json && \
    mv /tmp/oc.json ~/.config/opencode/opencode.json

# 2. Remove plugin config files
rm -f ~/.config/opencode/oh-my-openagent.json \
      ~/.config/opencode/oh-my-opencode.json \
      ~/.config/opencode/tui.json

# 3. Verify removal
opencode --version
```

Or use the switcher's option 1, which does the same thing.

## Files

| File | Purpose |
|---|---|
| `PROMPT.md` | LLM-readable setup instructions (curl and feed to any agent) |
| `opencode-switcher.sh` | Interactive mode switching script |
