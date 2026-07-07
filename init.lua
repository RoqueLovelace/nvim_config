-- Base settings
vim.g.mapleader = " "
vim.opt.clipboard = "unnamedplus" -- sync with system clipboard
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Plugin setup
require("lazy").setup({

  -- 1. nvim-tree
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {}, 
    keys = { { "<leader>e", ":NvimTreeToggle<CR>", desc = "Toggle explorer" } }
  },

  -- 2. treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      local status_ok, treesitter = pcall(require, "nvim-treesitter.configs")
      if not status_ok then return end

      treesitter.setup({
        ensure_installed = { "c", "lua", "vim", "vimdoc", "query", "python", "dockerfile" }, 
        highlight = { enable = true },
      })
    end
  },

  -- 3. telescope
  {
    'nvim-telescope/telescope.nvim', branch = 'master',
    dependencies = { 'nvim-lua/plenary.nvim' },
    keys = {
      { "<leader>ff", "<cmd>Telescope find_files<CR>", desc = "Find files" },
      { "<leader>fg", "<cmd>Telescope live_grep<CR>", desc = "Live grep" }
    }
  },

  -- 4. bufferline
  {
    "akinsho/bufferline.nvim",
    version = "*",
    dependencies = "nvim-tree/nvim-web-devicons",
    config = function()
      require("bufferline").setup({
        options = {
          separator_style = "slant",
          diagnostics = "nvim_lsp", 
          show_buffer_close_icons = false,
          show_close_icon = false,
        }
      })

      -- Tab navigation
      vim.keymap.set('n', '<S-h>', '<Cmd>BufferLineCyclePrev<CR>', { desc = "Prev buffer" })
      vim.keymap.set('n', '<S-l>', '<Cmd>BufferLineCycleNext<CR>', { desc = "Next buffer" })
    end
  },

  -- 5. bufdelete
  {
    "famiu/bufdelete.nvim",
    config = function()
      vim.keymap.set('n', '<leader>x', '<Cmd>Bdelete<CR>', { desc = "Close buffer safely" })
    end
  },

  -- 6. mason & lspconfig
  {
    "neovim/nvim-lspconfig",
    dependencies = { "williamboman/mason.nvim" },
    config = function()
      require("mason").setup()
      
      -- Native LSP setup (Neovim 0.12+)
      vim.lsp.config.pyright = {}
      vim.lsp.enable('pyright')
      
      vim.lsp.config.dockerls = {}
      vim.lsp.enable('dockerls')

      -- LSP keymaps
      vim.keymap.set('n', 'K', vim.lsp.buf.hover, { desc = "Hover documentation" })
      vim.keymap.set('n', 'gd', vim.lsp.buf.definition, { desc = "Go to definition" })
      vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, { desc = "Rename symbol" })
      vim.keymap.set('n', '<leader>d', vim.diagnostic.open_float, { desc = "Line diagnostics" })
    end
  },

  -- 7. nvim-cmp
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",  
      "hrsh7th/cmp-path",    
      "L3MON4D3/LuaSnip",    
      "saadparwaiz1/cmp_luasnip",
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")

      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        window = {
          completion = cmp.config.window.bordered(),
          documentation = cmp.config.window.bordered(),
        },
        mapping = cmp.mapping.preset.insert({
          ['<C-Space>'] = cmp.mapping.complete(),
          ['<CR>'] = cmp.mapping.confirm({ select = true }),
          ['<Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { "i", "s" }),
          ['<S-Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { "i", "s" }),
        }),
        -- Source priority
        sources = cmp.config.sources({
          { name = 'nvim_lsp' },
          { name = 'luasnip' }, 
        }, {
          { name = 'buffer' },  
          { name = 'path' },    
        })
      })
    end
  },

  -- 8. tokyonight
  {
    "folke/tokyonight.nvim",
    priority = 1000, 
    config = function()
      -- Disable transparency for SSH sessions
      local is_ssh = vim.env.SSH_CLIENT ~= nil or vim.env.SSH_TTY ~= nil
      local use_transparent = not is_ssh

      require("tokyonight").setup({
        transparent = use_transparent, 
        styles = {
          sidebars = use_transparent and "transparent" or "dark",
          floats = use_transparent and "transparent" or "dark",
        },
      })
      vim.cmd.colorscheme("tokyonight-moon") 
    end
  },

  -- 9. lualine
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("lualine").setup({
        options = {
          theme = "tokyonight", 
          component_separators = { left = '│', right = '│'},
          section_separators = { left = '', right = ''},
        },
      })
    end
  },

  -- 10. zen-mode
  {
    "folke/zen-mode.nvim",
    keys = { { "<leader>z", ":ZenMode<CR>", desc = "Toggle Zen mode" } }
  }

})

-- Global formatting overrides
vim.api.nvim_create_autocmd("FileType", {
  pattern = "*",
  callback = function()
    vim.opt_local.shiftwidth = 2
    vim.opt_local.tabstop = 2
    vim.opt_local.expandtab = true
  end,
})
