local M = {
	---@type uv_timer_t
	timer = nil,
	---@type number
	timer_id = nil,
	---@type boolean
	currently_in_dark_mode = nil,
}

-- Parses the query response for each system, returning `true` if the system is
-- in Dark mode, `false` when in Light mode.
---@param res string
---@return boolean
local function parse_query_response(res)
	if M.state.system == "Linux" then
		-- https://github.com/flatpak/xdg-desktop-portal/blob/c0f0eb103effdcf3701a1bf53f12fe953fbf0b75/data/org.freedesktop.impl.portal.Settings.xml#L32-L46
		-- 0: no preference
		-- 1: dark
		-- 2: light
		if string.match(res, "uint32 1") ~= nil then
			return true
		elseif string.match(res, "uint32 2") ~= nil then
			return false
		else
			return M.options.fallback == "dark"
		end
	elseif M.state.system == "Darwin" then
		return res == "Dark\n"
	elseif M.state.system == "Windows_NT" or M.state.system == "WSL" then
		-- AppsUseLightTheme REG_DWORD 0x0 : dark
		-- AppsUseLightTheme REG_DWORD 0x1 : light
		return string.match(res, "0x1") == nil
	end

	return false
end

---@param is_dark_mode boolean
local function change_theme_if_needed(is_dark_mode)
	if is_dark_mode == M.currently_in_dark_mode then
		return
	end

	M.currently_in_dark_mode = is_dark_mode
	if M.currently_in_dark_mode then
		if vim.system then
			vim.schedule(M.options.set_dark_mode)
		else
			M.options.set_dark_mode()
		end
	else
		if vim.system then
			vim.schedule(M.options.set_light_mode)
		else
			M.options.set_dark_mode()
		end
	end
end

M.poll_dark_mode = function()
	if vim.system then
		vim.system(M.state.query_command, { text = true }, function(data)
			local is_dark_mode = parse_query_response(data.stdout)
			change_theme_if_needed(is_dark_mode)
		end)
	else
		-- Legacy implementation using `vim.fn.jobstart` instead of `vim.system`,
		-- for use in neovim <0.10.0
		vim.fn.jobstart(M.state.query_command, {
			stdout_buffered = true,
			on_stdout = function(_, data, _)
				local is_dark_mode = parse_query_response(table.concat(data, "\n"))
				change_theme_if_needed(is_dark_mode)
			end,
		})
	end
end

M.start_timer = function()
	---@type number
	local interval = M.options.update_interval

	if vim.uv.new_timer or vim.loop.new_timer then
		M.timer = vim.uv.new_timer() or vim.loop.new_timer()
		M.timer:start(interval, interval, M.poll_dark_mode)
	else
		M.timer_id = vim.fn.timer_start(interval, M.poll_dark_mode, { ["repeat"] = -1 })
	end
end

M.stop_timer = function()
	if vim.uv.timer_stop or vim.loop.timer_stop then
		vim.uv.timer_stop(M.timer)
	else
		vim.fn.timer_stop(M.timer_id)
	end
end

---@param options AutoDarkModeOptions
---@param state AutoDarkModeState
M.start = function(options, state)
	M.options = options
	M.state = state

	M.poll_dark_mode()
	M.start_timer()
end

return M
