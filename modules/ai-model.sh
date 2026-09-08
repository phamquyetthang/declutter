#!/usr/bin/env bash
# Model chạy local + cache thư viện ML. Nhóm nặng nhất nếu bạn có dùng.
register_ai_model() {
  local H="$HOME"

  add green ai-ml rm "" "Cache JIT của GPU (CUDA / Triton)" \
    "$H/.nv/ComputeCache" "$H/.triton/cache"
  add green ai-ml rm "" "PyTorch hub cache" "$H/.cache/torch/hub"

  add yellow ai-ml rm "" "HuggingFace hub (model tải tự động — tải lại được)" \
    "$H/.cache/huggingface/hub"
  add yellow ai-ml rm "" "Whisper / CLIP / Keras model cache" \
    "$H/.cache/whisper" "$H/.cache/clip" "$H/.keras/models"

  # Model local: không bao giờ tự xóa — vài chục GB nhưng là thứ user chủ động tải.
  add red ai-model note "" \
    "Ollama models — gỡ bằng: ollama list && ollama rm <tên>" "$H/.ollama/models"
  add red ai-model note "" "LM Studio models" \
    "$H/.lmstudio/models" "$H/.cache/lm-studio"
}
