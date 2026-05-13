#!/bin/bash
# 渲染前预检脚本 — 在 lint 之前运行本地检查
# 用法：bash preflight-check.sh <composition_dir>

COMP_DIR="${1:-composition}"
INDEX="$COMP_DIR/index.html"
ERRORS=0

echo "=== 渲染前预检: $COMP_DIR ==="

# 1. BGM 文件是实体文件（非 symlink）
echo ""
echo "[1/6] BGM 实体文件检查..."
for f in "$COMP_DIR/bgm"/*.mp3; do
  if [ -L "$f" ]; then
    echo "  ✗ $(basename "$f") 是 symlink！需要 cp 实体文件"
    ERRORS=$((ERRORS+1))
  else
    echo "  ✓ $(basename "$f") (实体文件)"
  fi
done

# 2. visibility:hidden kill 数量 = 场景数-1
echo ""
echo "[2/6] visibility:hidden 检查..."
HIDDEN_COUNT=$(grep -c "visibility.*hidden" "$INDEX" 2>/dev/null || echo 0)
echo "  visibility:hidden 出现 $HIDDEN_COUNT 次"

# 3. GSAP timeline 注册名匹配
echo ""
echo "[3/6] Timeline 注册检查..."
COMP_ID=$(grep -o 'data-composition-id="[^"]*"' "$INDEX" | head -1 | sed 's/.*"\(.*\)"/\1/')
TIMELINE_ID=$(grep -o '__timelines\["[^"]*"\]' "$INDEX" | head -1 | sed 's/.*"\(.*\)"/\1/')
if [ "$COMP_ID" = "$TIMELINE_ID" ]; then
  echo "  ✓ composition-id='$COMP_ID' = timeline['$TIMELINE_ID']"
else
  echo "  ✗ 不匹配！composition-id='$COMP_ID' vs timeline['$TIMELINE_ID']"
  ERRORS=$((ERRORS+1))
fi

# 4. 场景2+ 初始 opacity:0
echo ""
echo "[4/6] 场景 opacity 检查..."
SCENE_COUNT=$(grep -c 'id="s[0-9]"' "$INDEX" 2>/dev/null || echo 0)
OPACITY0_COUNT=$(grep -c 'opacity:0' "$INDEX" 2>/dev/null || echo 0)
echo "  场景数: $SCENE_COUNT, opacity:0 出现: $OPACITY0_COUNT"

# 5. 字幕引用的 cap id 都存在
echo ""
echo "[5/6] 字幕 ID 检查..."
CAP_DIVS=$(grep -o 'id="cap[0-9]*"' "$INDEX" | wc -l)
CAP_REFS=$(grep -o "'cap[0-9]*'" "$INDEX" | wc -l)
echo "  cap div: $CAP_DIVS, cap 引用: $CAP_REFS"

# 6. 检查缺少的必需属性
echo ""
echo "[6/6] Root 属性检查..."
for attr in "data-start" "data-width" "data-height" "data-composition-id"; do
  if grep -q "$attr=" "$INDEX"; then
    echo "  ✓ $attr"
  else
    echo "  ✗ 缺少 $attr"
    ERRORS=$((ERRORS+1))
  fi
done

echo ""
if [ $ERRORS -eq 0 ]; then
  echo "=== 预检通过 (0 errors) ==="
else
  echo "=== 预检发现 $ERRORS 个问题，请修复后再 lint ==="
  exit 1
fi
