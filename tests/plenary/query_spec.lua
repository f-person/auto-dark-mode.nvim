describe("querying", function()
	it("polling dark mode", function()
		-- needed to initialize the plugin state
		require("auto-dark-mode").setup()

		require("auto-dark-mode.interval").poll_dark_mode()
	end)

	it("parsing the response", function()
		-- needed to initialize the plugin state
		require("auto-dark-mode").setup()

		require("auto-dark-mode.interval").poll_dark_mode(require("auto-dark-mode.interval").parse_callback)
	end)
end)
