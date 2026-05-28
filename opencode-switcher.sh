#!/usr/bin/env bash
# =========================================================================
#  OpenCode Mode Switcher
#  Switch between vanilla OpenCode, OpenAgent recommended, and custom modes
#  Backs up config on switch-away, restores on switch-back.
# =========================================================================

set -uo pipefail

OMO_CONFIG_DIR="${HOME}/.config/opencode"
OPENCODE_JSON="${OMO_CONFIG_DIR}/opencode.json"
OMO_JSON="${OMO_CONFIG_DIR}/oh-my-openagent.json"
TUI_JSON="${OMO_CONFIG_DIR}/tui.json"
BACKUP_DIR="${OMO_CONFIG_DIR}/.omo-backups"
RECOMMENDED_BACKUP="${BACKUP_DIR}/recommended.json"
CUSTOM_BACKUP="${BACKUP_DIR}/custom.json"
PLUGIN_NAME="oh-my-openagent@latest"
PLUGIN_TUI="oh-my-openagent/tui"

# ── Colors ──
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

# ── Helpers: JSON manipulation via Python3 ──

py_read_plugin() {
    python3 -c "
import json
with open('$OPENCODE_JSON') as f:
    data = json.load(f)
plugins = data.get('plugin', [])
print('true' if '$PLUGIN_NAME' in plugins else 'false')
"
}

py_remove_plugin() {
    python3 -c "
import json
with open('$OPENCODE_JSON') as f:
    data = json.load(f)
data['plugin'] = [p for p in data.get('plugin', []) if p != '$PLUGIN_NAME']
with open('$OPENCODE_JSON', 'w') as f:
    json.dump(data, f, indent=2)
print('OK')
"
}

py_add_plugin() {
    python3 -c "
import json
with open('$OPENCODE_JSON') as f:
    data = json.load(f)
plugins = data.get('plugin', [])
if '$PLUGIN_NAME' not in plugins:
    plugins.append('$PLUGIN_NAME')
data['plugin'] = plugins
with open('$OPENCODE_JSON', 'w') as f:
    json.dump(data, f, indent=2)
print('OK')
"
}

py_models_all_same() {
    python3 -c "
import json, sys
with open('$OMO_JSON') as f:
    omo = json.load(f)
agents = omo.get('agents', {})
models = [a.get('model') for a in agents.values() if a.get('model')]
if len(models) <= 1:
    print('false')
    sys.exit(0)
first = models[0]
print('true' if all(m == first for m in models) else 'false')
" 2>/dev/null || echo "false"
}

# ── Model validation ──

py_validate_model() {
    local model="$1"

    if [[ ! "$model" == */* ]]; then
        echo "invalid:missing separator / (expected provider/model-name)"
        return 1
    fi

    local provider="${model%%/*}"
    local model_name="${model#*/}"

    if [ -z "$provider" ] || [ -z "$model_name" ] || [ ${#model_name} -lt 3 ]; then
        echo "invalid:empty or too-short provider/model-name"
        return 1
    fi

    local available
    available=$(opencode models 2>/dev/null) || true

    if [ -z "$available" ]; then
        echo "valid:cannot run opencode models, skipping"
        return 0
    fi

    if echo "$available" | grep -qxF "$model"; then
        echo "valid:found in opencode models list"
        return 0
    else
        echo "unknown_model:not found in opencode models"
        echo "hint:use \`opencode providers\` or \`/connect\` in opencode, or add \"$model\" directly to opencode.json"
        return 1
    fi
}

# ── Detect current mode ──

detect_mode() {
    if [ ! -f "$OPENCODE_JSON" ]; then
        echo "unknown"
        return
    fi

    local has_plugin
    has_plugin=$(py_read_plugin)

    if [ "$has_plugin" != "true" ]; then
        echo "original"
        return
    fi

    if [ ! -f "$OMO_JSON" ]; then
        echo "recommended"
        return
    fi

    local uniform
    uniform=$(py_models_all_same)
    if [ "$uniform" = "true" ]; then
        local model
        model=$(python3 -c "
import json
with open('$OMO_JSON') as f:
    d = json.load(f)
agents = d.get('agents', {})
for a in agents.values():
    m = a.get('model')
    if m:
        print(m)
        break
" 2>/dev/null)
        echo "custom:${model:-?}"
    else
        echo "recommended"
    fi
}

# ── Backup / Restore ──

backup_current() {
    local label="$1"  # "recommended" or "custom"
    if [ ! -f "$OMO_JSON" ]; then
        return
    fi
    # Verify the current config matches the label to prevent cross-contamination
    if [ "$label" = "recommended" ]; then
        local uniform
        uniform=$(py_models_all_same 2>/dev/null || echo "false")
        if [ "$uniform" = "true" ]; then
            echo -e "  ${YELLOW}⚠${NC} Skipped recommended backup (current config has uniform models — looks like custom mode, not recommended)"
            return
        fi
    elif [ "$label" = "custom" ]; then
        local uniform
        uniform=$(py_models_all_same 2>/dev/null || echo "true")
        if [ "$uniform" = "false" ]; then
            echo -e "  ${YELLOW}⚠${NC} Skipped custom backup (current config has diverse models — looks like recommended mode, not custom)"
            return
        fi
    fi
    mkdir -p "$BACKUP_DIR"
    cp "$OMO_JSON" "${BACKUP_DIR}/${label}.json"
    echo -e "  ${GREEN}✓${NC} Backed up current config → ${BACKUP_DIR}/${label}.json"
}

restore_recommended() {
    if [ -f "$RECOMMENDED_BACKUP" ]; then
        cp "$RECOMMENDED_BACKUP" "$OMO_JSON"
        echo -e "  ${GREEN}✓${NC} Restored oh-my-openagent.json from backup"
        return 0
    else
        return 1
    fi
}

restore_custom() {
    if [ -f "$CUSTOM_BACKUP" ]; then
        cp "$CUSTOM_BACKUP" "$OMO_JSON"
        echo -e "  ${GREEN}✓${NC} Restored oh-my-openagent.json from custom backup"
        return 0
    else
        return 1
    fi
}

# ── Mode switching actions ──

action_original() {
    local current
    current=$(detect_mode)
    local changes=()

    # Backup before switching away
    case "$current" in
        recommended) backup_current "recommended" ;;
        custom:*)    backup_current "custom" ;;
    esac

    echo -e "${YELLOW}Switching to vanilla OpenCode mode...${NC}"

    if py_remove_plugin 2>/dev/null; then
        changes+=("opencode.json: removed oh-my-openagent from plugin array")
        echo -e "  ${GREEN}✓${NC} Removed oh-my-openagent from opencode.json"
    else
        echo -e "  ${RED}✗${NC} Failed to modify opencode.json"
        return 1
    fi

    if [ -f "$TUI_JSON" ]; then
        rm -f "$TUI_JSON"
        changes+=("tui.json: deleted")
        echo -e "  ${GREEN}✓${NC} Removed tui.json"
    fi

    echo ""
    echo -e "${BOLD}Files modified:${NC}"
    for c in "${changes[@]}"; do echo "  • $c"; done
    echo ""
    echo -e "  ${GREEN}${BOLD}Vanilla OpenCode restored.${NC}"
    echo -e "  Run ${CYAN}opencode${NC} to start without oh-my-openagent."
}

action_recommended() {
    local current
    current=$(detect_mode)
    local changes=()

    # Backup before switching away
    case "$current" in
        custom:*)    backup_current "custom" ;;
    esac

    echo -e "${YELLOW}Switching to OpenAgent Recommended mode...${NC}"

    if py_add_plugin 2>/dev/null; then
        changes+=("opencode.json: added oh-my-openagent to plugin array")
        echo -e "  ${GREEN}✓${NC} Registered oh-my-openagent plugin"
    else
        echo -e "  ${RED}✗${NC} Failed to register plugin"
        return 1
    fi

    # Helper: fresh-generate recommended config into OMO_JSON
    gen_recommended() {
        cat > "$OMO_JSON" << 'OMOEOF'
{
  "$schema": "https://raw.githubusercontent.com/code-yeongyu/oh-my-openagent/dev/assets/oh-my-opencode.schema.json",
  "agents": {
    "sisyphus": { "model": "agicto/claude-opus-4-7" },
    "prometheus": { "model": "agicto/claude-opus-4-7" },
    "oracle": { "model": "agicto/gpt-5.5" },
    "hephaestus": { "model": "agicto/gpt-5.5" },
    "momus": { "model": "agicto/gpt-5.5" },
    "multimodal-looker": { "model": "agicto/gpt-5.5" },
    "metis": { "model": "agicto/claude-sonnet-4-6" },
    "atlas": { "model": "agicto/claude-sonnet-4-6" },
    "sisyphus-junior": { "model": "agicto/claude-sonnet-4-6" },
    "explore": { "model": "opencode/deepseek-v4-flash-free" },
    "librarian": { "model": "agicto/kimi-k2.6" }
  },
  "categories": {
    "visual-engineering": { "model": "agicto/gemini-3.1-pro-preview" },
    "ultrabrain": { "model": "agicto/gpt-5.5" },
    "deep": { "model": "agicto/claude-opus-4-7" },
    "artistry": { "model": "agicto/gpt-5.5" },
    "quick": { "model": "agicto/claude-haiku-4-5-20251001" },
    "unspecified-low": { "model": "opencode/deepseek-v4-flash-free" },
    "unspecified-high": { "model": "agicto/claude-sonnet-4-6" },
    "writing": { "model": "agicto/claude-sonnet-4-6" }
  }
}
OMOEOF
    }

    # Try backup restore first; verify integrity
    local restored_ok=false
    local backup_corrupted=false
    if restore_recommended; then
        local uniform
        uniform=$(py_models_all_same 2>/dev/null || echo "false")
        if [ "$uniform" = "true" ]; then
            echo -e "  ${YELLOW}⚠${NC} Backup appears corrupted (all models identical)."
            backup_corrupted=true
        else
            restored_ok=true
        fi
    fi

    if [ "$restored_ok" = "true" ]; then
        changes+=("oh-my-openagent.json: restored from backup")
    else
        if [ "$backup_corrupted" = "true" ]; then
            echo -e "     Regenerating fresh config and overwriting backup..."
        fi
        gen_recommended
        # Save fresh config as backup for future restores
        mkdir -p "$BACKUP_DIR"
        cp "$OMO_JSON" "$RECOMMENDED_BACKUP"
        changes+=("oh-my-openagent.json: fresh write with AGICTO recommended mappings; backup saved")
        echo -e "  ${GREEN}✓${NC} Wrote fresh oh-my-openagent.json (AGICTO recommended)"
    fi

    cat > "$TUI_JSON" << 'TUIEOF'
{
  "plugin": ["oh-my-openagent/tui"]
}
TUIEOF
    changes+=("tui.json: wrote TUI plugin entry")
    echo -e "  ${GREEN}✓${NC} Wrote tui.json"

    echo ""
    echo -e "${BOLD}Files modified:${NC}"
    for c in "${changes[@]}"; do echo "  • $c"; done
    echo ""
    echo -e "  ${GREEN}${BOLD}OpenAgent Recommended mode active.${NC}"
    echo -e "  Run ${CYAN}opencode${NC} to start."
}

action_custom() {
    local current
    current=$(detect_mode)
    local changes=()
    local custom_model=""

    echo ""
    echo -e "${YELLOW}OpenAgent Custom Mode${NC}"
    echo -e "All agents and categories will use the same model."
    echo ""

    # ── Offer restore from previous custom backup ──
    if [ -f "$CUSTOM_BACKUP" ]; then
        local prev_model
        prev_model=$(python3 -c "
import json
with open('$CUSTOM_BACKUP') as f:
    d = json.load(f)
for a in d.get('agents', {}).values():
    m = a.get('model')
    if m:
        print(m)
        break
" 2>/dev/null || echo "unknown")
        echo -e "  Previous custom config found: all agents → ${CYAN}${prev_model}${NC}"
        read -rp "  Restore it? [Y/n]: " restore_ans || true
        case "${restore_ans:-Y}" in
            [Yy]*|"")
                custom_model="$prev_model"
                echo ""
                echo -e "${YELLOW}Restoring from backup...${NC}"
                local restore_validation restore_valid
                restore_validation=$(py_validate_model "$prev_model" 2>&1)
                restore_valid=$?
                if [ "$restore_valid" -ne 0 ]; then
                    echo -e "  ${YELLOW}⚠${NC} Backup model '${prev_model}' may be invalid:"
                    echo -e "     ${restore_validation}"
                    read -rp "  Restore anyway? [y/N]: " force_ans || true
                    case "${force_ans:-N}" in
                        [Yy]*) ;;
                        *) echo -e "  ${RED}Cancelled.${NC}"; return 1 ;;
                    esac
                fi
                if py_add_plugin 2>/dev/null; then
                    changes+=("opencode.json: added oh-my-openagent to plugin array")
                    echo -e "  ${GREEN}✓${NC} Registered oh-my-openagent plugin"
                fi
                if [ -f "$CUSTOM_BACKUP" ]; then
                    cp "$CUSTOM_BACKUP" "$OMO_JSON"
                    changes+=("oh-my-openagent.json: restored from custom backup (${prev_model})")
                    echo -e "  ${GREEN}✓${NC} Restored oh-my-openagent.json from backup"
                else
                    echo -e "  ${RED}✗${NC} Backup file not found at ${CUSTOM_BACKUP}"
                    echo -e "  ${RED}Cancelled.${NC}"
                    return 1
                fi
                if [ ! -f "$TUI_JSON" ]; then
                    cat > "$TUI_JSON" << 'TUIEOF'
{
  "plugin": ["oh-my-openagent/tui"]
}
TUIEOF
                    changes+=("tui.json: wrote TUI plugin entry")
                    echo -e "  ${GREEN}✓${NC} Wrote tui.json"
                fi
                echo ""
                echo -e "${BOLD}Files modified:${NC}"
                for c in "${changes[@]}"; do echo "  • $c"; done
                echo ""
                echo -e "  ${GREEN}${BOLD}OpenAgent Custom mode active.${NC}"
                echo -e "  All agents set to: ${CYAN}${prev_model}${NC}"
                echo -e "  Run ${CYAN}opencode${NC} to start."
                return
                ;;
        esac
    fi

    # ── Input / validation retry loop ──
    while true; do
        echo -e "Common choices:"
        echo -e "  ${CYAN}opencode/deepseek-v4-flash-free${NC}  (free via OpenCode)"
        echo -e "  ${CYAN}deepseek/deepseek-v4-flash${NC}       (via DeepSeek provider)"
        echo -e "  ${CYAN}deepseek/deepseek-v4-pro${NC}         (via DeepSeek provider)"
        echo -e "  ${CYAN}deepseek/deepseek-reasoner${NC}        (via DeepSeek provider)"
        echo -e "  ${CYAN}agicto/claude-opus-4-7${NC}            (¥35/¥175 via AGICTO)"
        echo -e "  ${CYAN}agicto/gpt-5.5${NC}                    (¥35/¥210 via AGICTO)"
        echo -e "  ${CYAN}agicto/claude-sonnet-4-6${NC}          (¥21/¥105 via AGICTO)"
        echo -e "  ${CYAN}agicto/claude-haiku-4-5${NC}            (¥3.5/¥17.5 via AGICTO)"
        echo -e "  ${CYAN}agicto/kimi-k2.6${NC}                  (¥6.5/¥27 via AGICTO)"
        echo -e "  ${CYAN}agicto/deepseek-v4-flash${NC}           (¥1/¥2 via AGICTO)"
        echo ""
        read -rp "Enter model ID (e.g. opencode/deepseek-v4-flash-free, or empty to cancel): " custom_model || true

        if [ -z "$custom_model" ]; then
            echo -e "  ${RED}Cancelled.${NC}"
            return 1
        fi

        echo ""
        echo -e "  ${YELLOW}Validating model...${NC}"
        local validation_result validation_status
        validation_result=$(py_validate_model "$custom_model" 2>&1)
        validation_status=$?

        if [ $validation_status -eq 0 ]; then
            local model_info="${validation_result#valid:}"
            echo -e "  ${GREEN}✓${NC} Model verified: ${model_info}"
            break
        elif echo "$validation_result" | grep -q "^unknown_model:"; then
            local hint=""
            hint=$(echo "$validation_result" | grep "^hint:" | sed 's/^hint://')
            echo -e "  ${RED}✗${NC} '${custom_model}' not found in opencode models"
            [ -n "$hint" ] && echo -e "     ${hint}"
            read -rp "  Retry with a different model? [Y/n]: " confirm_ans || true
            case "${confirm_ans:-Y}" in
                [Yy]*) echo -e "  ${YELLOW}Try a different model.${NC}" ;;
                *) echo -e "  ${RED}Cancelled.${NC}"; return 1 ;;
            esac
        elif echo "$validation_result" | grep -q "^invalid:"; then
            local invalid_reason="${validation_result#invalid:}"
            echo -e "  ${RED}✗${NC} ${invalid_reason}"
            echo -e "     Must be ${CYAN}provider/model-name${NC} (e.g. opencode/deepseek-v4-flash-free)"
        else
            echo -e "  ${YELLOW}⚠${NC} Could not validate model. Proceeding..."
            break
        fi
        echo ""
    done

    # ── Backup current config before switching away ──
    if [[ "$current" == recommended ]] || [[ "$current" == custom:* ]]; then
        backup_current "${current%%:*}"
    fi

    echo ""
    echo -e "${YELLOW}Switching to OpenAgent Custom mode (${custom_model})...${NC}"

    if py_add_plugin 2>/dev/null; then
        changes+=("opencode.json: added oh-my-openagent to plugin array")
        echo -e "  ${GREEN}✓${NC} Registered oh-my-openagent plugin"
    else
        echo -e "  ${RED}✗${NC} Failed to register plugin"
        return 1
    fi

    python3 -c "
import json
config = {
    '\$schema': 'https://raw.githubusercontent.com/code-yeongyu/oh-my-openagent/dev/assets/oh-my-opencode.schema.json',
    'agents': {
        'sisyphus': {'model': '$custom_model'},
        'prometheus': {'model': '$custom_model'},
        'oracle': {'model': '$custom_model'},
        'hephaestus': {'model': '$custom_model'},
        'momus': {'model': '$custom_model'},
        'multimodal-looker': {'model': '$custom_model'},
        'metis': {'model': '$custom_model'},
        'atlas': {'model': '$custom_model'},
        'sisyphus-junior': {'model': '$custom_model'},
        'explore': {'model': '$custom_model'},
        'librarian': {'model': '$custom_model'}
    },
    'categories': {
        'visual-engineering': {'model': '$custom_model'},
        'ultrabrain': {'model': '$custom_model'},
        'deep': {'model': '$custom_model'},
        'artistry': {'model': '$custom_model'},
        'quick': {'model': '$custom_model'},
        'unspecified-low': {'model': '$custom_model'},
        'unspecified-high': {'model': '$custom_model'},
        'writing': {'model': '$custom_model'}
    }
}
with open('$OMO_JSON', 'w') as f:
    json.dump(config, f, indent=2)
print('OK')
"
    changes+=("oh-my-openagent.json: all agents model → ${custom_model}")
    changes+=("oh-my-openagent.json: all categories model → ${custom_model}")
    echo -e "  ${GREEN}✓${NC} Wrote oh-my-openagent.json (all → ${custom_model})"

    # Save as custom backup for future restore
    mkdir -p "$BACKUP_DIR"
    cp "$OMO_JSON" "$CUSTOM_BACKUP"
    echo -e "  ${GREEN}✓${NC} Saved as custom backup for future restore"

    if [ ! -f "$TUI_JSON" ]; then
        cat > "$TUI_JSON" << 'TUIEOF'
{
  "plugin": ["oh-my-openagent/tui"]
}
TUIEOF
        changes+=("tui.json: wrote TUI plugin entry")
        echo -e "  ${GREEN}✓${NC} Wrote tui.json"
    else
        changes+=("tui.json: unchanged (already exists)")
    fi

    echo ""
    echo -e "${BOLD}Files modified:${NC}"
    for c in "${changes[@]}"; do echo "  • $c"; done
    echo ""
    echo -e "  ${GREEN}${BOLD}OpenAgent Custom mode active.${NC}"
    echo -e "  All agents set to: ${CYAN}${custom_model}${NC}"
    echo -e "  Run ${CYAN}opencode${NC} to start."
}

# ── Print header ──

print_header() {
    echo ""
    echo -e "${BOLD}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}║       OpenCode Mode Switcher                ║${NC}"
    echo -e "${BOLD}╚══════════════════════════════════════════════╝${NC}"
    echo ""

    local mode
    mode=$(detect_mode)
    case "$mode" in
        original)
            echo -e "  Current mode: ${BLUE}Vanilla OpenCode${NC} (oh-my-openagent not loaded)"
            ;;
        recommended)
            echo -e "  Current mode: ${GREEN}OpenAgent Recommended${NC} (AGICTO model mappings)"
            if [ -f "$RECOMMENDED_BACKUP" ]; then
                echo -e "  Backup:       ${CYAN}available${NC}"
            fi
            ;;
        custom:*)
            local model="${mode#custom:}"
            echo -e "  Current mode: ${YELLOW}OpenAgent Custom${NC} (all → ${model})"
            if [ -f "$CUSTOM_BACKUP" ]; then
                echo -e "  Backup:       ${CYAN}available${NC}"
            fi
            ;;
        *)
            echo -e "  Current mode: ${RED}Unknown${NC}"
            ;;
    esac
    echo ""
}

# ── Main menu ──

print_menu() {
    echo -e "  ${BOLD}Select an option:${NC}"
    echo ""
    echo -e "    ${CYAN}1${NC}) Restore vanilla OpenCode (remove oh-my-openagent)"
    echo -e "    ${CYAN}2${NC}) Enable OpenAgent — Recommended mode (AGICTO models)"
    echo -e "    ${CYAN}3${NC}) Enable OpenAgent — Custom mode (unified model)"
    echo -e "    ${CYAN}4${NC}) ${BOLD}Exit${NC}"
    echo ""
}

# ── Entry point ──

main() {
    mkdir -p "$OMO_CONFIG_DIR"

    while true; do
        print_header
        print_menu

        read -rp "  Enter choice [1-4]: " choice || { echo ""; echo "stdin closed, exiting"; exit 0; }
        echo ""

        case "$choice" in
            1)
                action_original
                echo ""
                sleep 2
                ;;
            2)
                action_recommended
                echo ""
                sleep 2
                ;;
            3)
                action_custom
                echo ""
                sleep 2
                ;;
            4)
                echo -e "  ${GREEN}Bye!${NC}"
                echo ""
                exit 0
                ;;
            *)
                echo -e "  ${RED}Invalid choice.${NC}"
                sleep 1
                ;;
        esac
    done
}

main "$@"
