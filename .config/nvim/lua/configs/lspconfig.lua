require("nvchad.configs.lspconfig").defaults()

local servers = { "html", "cssls", "ts_ls", "eslint" }
vim.lsp.enable(servers)

-- Waybar/GTK stylesheets are GTK CSS, a different dialect: `@name` references
-- @define-color colors (waybar's theme.css) and functions like alpha() are
-- valid there but not in web CSS, so cssls floods "property value expected" /
-- "{ expected" false errors. No LSP speaks the GTK dialect, so keep cssls
-- attached (standard-property completion still useful) and mute diagnostics
-- on those buffers only.
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if not client or client.name ~= "cssls" then
      return
    end
    local path = vim.api.nvim_buf_get_name(args.buf)
    if path:match "/waybar/" or path:match "/gtk%-%d" then
      vim.diagnostic.enable(false, { bufnr = args.buf })
    end
  end,
})

-- local lspconfig = require "lspconfig"
-- local nvlsp = require "nvchad.configs.lspconfig"
--
-- -- lsps with default config
-- for _, lsp in ipairs(servers) do
--   lspconfig[lsp].setup {
--     on_attach = nvlsp.on_attach,
--     on_init = nvlsp.on_init,
--     capabilities = nvlsp.capabilities,
--   }
-- end
--
-- -- configuring single server, example: typescript
-- lspconfig.ts_ls.setup {
--   filetypes = { 'typescript', 'javascript', 'javascriptreact', 'typescriptreact', 'vue', 'markdown' },
-- }
--
-- -- configuring single server, example: typescript
-- -- lspconfig.ts_ls.setup {
-- --   on_attach = nvlsp.on_attach,
-- --   on_init = nvlsp.on_init,
-- --   capabilities = nvlsp.capabilities,
-- -- }
