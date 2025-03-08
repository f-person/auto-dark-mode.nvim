---@meta

---@alias Appearance "light" | "dark"
---@alias DetectedOS "Linux" | "Darwin" | "Windows_NT" | "WSL"

---@class AutoDarkModeOptions
-- Optional. Fallback theme to use if the system theme can't be detected.
-- Useful for linux and environments without a desktop manager.
---@field fallback? Appearance
-- Optional. The default runs:
-- ```lua
-- vim.api.nvim_set_option_value('background', 'dark', {})
-- ```
---@field set_dark_mode? fun(): nil
-- Optional. The default runs:
-- ```lua
-- vim.api.nvim_set_option_value('background', 'light', {})
-- ```
---@field set_light_mode? fun(): nil
-- Optional. Specifies the `update_interval` milliseconds a theme check will be performed.
---@field update_interval? number
