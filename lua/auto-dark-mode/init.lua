local utils = require("auto-dark-mode.utils")

---@type number
local timer_id
---@type boolean
local is_currently_dark_mode

---@type fun(): nil | nil
local set_dark_mode
---@type fun(): nil | nil
local set_light_mode

---@type number
local update_interval

---@type table
local query_command
---@type "Linux" | "Darwin" | "Windows_NT" | "WSL"
local system

---@type "light" | "dark"
local fallback

-- Parses the query response for each system
---@param res table
---@return boolean
local function parse_query_response(res)
	if system == "Linux" then
		-- https://github.com/flatpak/xdg-desktop-portal/blob/c0f0eb103effdcf3701a1bf53f12fe953fbf0b75/data/org.freedesktop.impl.portal.Settings.xml#L32-L46
		-- 0: no preference
		-- 1: dark
		-- 2: light
		if string.match(res[1], "uint32 1") ~= nil then
			return true
		elseif string.match(res[1], "uint32 2") ~= nil then
			return false
		else
			return fallback == "dark"
		end
	elseif system == "Darwin" then
		return res[1] == "Dark"
	elseif system == "Windows_NT" or system == "WSL" then
		-- AppsUseLightTheme REG_DWORD 0x0 : dark
		-- AppsUseLightTheme REG_DWORD 0x1 : light
		return string.match(res[3], "0x1") == nil
	end
	return false
end

---@param callback fun(is_dark_mode: boolean)
local function check_is_dark_mode(callback)
	utils.start_job(query_command, {
		on_stdout = function(data)
			local is_dark_mode = parse_query_response(data)
			callback(is_dark_mode)
		end,
	})
end

---@param is_dark_mode boolean
local function change_theme_if_needed(is_dark_mode)
	if is_dark_mode == is_currently_dark_mode then
		return
	end

	is_currently_dark_mode = is_dark_mode
	if is_currently_dark_mode then
		set_dark_mode()
	else
		set_light_mode()
	end
end

local function start_check_timer()
	timer_id = vim.fn.timer_start(update_interval, function()
		check_is_dark_mode(change_theme_if_needed)
	end, { ["repeat"] = -1 })
end

local function init()
	if string.match(vim.loop.os_uname().release, "WSL") then
		system = "WSL"
	else
		system = vim.loop.os_uname().sysname
	end

	if system == "Darwin" then
		query_command = { "defaults", "read", "-g", "AppleInterfaceStyle" }
	elseif system == "Linux" then
		if not vim.fn.executable("dbus-send") then
			error([[
		`dbus-send` is not available. The Linux implementation of
		auto-dark-mode.nvim relies on `dbus-send` being on the `$PATH`.
		]])
		end

		query_command = {
			"dbus-send",
			"--session",
			"--print-reply=literal",
			"--reply-timeout=1000",
			"--dest=org.freedesktop.portal.Desktop",
			"/org/freedesktop/portal/desktop",
			"org.freedesktop.portal.Settings.Read",
			"string:org.freedesktop.appearance",
			"string:color-scheme",
		}
	elseif system == "WSL" then
		-- Don't swap the quotes; it breaks the code
		query_command = {
			"/mnt/c/Windows/system32/reg.exe",
			"Query",
			"HKCU\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Themes\\Personalize",
			"/v",
			"AppsUseLightTheme",
		}
  elseif system == "Windows_NT" then
		-- Don't swap the quotes; it breaks the code
		query_command = {
			"reg.exe",
			"Query",
			"HKCU\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Themes\\Personalize",
			"/v",
			"AppsUseLightTheme",
		}

	else
		return
	end

	if vim.fn.has("unix") ~= 0 then
		if vim.loop.getuid() == 0 then
			local sudo_user = vim.env.SUDO_USER

			if sudo_user ~= nil then
				query_command = vim.tbl_extend("keep", { "su", "-", sudo_user, "-c" }, query_command)
			else
				error([[
				auto-dark-mode.nvim:
				Running as `root`, but `$SUDO_USER` is not set.
				Please open an issue to add support for your system.
				]])
			end
		end
	end

	if type(set_dark_mode) ~= "function" or type(set_light_mode) ~= "function" then
		error([[

		Call `setup` first:

		require('auto-dark-mode').setup({
			set_dark_mode=function()
				vim.api.nvim_set_option_value('background', 'dark')
				vim.cmd('colorscheme gruvbox')
			end,
			set_light_mode=function()
				vim.api.nvim_set_option_value('background', 'light')
			end,
		})
		]])
	end

	check_is_dark_mode(change_theme_if_needed)
	start_check_timer()
end

local function disable()
	vim.fn.timer_stop(timer_id)
end

---@param options AutoDarkModeOptions
local function setup(options)
	options = options or {}

	---@param background string
	local function set_background(background)
		vim.api.nvim_set_option_value("background", background, {})
	end

	set_dark_mode = options.set_dark_mode or function()
		set_background("dark")
	end
	set_light_mode = options.set_light_mode or function()
		set_background("light")
	end
	update_interval = options.update_interval or 3000
	fallback = options.fallback or "dark"

	init()
end

return { setup = setup, init = init, disable = disable }
