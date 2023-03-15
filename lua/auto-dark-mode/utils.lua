local M = {}

---@param cmd string
---@param opts table
---@return number | 'the job id'
function M.start_job(cmd, opts)
	opts = opts or {}
	local id = vim.fn.jobstart(cmd, {
		stdout_buffered = true,
		on_stdout = function(_, data, _)
			if data and opts.on_stdout then
				opts.on_stdout(data)
			end
		end,
		on_exit = function(_, data, _)
			if opts.on_exit then
				opts.on_exit(data)
			end
		end,
	})

	if opts.input then
		vim.fn.chansend(id, opts.input)
		vim.fn.chanclose(id, "stdin")
	end

	return id
end

---@return 'win'|'darwin'|'linux'
function M.get_os()
	if package.config:sub(1, 1) == "\\" then
		return "win"
	elseif (io.popen("uname -s"):read("*a")):match("Darwin") then
		return "darwin"
	else
		return "linux"
	end
end

--- Caching `is_root` to avoid checking it every time
---@type boolean
local is_root

---@param callback fun(result: boolean)
function M.check_is_root(callback)
	if is_root ~= nil then
		callback(is_root)
		return
	end

	M.start_job("id -u", {
		on_stdout = function(result)
			is_root = result[1] == "0"
			callback(is_root)
		end,
	})
end

return M
