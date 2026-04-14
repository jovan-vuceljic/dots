local model = "Qwen3-Coder-30B-Instruct-IQ4_XS"

return {
  adapters = {
    http = {
      llama_cpp = function()
        return require("codecompanion.adapters").extend("openai_compatible", {
          env = {
            url = "http://localhost:11343",
            chat_url = "/v1/chat/completions",
            models_endpoint = "/v1/models",
            api_key = "dummy",
          },
          schema = {
            model = {
              default = model,
            },
          },
        })
      end,
    },
  },
  interactions = {
    chat = {
      adapter = "llama_cpp",
    },
    inline = {
      adapter = "llama_cpp",
    },
    cmd = {
      adapter = "llama_cpp",
    },
  },
}
