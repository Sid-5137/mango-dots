local map = vim.keymap.set

-- File tree
map("n", "<leader>e", ":NvimTreeToggle<CR>", { desc = "Toggle file tree" })

-- Telescope
map("n", "<leader>ff", ":Telescope find_files<CR>", { desc = "Find files" })
map("n", "<leader>fg", ":Telescope live_grep<CR>",  { desc = "Live grep" })
map("n", "<leader>fb", ":Telescope buffers<CR>",    { desc = "Buffers" })

-- Terminal mode exit (Esc to go back to normal mode from terminal)
map("t", "<Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- Python env switcher
map("n", "<leader>pv", ":VenvSelect<CR>",        { desc = "Select Python venv" })
map("n", "<leader>pc", ":VenvSelectCached<CR>",  { desc = "Use cached venv" })

-- Git
map("n", "<leader>gg", ":LazyGit<CR>", { desc = "LazyGit" })

-- Window navigation
map("n", "<C-h>", "<C-w>h")
map("n", "<C-l>", "<C-w>l")
map("n", "<C-j>", "<C-w>j")
map("n", "<C-k>", "<C-w>k")
