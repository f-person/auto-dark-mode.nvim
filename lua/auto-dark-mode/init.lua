local M = {}

local uv = vim.uv or vim.loop

---@type AutoDarkModeOptions
local default_options = {
	fallback = "dark",

	set_dark_mode = function()
		vim.api.nvim_set_option_value("background", "dark", {})
	end,

	set_light_mode = function()
		vim.api.nvim_set_option_value("background", "light", {})
	end,

	update_interval = 3000,
}

---@param options AutoDarkModeOptions
local function validate_options(options)
	local version = vim.version()

	if (version.major == 0 and version.minor >= 11) or version.major > 0 then
		vim.validate("fallback", options.fallback, function(opt)
			return vim.tbl_contains({ "dark", "light" }, opt)
		end, "`fallback` to be either 'light' or 'dark'")
		vim.validate("set_dark_mode", options.set_dark_mode, "function")
		vim.validate("set_light_mode", options.set_light_mode, "function")
		vim.validate("update_interval", options.update_interval, "number")
	else
		vim.validate({
			fallback = {
				options.fallback,
				function(opt)
					return vim.tbl_contains({ "dark", "light" }, opt)
				end,
				"`fallback` to be either 'light' or 'dark'",
			},
			set_dark_mode = { options.set_dark_mode, "function" },
			set_light_mode = { options.set_light_mode, "function" },
			update_interval = { options.update_interval, "number" },
		})
	end

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

---@return nil
M.init = function()
	local os_uname = uv.os_uname()

	if string.match(os_uname.release, "WSL") then
		M.state.system = "WSL"
	elseif string.match(os_uname.release, "orbstack") then
		M.state.system = "OrbStack"
	else
		M.state.system = os_uname.sysname
	end

	if M.state.system == "Darwin" or M.state.system == "OrbStack" then
		local query_command = { "defaults", "read", "-g", "AppleInterfaceStyle" }
		if M.state.system == "OrbStack" then
			query_command = vim.list_extend({ "mac" }, query_command)
		end
		M.state.query_command = query_command
	elseif M.state.system == "Linux" then
	  -- Detect a real desktop session (avoid DBus on raw SSH/TTY)
	  local has_display = (vim.env.DISPLAY and #vim.env.DISPLAY > 0)
	                   or (vim.env.WAYLAND_DISPLAY and #vim.env.WAYLAND_DISPLAY > 0)

	  -- Normalize desktop/session hints
	  local session = ((vim.env.XDG_CURRENT_DESKTOP or vim.env.DESKTOP_SESSION or "") .. ""):lower()
	  local is_gnome  = session:find("gnome", 1, true) ~= nil
	  local is_kde    = session:find("kde",   1, true) ~= nil or session:find("plasma", 1, true) ~= nil

	  if not has_display then
	    -- Headless / raw SSH: do NOT query anything; empty output -> parser uses fallback
	    -- (Parser: "" -> M.options.fallback)
	    M.state.query_command = { "sh", "-lc", "printf ''" }

	    -- Avoid polling when headless
	    M.options.update_interval = 0
	  else
	    -- Prefer native, desktop-specific backends when they match the session
	    if is_gnome and vim.fn.executable("gsettings") == 1 then
	      -- Map GNOME’s value to the DBus-portal style the parser expects:
	      --   dark   -> "uint32 1"
	      --   light  -> "uint32 0"
	      local cmd = [[
	        if gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null | grep -q 'prefer-dark'; then
	          echo 'uint32 1'
	        else
	          echo 'uint32 0'
	        fi
	      ]]
	      M.state.query_command = { "sh", "-lc", cmd }

	    elseif is_kde and vim.fn.executable("kreadconfig5") == 1 then
	      -- KDE/Plasma: "Breeze Dark" etc. -> dark
	      local cmd = [[
	        cs="$(kreadconfig5 --file kdeglobals --group General --key ColorScheme 2>/dev/null)"
	        case "${cs,,}" in *dark*) echo 'uint32 1';; *) echo 'uint32 0';; esac
	      ]]
	      M.state.query_command = { "sh", "-lc", cmd }

	    -- If session vars are unreliable, still try native tools opportunistically
	    elseif vim.fn.executable("gsettings") == 1 then
	      local cmd = [[
	        if gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null | grep -q 'prefer-dark'; then
	          echo 'uint32 1'
	        else
	          echo 'uint32 0'
	        fi
	      ]]
	      M.state.query_command = { "sh", "-lc", cmd }

	    elseif vim.fn.executable("kreadconfig5") == 1 then
	      local cmd = [[
	        cs="$(kreadconfig5 --file kdeglobals --group General --key ColorScheme 2>/dev/null)"
	        case "${cs,,}" in *dark*) echo 'uint32 1';; *) echo 'uint32 0';; esac
	      ]]
	      M.state.query_command = { "sh", "-lc", cmd }

	    elseif vim.fn.executable("dbus-send") == 1 then
	      -- Fallback: xdg-desktop-portal (short timeout to avoid visible stalls)
	      M.state.query_command = {
	        "dbus-send",
	        "--session",
	        "--print-reply=literal",
	        "--reply-timeout=200",  -- shorter than 1000ms
	        "--dest=org.freedesktop.portal.Desktop",
	        "/org/freedesktop/portal/desktop",
	        "org.freedesktop.portal.Settings.Read",
	        "string:org.freedesktop.appearance",
	        "string:color-scheme",
	      }

	    else
	      -- Nothing suitable available: empty -> parser uses fallback
	      M.state.query_command = { "sh", "-lc", "printf ''" }
	      M.options.update_interval = 0
	    end
	  end
	elseif M.state.system == "Windows_NT" or M.state.system == "WSL" then
		local reg = "reg.exe"

		-- gracefully handle a bunch of WSL specific errors
		if M.state.system == "WSL" then
			-- automount not being enabled
			if not uv.fs_stat("/mnt/c/Windows") then
				error(
					"auto-dark-mode.nvim: Your WSL configuration doesn't enable `automount`. Please see https://learn.microsoft.com/en-us/windows/wsl/wsl-config#automount-settings."
				)
			end

			-- binfmt not being provided for windows executables
			if
				not (
					uv.fs_stat("/proc/sys/fs/binfmt_misc/WSLInterop")
					or uv.fs_stat("/proc/sys/fs/binfmt_misc/WSLInterop-late")
				)
			then
				error(
					"auto-dark-mode.nvim: Your WSL configuration doesn't enable `interop`. Please see https://learn.microsoft.com/en-us/windows/wsl/wsl-config#interop-settings."
				)
			end

			-- `appendWindowsPath` being set to false
			if vim.fn.executable("reg.exe") == 0 then
				local hardcoded_path = "/mnt/c/Windows/system32/reg.exe"
				if uv.fs_stat(hardcoded_path) then
					reg = hardcoded_path
				else
					error(
						"auto-dark-mode.nvim: `reg.exe` cannot be found. To support syncing with the host system, this plugin relies on `reg.exe` being on the `$PATH`."
					)
				end
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

		if not sudo_user then
			error(
				"auto-dark-mode.nvim: Running as `root`, but `$SUDO_USER` is not set. Please open an issue to add support for your setup."
			)
		end

		local prefixed_cmd = { "sudo", "--user", sudo_user }
		vim.list_extend(prefixed_cmd, M.state.query_command)

		M.state.query_command = prefixed_cmd
	end

	local interval = require("auto-dark-mode.interval")

	interval.start(M.options, M.state)

	-- expose the previous `require("auto-dark-mode").disable()` function
	M.disable = interval.stop_timer
end

---@param options? AutoDarkModeOptions
---@return nil
M.setup = function(options)
	if not options then
		options = {}
	end
	M.options = vim.tbl_deep_extend("keep", options or {}, default_options)
	validate_options(M.options)

	M.init()
end

return M
