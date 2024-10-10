local M = {}

local uv = vim.uv or vim.loop

local adm = require("auto-dark-mode")
local interval = require("auto-dark-mode.interval")

M.benchmark = function(iterations)
	local results = {}

	for _ = 1, iterations do
		local _start = uv.hrtime()
		-- by using an empty function, parsing the response is measured, but
		-- actually syncing the vim theme isn't performed
		interval.poll_dark_mode(function() end)
		local _end = uv.hrtime()

		table.insert(results, (_end - _start) / 1000000)
	end

	local max = 0
	local min = math.huge
	local sum = 0
	for _, v in pairs(results) do
		max = max > v and max or v
		min = min < v and min or v
		sum = sum + v
	end

	return { avg = sum / #results, max = max, min = min }
end

-- support for neovim < 0.9.0
local H = vim.health
local health = {}
health.start = H.start or H.report_start
health.ok = H.ok or H.report_ok
health.info = H.info or H.report_info
health.error = H.error or H.report_error

M.check = function()
	health.start("auto-dark-mode.nvim")

	if adm.state.setup_correct then
		health.ok("Setup is correct")
	else
		health.error("Setup is incorrect")
	end

	health.info(string.format("Detected operating system: %s", adm.state.system))
	health.info(string.format("Using query command: `%s`", table.concat(adm.state.query_command, " ")))

	local benchmark = M.benchmark(30)
	health.info(
		string.format("Benchmark: %.2fms avg / %.2fms min / %.2fms max", benchmark.avg, benchmark.min, benchmark.max)
	)

	local update_interval = adm.options.update_interval
	local ratio = update_interval / benchmark.avg
	local info = string.format("Update interval (%dms) is %.2fx the average query time", update_interval, ratio)
	local error = string.format(
		"Update interval (%dms) seems too short compared to current benchmarks, consider increasing it",
		update_interval
	)

	if ratio > 30 then
		health.ok(info)
	elseif ratio > 5 then
		health.warn(info)
	else
		health.error(error)
	end
end

return M
