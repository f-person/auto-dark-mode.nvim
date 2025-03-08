describe("healthchecks", function()
	it("running :checkhealth auto-dark-mode", function()
		require("auto-dark-mode").setup()

		vim.cmd(":checkhealth auto-dark-mode")
	end)
end)
