#!/usr/bin/env bash
set -euo pipefail

OMO_CONFIG_DIR="${HOME}/.config/opencode"
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "================================================"
echo "  OpenCode + oh-my-openagent + AGICTO 配置脚本"
echo "================================================"
echo ""

# ── Step 1: 检查 OpenCode ──
echo "[1/4] 检查 OpenCode 安装..."
if command -v opencode &> /dev/null; then
    echo "  ✅ OpenCode $(opencode --version) 已安装"
else
    echo "  ❌ OpenCode 未安装，请先安装："
    echo "     https://opencode.ai/docs"
    exit 1
fi

# ── Step 2: 安装 oh-my-openagent ──
echo "[2/4] 安装 oh-my-openagent 插件..."
if ! bunx oh-my-openagent install --no-tui \
    --claude=no --openai=no --gemini=no --copilot=no \
    --opencode-zen=no --zai-coding-plan=no \
    --opencode-go=no --kimi-for-coding=no \
    --vercel-ai-gateway=no 2>&1; then
    echo "  ❌ 安装失败，请确认 bun 已安装 (npm install -g bun)"
    exit 1
fi
echo "  ✅ oh-my-openagent 插件已注册"

# ── Step 3: 写入 agicto 配置 ──
echo "[3/4] 配置 AGICTO 提供商..."

API_KEY="${AGICTO_API_KEY:-}"
if [ -z "$API_KEY" ]; then
    read -rp "  请输入你的 AGICTO API Key (sk-...): " API_KEY
fi

if [ -z "$API_KEY" ]; then
    echo "  ❌ API Key 不能为空"
    exit 1
fi

# 生成 opencode.json（替换 API key 占位符）
sed "s|<YOUR_AGICTO_API_KEY>|${API_KEY}|g" \
    "${REPO_DIR}/configs/opencode.json.template" > "${OMO_CONFIG_DIR}/opencode.json"
echo "  ✅ opencode.json 已写入 (含 AGICTO 提供商 + 价格)"

# 写入 oh-my-openagent.json（agent 模型映射）
cp "${REPO_DIR}/configs/oh-my-openagent.json" "${OMO_CONFIG_DIR}/oh-my-openagent.json"
echo "  ✅ oh-my-openagent.json 已写入 (Agent 模型映射)"

# 写入 tui.json（TUI 插件）
cp "${REPO_DIR}/configs/tui.json" "${OMO_CONFIG_DIR}/tui.json"
echo "  ✅ tui.json 已写入 (TUI 插件)"

# ── Step 4: 验证 ──
echo "[4/4] 验证配置..."
if command -v bun &> /dev/null && bunx oh-my-openagent doctor 2>&1; then
    echo ""
    echo "  ✅ 配置完成！运行 opencode 即可使用"
else
    echo "  ⚠️  doctor 检查有警告，请查看上方输出"
fi

echo ""
echo "================================================"
echo "  配置完成！"
echo "================================================"
echo ""
echo "  模型使用概览："
echo "    Sisyphus / Prometheus / deep      → agicto/claude-opus-4-7"
echo "    Oracle / Hephaestus / Momus        → agicto/gpt-5.5"
echo "    atlas / metis / sisyphus-junior    → agicto/claude-sonnet-4-6"
echo "    visual-engineering                 → agicto/gemini-3.1-pro-preview"
echo "    quick                              → agicto/claude-haiku-4-5"
echo "    librarian                          → agicto/kimi-k2.6"
echo "    explore / unspecified-low          → opencode/deepseek-v4-flash (免费)"
echo ""
echo "  提示：可通过 AGICTO_API_KEY 环境变量避免交互输入"
echo "    AGICTO_API_KEY=sk-xxx ./setup.sh"
