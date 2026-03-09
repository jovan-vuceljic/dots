require "nvchad.mappings"

local map = vim.keymap.set

-- map("n", ";", ":", { desc = "CMD enter command mode" })
-- map({ "n", "v" }, "<C>u", "<C>uzz", { desc = "Page up" })
-- map({ "n", "v" }, "<C>d", "<C>dzz", { desc = "Page up" })
-- map({ "n", "i", "v" }, "<C-s>", "<cmd> w <cr>")

local builtin = require "telescope.builtin"

map("n", "gd", vim.lsp.buf.definition, { desc = "Go to definition" })
map("n", "gD", builtin.lsp_definitions, { desc = "Go to Definitions" })
map("n", "grr", builtin.lsp_references, { desc = "Go to references" })
map("n", "<leader>gl", "<cmd>lua vim.lsp.buf.code_action()<CR>", { noremap = true, silent = true })

map({ "n", "v" }, "<leader>dg", "<cmd> lua vim.diagnostic.open_float()<cr>", { desc = "Float diagnostic" })
map("n", "<leader>dh", ":lua vim.diagnostic.open_float()<cr>", { desc = "Show diagnostics" })
map("n", "<leader>dj", ":lua vim.diagnostic.goto_next()<cr>", { desc = "Go to next" })
map("n", "<leader>dk", ":lua vim.diagnostic.goto_prev()<cr>", { desc = "Go to previous" })
map("n", "<leader>da", ":lua vim.lsp.buf.code_action()<cr>", { desc = "Code actions", noremap = true, silent = true })

map("n", "<leader>fr", ":Telescope resume<CR>", { desc = "Resume last search" })
map("n", "<leader>fs", ":Telescope grep_string<CR>", { desc = "Find selected string" })
map("n", "<leader>fk", ":Telescope keymaps<CR>", { desc = "Find keymaps" })
map("n", "<leader>fd", ":Telescope diagnostics<CR>", { desc = "Diagnostics" })

map({ "n", "v" }, "<leader>ge", "<cmd>:Gen<cr>", { desc = "Gen.nvim" })

-- Opencode
map({ "n", "x" }, "<leader>ga", function()
  require("opencode").ask("@this: ", { submit = true })
end, { desc = "Ask opencode…" })

map({ "n", "x" }, "<leader>gx", function()
  require("opencode").select()
end, { desc = "Execute opencode action…" })

map({ "n", "t" }, "<leader>g.", function()
  require("opencode").toggle()
end, { desc = "Toggle opencode" })

map({ "n", "x" }, "<leader>go", function()
  return require("opencode").operator "@this "
end, { desc = "Add range to opencode", expr = true })
map("n", "<leader>goo", function()
  return require("opencode").operator "@this " .. "_"
end, { desc = "Add line to opencode", expr = true })

map("n", "<leader>gu", function()
  require("opencode").command "session.half.page.up"
end, { desc = "Scroll opencode up" })
map("n", "<leader>gd", function()
  require("opencode").command "session.half.page.down"
end, { desc = "Scroll opencode down" })

-- You may want these if you use the opinionated `<C-a>` and `<C-x>` keymaps above — otherwise consider `<leader>o…` (and remove terminal mode from the `toggle` keymap)
-- map("n", "+", "<C-a>", { desc = "Increment under cursor", noremap = true })
-- map("n", "-", "<C-x>", { desc = "Decrement under cursor", noremap = true })
