rockspec_format = "3.0"
package = "auto-dark-mode"
version = "scm-1"
source = {
	url = "git+https://github.com/f-person/auto-dark-mode.nvim",
}
dependencies = {}
test_dependencies = { "nlua" }
build = {
	type = "builtin",
	copy_directories = { "doc" },
}
