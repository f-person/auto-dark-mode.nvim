describe("querying works", function()
	it("polling dark mode", function()
		-- needed to initialize the plugin state
		require("auto-dark-mode").setup()

		require("auto-dark-mode.interval").poll_dark_mode()
	end)
end)
