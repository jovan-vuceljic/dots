require "nvchad.mappings"

local map = vim.keymap.set

map({ "n", "i", "v" }, "<leader>dg", "<cmd> lua vim.diagnostic.open_float()<cr>", { desc = "Float diagnostic" })
map({ "n", "v" }, "<leader>ge", "<cmd>:Gen<cr>", { desc = "Gen.nvim" })
-- map("n", ";", ":", { desc = "CMD enter command mode" })
-- map({ "n", "v" }, "<C>u", "<C>uzz", { desc = "Page up" })
-- map({ "n", "v" }, "<C>d", "<C>dzz", { desc = "Page up" })
