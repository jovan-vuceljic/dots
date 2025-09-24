-- load defaults i.e lua_lsp
require("nvchad.configs.lspconfig").defaults()

local servers = { "html", "cssls", "ts_ls", "python_lsp_server", "eslint" }
vim.lsp.enable(servers)
