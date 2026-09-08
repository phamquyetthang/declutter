#!/usr/bin/env bash
register_dev_python() {
  local H="$HOME"
  have pip  && add green pkg-python cmd "pip cache purge" \
      "$(L "pip wheel cache" "pip wheel cache")" "$H/.cache/pip"
  have pip3 && ! have pip && add green pkg-python cmd "pip3 cache purge" \
      "$(L "pip wheel cache" "pip wheel cache")" "$H/.cache/pip"
  have uv   && add green pkg-python cmd "uv cache clean" \
      "$(L "uv cache" "uv cache")" "$H/.cache/uv"
  have conda && add yellow pkg-python cmd "conda clean --all -y" \
      "$(L "conda: tarballs + index" "conda: tarball + index")" ""

  add green pkg-python rm "" \
    "$(L "Poetry cache" "Poetry cache")" "$H/.cache/pypoetry" "$H/Library/Caches/pypoetry"

  if [ "${DEEP:-0}" = 1 ]; then
    add green pkg-python findrm "6|__pycache__" \
      "$(L "__pycache__ bytecode across \$HOME (--deep)" \
           "Bytecode __pycache__ trong \$HOME (--deep)")" "$H"
  fi
  add red pkg-python note "" \
    "$(L ".venv with torch/mediapipe: see declutter --projects" \
         ".venv có torch/mediapipe: xem declutter --projects")" ""
}
