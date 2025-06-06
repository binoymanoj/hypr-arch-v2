-- Neovim Configuration
-- Author: Binoy Manoj
-- GitHub: https://github.com/binoymanoj


-- This file simply bootstraps the installation of Lazy.nvim and then calls other files for execution
-- This file doesn't necessarily need to be touched, BE CAUTIOUS editing this file and proceed at your own risk.
local lazypath = vim.env.LAZY or vim.fn.stdpath "data" .. "/lazy/lazy.nvim"
if not (vim.env.LAZY or (vim.uv or vim.loop).fs_stat(lazypath)) then
  -- stylua: ignore
  vim.fn.system({ "git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath })
end
vim.opt.rtp:prepend(lazypath)

-- validate that lazy is available
if not pcall(require, "lazy") then
  -- stylua: ignore
  vim.api.nvim_echo({ { ("Unable to load lazy from: %s\n"):format(lazypath), "ErrorMsg" }, { "Press any key to exit...", "MoreMsg" } }, true, {})
  vim.fn.getchar()
  vim.cmd.quit()
end

require "lazy_setup"
require "polish"

------------
-- CUSTOM --
------------

-- Load AstroNvim
require("astronvim").setup()

-- -- Load user configurations
-- require("user.init")

-- DAP setup for JS, TS files
-- js-debug-adapter    # Install this from Mason
-- local dap = require "dap"
-- local mason_registry = require("mason-registry")
--
-- -- Set up the debug adapter
-- require("dap").adapters["pwa-node"] = {
--   type = "server",
--   host = "localhost",
--   port = "${port}",
--   executable = {
--     command = "node",
--     args = {
--       require("mason-registry").get_package("js-debug-adapter"):get_install_path() .. "/js-debug/src/dapDebugServer.js",
--       "${port}",
--     },
--   },
-- }
-- -- Add JavaScript configurations
-- require("dap").configurations.javascript = {
--   {
--     type = "pwa-node",
--     request = "launch",
--     name = "Launch file",
--     program = "${file}",
--     cwd = "${workspaceFolder}",
--   },
--   {
--     type = "pwa-node",
--     request = "attach",
--     name = "Attach",
--     processId = require("dap.utils").pick_process,
--     cwd = "${workspaceFolder}",
--   },
-- }
-- -- Also add TypeScript configurations
-- require("dap").configurations.typescript = require("dap").configurations.javascript

-- Go dap setup
-- local go_debug_adapter_pkg = mason_registry.get_package("go-debug-adapter")
-- local go_debug_adapter_path = go_debug_adapter_pkg:get_install_path()
-- dap.adapters.go = {
--   type = "server",
--   port = "${port}",
--   executable = {
--     command = go_debug_adapter_path .. "/extension/dist/debugAdapter.js",
--     args = { "${port}" },
--   },
-- }
-- dap.configurations.go = {
--   {
--     type = "go",
--     name = "Debug file",
--     request = "launch",
--     program = "${file}",
--   },
--   {
--     type = "go",
--     name = "Debug test (current file)",
--     request = "launch",
--     mode = "test",
--     program = "${file}",
--   },
--   {
--     type = "go",
--     name = "Attach to process",
--     request = "attach",
--     processId = require('dap.utils').pick_process,
--     cwd = "${workspaceFolder}",
--   },
-- }

-- Load custom keybindings
local mappings = require "mappings"
for mode, mode_mappings in pairs(mappings) do
  for lhs, mapping in pairs(mode_mappings) do
    local rhs = mapping[1]
    local opts = { noremap = true, silent = true, desc = mapping.desc }
    vim.api.nvim_set_keymap(mode, lhs, rhs, opts)
  end
end

--------------------
-- CUSTOM MACROS -- 
--------------------

-- Macro for console.log("<text> :", <text>);
local esc = vim.api.nvim_replace_termcodes("<Esc>", true, true, true)

-- Create a new augroup for JS/TS log macro
vim.api.nvim_create_augroup("JSLogMacro", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
  group = "JSLogMacro",
  pattern = { "javascript", "typescript", "javascriptreact", "typescriptreact" }, -- js, ts, jsx, tsx
  callback = function()
    -- Set 'l' register macro: console.log('<var>:', <var>);
    vim.fn.setreg("l", "yoconsole.log('" .. esc .. "pa:', " .. esc .. "pa);" .. esc .. "gs")
  end,
})

-- Create a new augroup for Go log macro
vim.api.nvim_create_augroup("GoLogMacro", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
  group = "GoLogMacro",
  pattern = { "go" },
  callback = function()
    -- Set 'l' register macro: log.Printf("<var>: %v", <var>)
    vim.fn.setreg("l", "yolog.Printf(\"" .. esc .. "pa: %v\", " .. esc .. "pa)" .. esc .. "gs")
  end,
})

-- Older Version
-- Macro for console.log()
-- vim.fn.setreg("l", "yoconsole.log('" .. esc .. "pa:', " .. esc .. "pa);" .. esc .. "gs") -- with save
-- vim.fn.setreg("l", "yoconsole.log('" .. esc .. "pa :', " .. esc .. "pa);" .. esc .. "") -- without save

