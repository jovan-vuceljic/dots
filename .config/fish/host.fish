## wm (desktop workstation, 4K, NVIDIA) — Wingman work machine

# NVIDIA VA-API (hardware video acceleration)
set -gx LIBVA_DRIVER_NAME nvidia

# Toys built from local clones (only on this box)
alias matrix="~/projects/random-clones/matrix/matrix"

# Local llama.cpp
abbr llamacpp "~/projects/random-clones/llama.cpp/build/bin/llama-server --alias Qwen3-Coder-30B-Instruct-XXS --jinja --ctx-size 8192 --temp 1.0 --top-p 0.95 --min-p 0.01 --port 11343 -m ~/Documents/models/Qwen3-Coder-30B-A3B-Instruct-UD-IQ2_XXS.gguf"
