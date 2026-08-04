require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set

map("n", "gd", vim.lsp.buf.definition, { desc = "Go to definition" })
map("n", "gD", "<cmd>Telescope lsp_definitions<CR>", { desc = "Go to Definitions" })
map("n", "grr", "<cmd>Telescope lsp_references<CR>", { desc = "Go to references" })
map("n", "<leader>da", ":lua vim.lsp.buf.code_action()<cr>", { desc = "Code actions", noremap = true, silent = true })
map("n", "<leader>dh", ":lua vim.diagnostic.open_float()<CR>", { desc = "Show diagnostics" })
map("n", "<leader>dj", function()
  vim.diagnostic.jump { count = 1, float = true }
end, { desc = "Go to next" })
map("n", "<leader>dk", function()
  vim.diagnostic.jump { count = -1, float = true }
end, { desc = "Go to previous" })
-- Telescope
map("n", "<leader>fr", ":Telescope resume<CR>", { desc = "Resume last search" })
map("n", "<leader>fs", ":Telescope grep_string<CR>", { desc = "Find selected string" })
map("n", "<leader>fk", ":Telescope keymaps<CR>", { desc = "Find keymaps" })
map("n", "<leader>fd", ":Telescope diagnostics<CR>", { desc = "Diagnostics" })
-- Remaps
map({ "n", "v" }, "x", '"_x', { desc = "Delete char without yanking" })
map({ "n", "v" }, "c", '"_c', { desc = "Change without yanking" })
