local M = {}

local adm = require("auto-dark-mode")

M.benchmark = function(iterations)
	local results = {}

	for _ = 1, iterations do
		local _start = vim.uv.hrtime()
		vim.system(adm.state.query_command, { text = true }):wait()
		local _end = vim.uv.hrtime()
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

M.check = function()
	vim.health.start("auto-dark-mode.nvim")

	if adm.state.setup_correct then
		vim.health.ok("Setup is correct")
	else
		vim.health.error("Setup is incorrect")
	end

	vim.health.info("Detected operating system: " .. adm.state.system)
	vim.health.info("Using query command: `" .. table.concat(adm.state.query_command, " ") .. "`")

	local benchmark = M.benchmark(30)
	vim.health.info(
		string.format("Benchmark: %.2fms avg / %.2fms min / %.2fms max", benchmark.avg, benchmark.min, benchmark.max)
	)

	local interval = adm.options.update_interval
	local ratio = interval / benchmark.avg
	local info = string.format("Update interval (%dms) is %.2fx the average query time", interval, ratio)
	local error = string.format(
		"Update interval (%dms) seems too short compared to current benchmarks, consider increasing it",
		interval
	)

	if ratio > 30 then
		vim.health.ok(info)
	elseif ratio > 5 then
		vim.health.warn(info)
	else
		vim.health.error(error)
	end
end

return M
