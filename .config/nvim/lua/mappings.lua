require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set

map("n", ";", ":", { desc = "CMD enter command mode" })
map({ "n", "i", "v" }, "<leader>dg", "<cmd> lua vim.diagnostic.open_float()<cr>", { desc = "Float diagnostic" })

-- map({ "n", "i", "v" }, "<C-s>", "<cmd> w <cr>")

