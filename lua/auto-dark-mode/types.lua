---@class AutoDarkModeOptions
-- Optional. If not provided, `vim.api.nvim_set_option_value('background', 'dark')` will be used.
---@field set_dark_mode nil | fun(): nil
-- Optional. If not provided, `vim.api.nvim_set_option_value('background', 'light')` will be used.
---@field set_light_mode nil | fun(): nil
-- Every `update_interval` milliseconds a theme check will be performed.
---@field update_interval number?
-- Optional. Fallback theme to use if the system theme can't be detected.
-- Useful for linux and environments without a desktop manager.
---@field fallback "light" | "dark" | nil
--- Optional: If not provided, false will be used, default for solid background color
---@field transparent_dark_background boolean?
