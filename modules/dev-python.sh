#!/usr/bin/env bash
register_dev_python() {
  local H="$HOME"
  have pip  && add green pkg-python cmd "pip cache purge"  "pip wheel cache" "$H/.cache/pip"
  have pip3 && ! have pip && add green pkg-python cmd "pip3 cache purge" "pip wheel cache" "$H/.cache/pip"
  have uv   && add green pkg-python cmd "uv cache clean"   "uv cache" "$H/.cache/uv"
  have conda && add yellow pkg-python cmd "conda clean --all -y" "conda: tarball + index" ""

  add green pkg-python rm "" "Poetry cache" "$H/.cache/pypoetry" "$H/Library/Caches/pypoetry"

  if [ "${DEEP:-0}" = 1 ]; then
    add green pkg-python findrm "6|__pycache__" "Bytecode __pycache__ trong \$HOME (--deep)" "$H"
  fi
  add red pkg-python note "" \
    ".venv có torch/mediapipe: xem declutter --projects" ""
}
