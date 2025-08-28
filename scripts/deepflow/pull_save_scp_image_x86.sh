#!/bin/bash
# deepflow/pull_save_scp_image_amd64.sh
# 目标：仅拉取/保存 amd64 变体，并强校验；支持批量与 --rm-remote 清理
set -euo pipefail

REMOTE_HOST="${REMOTE_HOST:-root@10.1.3.179}"
DEST_DIR="${DEST_DIR:-$HOME/Desktop}"
RM_REMOTE=0

usage() {
  cat <<EOF
用法:
  $0 <image1> [image2 ...] [--rm-remote]
  $0 -f images.txt [--rm-remote]

说明:
  - 支持批量处理:
      • 多个参数:   ./pull_save_scp_image_amd64.sh image1 image2 ...
      • 文件清单:   ./pull_save_scp_image_amd64.sh -f images.txt
        (清单支持 # 注释与空行)

  - 只拉 amd64 & save amd64:
      • docker pull --platform=linux/amd64
      • docker image inspect --format '{{.Architecture}}' 二次确认
      • 以镜像ID保存，避免 tag→manifest list 在异构主机上回退到其他架构

  - 保存后校验:
      • 在远端解析 tar 的 manifest.json 和对应 config
      • 逐个检查 "architecture":"amd64"，确保 tar 内确实是 amd64

  - 可配置环境变量:
      • REMOTE_HOST   (默认 root@10.1.3.179)
      • DEST_DIR      (默认 ~/Desktop)

  - 额外选项:
      • --rm-remote   成功拷贝到本地后自动删除远端 /tmp/*.tar；
                      任一步失败也会自动清理远端临时文件，避免残留。

示例:
  $0 dfcloud-image-registry-vpc.cn-beijing.cr.aliyuncs.com/dev/df-web-ai:v6.6.18839
  $0 -f images.txt --rm-remote
EOF
}

# -------- 参数解析 --------
IMAGES=()
LIST_FILE=""
if [[ $# -eq 0 ]]; then usage; exit 1; fi

ARGS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    --rm-remote) RM_REMOTE=1; shift ;;
    -f)
      [[ $# -ge 2 ]] || { echo "❌ 缺少镜像清单文件"; exit 1; }
      LIST_FILE="$2"; shift 2 ;;
    *)
      ARGS+=("$1"); shift ;;
  esac
done

if [[ -n "$LIST_FILE" ]]; then
  [[ -f "$LIST_FILE" ]] || { echo "❌ 文件不存在: $LIST_FILE"; exit 1; }
  while IFS= read -r line; do
    line="${line%%#*}"
    line="$(echo -n "$line" | xargs || true)"
    [[ -n "$line" ]] || continue
    IMAGES+=("$line")
  done < "$LIST_FILE"
fi

if [[ ${#ARGS[@]} -gt 0 ]]; then
  IMAGES+=("${ARGS[@]}")
fi

[[ ${#IMAGES[@]} -gt 0 ]] || { echo "❌ 没有可处理的镜像"; exit 1; }

echo "🖥️ 远端: $REMOTE_HOST"
echo "💾 本地保存目录: $DEST_DIR"
echo "🧹 rm-remote: $([[ $RM_REMOTE -eq 1 ]] && echo ON || echo OFF)"
mkdir -p "$DEST_DIR"

# -------- 远端校验脚本内容（用 cat heredoc 赋值，兼容 macOS 老 bash） --------
REMOTE_VERIFY_PY="$(cat <<'PYCODE'
import sys, tarfile, json
tar_path = sys.argv[1]
with tarfile.open(tar_path, "r") as tf:
    manifest = json.load(tf.extractfile("manifest.json"))
    for item in manifest:
        cfg = item.get("Config")
        if not cfg:
            print("NO_CONFIG_IN_MANIFEST", file=sys.stderr); sys.exit(2)
        f = tf.extractfile(cfg)
        if f is None:
            print("CONFIG_NOT_FOUND", file=sys.stderr); sys.exit(3)
        cfg_json = json.load(f)
        arch = cfg_json.get("architecture")
        if arch != "amd64":
            print(f"BAD_ARCH:{arch}", file=sys.stderr); sys.exit(4)
print("OK")
PYCODE
)"

escape_for_ssh() {
  printf "%s" "$1" | python3 - <<'P'
import sys, shlex
data=sys.stdin.read()
print(shlex.quote(data))
P
}
REMOTE_VERIFY_PY_Q=$(escape_for_ssh "$REMOTE_VERIFY_PY")

# -------- 处理单个镜像 --------
process_image() {
  local IMAGE="$1"

  local NAME_TAG="${IMAGE##*/}"          # e.g. weaviate:1.30.0
  local NAME="${NAME_TAG%%:*}"           # weaviate
  local TAG="${NAME_TAG##*:}"            # 1.30.0
  if [[ "$NAME" == "$NAME_TAG" ]]; then TAG="latest"; fi

  local FILE_NAME="${NAME}-${TAG}.amd64.tar"
  local REMOTE_TAR="/tmp/${FILE_NAME}"
  local DEST_PATH="${DEST_DIR}/${FILE_NAME}"

  echo
  echo "=============================="
  echo "📦 镜像: $IMAGE"
  echo "🎯 仅拉取平台: linux/amd64"
  echo "📁 导出文件名: $FILE_NAME"
  echo "=============================="

  # 失败即清理远端临时文件
  local CLEAN_ON_FAILURE=1
  trap 'if [[ "${CLEAN_ON_FAILURE:-0}" -eq 1 ]]; then ssh -o BatchMode=yes "'"$REMOTE_HOST"'" "rm -f \"'"$REMOTE_TAR"'\"" || true; fi' RETURN

  # 1) 强制拉 amd64
  echo "🚀 远端拉取镜像..."
  ssh -o BatchMode=yes "$REMOTE_HOST" "docker pull --platform=linux/amd64 \"$IMAGE\""

  # 2) 获取 amd64 变体镜像ID
  echo "🔎 提取 amd64 镜像ID..."
  local IMAGE_ID
  IMAGE_ID="$(ssh "$REMOTE_HOST" "
    docker image inspect \"$IMAGE\" \
      --format '{{.Id}} {{.Architecture}}' 2>/dev/null \
      | awk '\$2==\"amd64\"{print \$1; exit}'
  ")"
  if [[ -z "${IMAGE_ID:-}" ]]; then
    echo "❌ 未找到 amd64 变体镜像ID，可能仓库不包含 amd64。"; return 12
  fi
  echo "✅ amd64 镜像ID: $IMAGE_ID"

  # 3) 二次确认该 ID 的架构为 amd64
  echo "🧪 inspect 架构确认..."
  ssh "$REMOTE_HOST" "
    arch=\$(docker image inspect --format '{{.Architecture}}' $IMAGE_ID | head -n1); \
    if [[ \"\$arch\" != \"amd64\" ]]; then
      echo '❌ 镜像ID架构校验失败: '\"\$arch\"; exit 13; fi; \
    echo '✅ 架构: '\"\$arch\"
  "

  # 4) 以镜像ID保存
  echo "💾 保存为: $REMOTE_TAR ..."
  ssh "$REMOTE_HOST" "docker save $IMAGE_ID > \"$REMOTE_TAR\""

  # 5) 解包校验 tar 内架构
  echo "🧬 校验 tar 包内部 architecture..."
  ssh "$REMOTE_HOST" "python3 -c $REMOTE_VERIFY_PY_Q \"$REMOTE_TAR\""

  # 6) 拷回本地
  echo "📥 拷贝到本地: $DEST_PATH ..."
  scp "$REMOTE_HOST:$REMOTE_TAR" "$DEST_PATH"

  # 7) 可选删除远端临时 tar；关闭失败清理 trap
  if [[ $RM_REMOTE -eq 1 ]]; then
    echo "🧹 删除远端临时文件: $REMOTE_TAR"
    ssh "$REMOTE_HOST" "rm -f \"$REMOTE_TAR\""
  else
    echo "ℹ️ 远端临时文件保留: $REMOTE_TAR"
  fi

  CLEAN_ON_FAILURE=0
  trap - RETURN
  echo "✅ 完成: $DEST_PATH (amd64 only)"
}

# -------- 批量执行 --------
for img in "${IMAGES[@]}"; do
  process_image "$img"
done

echo
echo "🎉 所有任务完成。"

