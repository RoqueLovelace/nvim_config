-- ==========================================
-- 1. CONFIGURACIÓN BASE Y TECLA LÍDER
-- ==========================================
vim.g.mapleader = " "

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.tabstop = 2         -- El ancho visual de un tabulador ahora es de 2 espacios
vim.opt.shiftwidth = 2      -- El ancho de la sangría (indentación) cambia a 2 espacios
vim.opt.expandtab = true    -- Transforma los tabs físicos en espacios reales

-- ==========================================
-- 2. INSTALADOR DEL GESTOR (lazy.nvim)
-- ==========================================
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- ==========================================
-- 3. PLUGINS (COMPATIBLES CON NVIM v0.12)
-- ==========================================
require("lazy").setup({

  -- [ A ] EL ÁRBOL DE CARPETAS
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {}, 
    keys = { { "<leader>e", ":NvimTreeToggle<CR>", desc = "Explorador" } }
  },

-- [ B ] TREESITTER (Ahora con Python y Docker)
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      local status_ok, treesitter = pcall(require, "nvim-treesitter.configs")
      if not status_ok then return end

      treesitter.setup({
        -- Añadimos python y dockerfile a la lista de descargas
        ensure_installed = { "c", "lua", "vim", "vimdoc", "query", "python", "dockerfile" }, 
        highlight = { enable = true },
      })
    end
  },
  -- [ C ] TELESCOPE (Buscador)
  {
    'nvim-telescope/telescope.nvim', tag = '0.1.5',
    dependencies = { 'nvim-lua/plenary.nvim' },
    keys = {
      { "<leader>ff", "<cmd>Telescope find_files<CR>", desc = "Buscar Archivos" },
      { "<leader>fg", "<cmd>Telescope live_grep<CR>", desc = "Buscar Texto" }
    }
  },

-- [ D ] MASON Y LSP (Sintaxis nativa Neovim 0.12+)
  {
    "neovim/nvim-lspconfig",
    dependencies = { "williamboman/mason.nvim" },
    config = function()
      require("mason").setup()
      
      -- Nueva API de Neovim para activar los servidores sin usar require('lspconfig')
      vim.lsp.config.pyright = {}
      vim.lsp.enable('pyright')
      
      vim.lsp.config.dockerls = {}
      vim.lsp.enable('dockerls')

      -- Atajos de teclado
      vim.keymap.set('n', 'K', vim.lsp.buf.hover, { desc = "Analizar documentación" })
      vim.keymap.set('n', 'gd', vim.lsp.buf.definition, { desc = "Rastrear definición" })
      vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, { desc = "Renombrar variable" })
      -- Atajo para ver el mensaje de error o advertencia flotante
      vim.keymap.set('n', '<leader>d', vim.diagnostic.open_float, { desc = "Ver diagnóstico/error" })
    end
  },
  -- [ E ] MODO ZEN
  {
    "folke/zen-mode.nvim",
    keys = { { "<leader>z", ":ZenMode<CR>", desc = "Modo Zen" } }
  },

-- [ F ] TEMA VISUAL (Con lógica de Servidor/Local)
  {
    "folke/tokyonight.nvim",
    priority = 1000, 
    config = function()
      -- Detecta si estamos conectados por SSH
      local is_ssh = vim.env.SSH_CLIENT ~= nil or vim.env.SSH_TTY ~= nil
      
      -- Si NO estamos en SSH, activamos la transparencia
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

  -- [ G ] AUTOCOMPLETADO (El menú desplegable inteligente)
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp", -- Conecta la inteligencia del LSP con el menú
      "hrsh7th/cmp-buffer",   -- Sugiere palabras que ya escribiste en el archivo
      "hrsh7th/cmp-path",     -- Sugiere rutas de archivos (ej. al escribir "./")
      "L3MON4D3/LuaSnip",     -- Motor para expandir fragmentos de código (necesario)
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
          ['<C-Space>'] = cmp.mapping.complete(), -- Forzar abrir el menú manualmente
          ['<CR>'] = cmp.mapping.confirm({ select = true }), -- Enter para aceptar sugerencia
          ['<Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item() -- Bajar en la lista con Tab
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { "i", "s" }),
          ['<S-Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item() -- Subir en la lista con Shift + Tab
            elseif luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { "i", "s" }),
        }),
        -- El orden de las "sources" define la prioridad de lo que te recomienda
        sources = cmp.config.sources({
          { name = 'nvim_lsp' }, -- 1. Sugerencias lógicas de Pyright/Dockerls
          { name = 'luasnip' },  -- 2. Fragmentos de código
        }, {
          { name = 'buffer' },   -- 3. Palabras de este mismo archivo
          { name = 'path' },     -- 4. Rutas de tu disco duro
        })
      })
    end
  }

})