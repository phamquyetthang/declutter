#!/usr/bin/env bash
# Local models and ML library caches. The heaviest group by far, if you use them.
register_ai_model() {
  local H="$HOME"

  add green ai-ml rm "" \
    "$(L "GPU JIT cache (CUDA / Triton)" "Cache JIT của GPU (CUDA / Triton)")" \
    "$H/.nv/ComputeCache" "$H/.triton/cache"
  add green ai-ml rm "" \
    "$(L "PyTorch hub cache" "PyTorch hub cache")" "$H/.cache/torch/hub"

  add yellow ai-ml rm "" \
    "$(L "HuggingFace hub (auto-downloaded models — re-downloadable)" \
         "HuggingFace hub (model tải tự động — tải lại được)")" \
    "$H/.cache/huggingface/hub"
  add yellow ai-ml rm "" \
    "$(L "Whisper / CLIP / Keras model cache" "Whisper / CLIP / Keras model cache")" \
    "$H/.cache/whisper" "$H/.cache/clip" "$H/.keras/models"

  # Local models are never auto-deleted: tens of GB, but you chose to pull them.
  add red ai-model note "" \
    "$(L "Ollama models — remove with: ollama list && ollama rm <name>" \
         "Ollama models — gỡ bằng: ollama list && ollama rm <tên>")" "$H/.ollama/models"
  add red ai-model note "" \
    "$(L "LM Studio models" "LM Studio models")" \
    "$H/.lmstudio/models" "$H/.cache/lm-studio"
}
