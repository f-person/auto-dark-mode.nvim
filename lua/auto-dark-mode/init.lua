local M = {}

local uv = vim.uv or vim.loop

---@alias Appearance "light" | "dark"
---@alias DetectedOS "Linux" | "Darwin" | "Windows_NT" | "WSL"

---@class AutoDarkModeOptions
local default_options = {
	-- Optional. Fallback theme to use if the system theme can't be detected.
	-- Useful for linux and environments without a desktop manager.
	---@type Appearance?
	fallback = "dark",

	-- Optional. If not provided, `vim.api.nvim_set_option_value('background', 'dark', {})` will be used.
	---@type fun(): nil | nil
	set_dark_mode = function()
		vim.api.nvim_set_option_value("background", "dark", {})
	end,

	-- Optional. If not provided, `vim.api.nvim_set_option_value('background', 'light', {})` will be used.
	---@type fun(): nil | nil
	set_light_mode = function()
		vim.api.nvim_set_option_value("background", "light", {})
	end,

	-- Optional. Specifies the `update_interval` milliseconds a theme check will be performed.
	---@type number?
	update_interval = 3000,
}

local function validate_options(options)
	vim.validate({
		fallback = {
			options.fallback,
			function(opt)
				return opt == "dark" or opt == "light"
			end,
			"`fallback` must be either 'light' or 'dark'",
		},
		set_dark_mode = { options.set_dark_mode, "function" },
		set_light_mode = { options.set_light_mode, "function" },
		update_interval = { options.update_interval, "number" },
	})
	M.state.setup_correct = true
end

---@class AutoDarkModeState
M.state = {
	---@type boolean
	setup_correct = false,
	---@type DetectedOS
	system = nil,
	---@type table
	query_command = {},
}

M.init = function()
	local os_uname = uv.os_uname()

	if string.match(os_uname.release, "WSL") then
		M.state.system = "WSL"
	else
		M.state.system = os_uname.sysname
	end

	if M.state.system == "Darwin" then
		M.state.query_command = { "defaults", "read", "-g", "AppleInterfaceStyle" }
	elseif M.state.system == "Linux" then
		if not vim.fn.executable("dbus-send") then
			error([[
        auto-dark-mode.nvim:
        `dbus-send` is not available. The Linux implementation of
        auto-dark-mode.nvim relies on `dbus-send` being on the `$PATH`.
			]])
		end

		M.state.query_command = {
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
	elseif M.state.system == "Windows_NT" or M.state.system == "WSL" then
		local reg = "reg.exe"

		-- on WSL, if `reg.exe` cannot be found on the `$PATH`
		-- (see interop.appendWindowsPath https://learn.microsoft.com/en-us/windows/wsl/wsl-config),
		-- assume that it's in the default location
		if M.state.system == "WSL" and not vim.fn.executable("reg.exe") then
			local assumed_path = "/mnt/c/Windows/system32/reg.exe"

			if vim.fn.filereadable(assumed_path) then
				reg = assumed_path
			else
				-- `reg.exe` isn't on `$PATH` or in the default location, so throw an error
				error([[
          auto-dark-mode.nvim:
          `reg.exe` is not available. To support syncing with the host system,
          this plugin relies on `reg.exe` being on the `$PATH`.
        ]])
			end
		end

		M.state.query_command = {
			reg,
			"Query",
			"HKCU\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Themes\\Personalize",
			"/v",
			"AppsUseLightTheme",
		}
	else
		return
	end

	-- when on a supported unix system, and the userid is root
	if (M.state.system == "Darwin" or M.state.system == "Linux") and uv.getuid() == 0 then
		local sudo_user = vim.env.SUDO_USER

		if sudo_user ~= nil then
			-- prepend the command with `su - $SUDO_USER -c`
			local extra_args = { "su", "-", sudo_user, "-c" }
			for _, v in pairs(M.state.query_command) do
				table.insert(extra_args, v)
			end
			M.state.query_command = extra_args
		else
			error([[
				auto-dark-mode.nvim:
				Running as `root`, but `$SUDO_USER` is not set.
				Please open an issue to add support for your system.
      ]])
		end
	end

	local interval = require("auto-dark-mode.interval")

	interval.start(M.options, M.state)

	-- expose the previous `require("auto-dark-mode").disable()` function
	M.disable = interval.stop_timer
end

---@param options AutoDarkModeOptions
M.setup = function(options)
	M.options = vim.tbl_deep_extend("keep", options or {}, default_options)
	validate_options(M.options)

	M.init()
end

return M
