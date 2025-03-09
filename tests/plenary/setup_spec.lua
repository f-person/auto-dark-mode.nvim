describe("calling setup()", function()
	it("with default config", function()
		require("auto-dark-mode").setup()
	end)

	it("with customized config", function()
		require("auto-dark-mode").setup({
			fallback = "light",
			set_dark_mode = function()
				vim.notify("would set dark mode")
			end,
			set_light_mode = function()
				vim.notify("would set light mode")
			end,
			update_interval = 10000,
		})
	end)
end)
