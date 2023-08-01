# auto-dark-mode.nvim
A Neovim plugin for macOS that automatically changes the editor appearance
based on system settings.
![demo](assets/demo.gif?raw=true)

## Installation
### Using [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'f-person/auto-dark-mode.nvim'
```

## Configuration
You need to call `setup` for initialization.
`setup` accepts a table with options – `set_dark_mode` function,
`set_light_mode` function, and `update_interval` integer.

`set_dark_mode` is called when the system appearance changes to dark mode, and
`set_light_mode` is called when it changes to light mode.
By default, they just change the background option, but you can do whatever you like.

`update_interval` is how frequently the system appearance is checked.
The value is stored in milliseconds. Defaults to `3000`.

```lua
local auto_dark_mode = require('auto-dark-mode')

auto_dark_mode.setup({
	update_interval = 1000,
	set_dark_mode = function()
		vim.api.nvim_set_option('background', 'dark')
		vim.cmd('colorscheme gruvbox')
	end,
	set_light_mode = function()
		vim.api.nvim_set_option('background', 'light')
		vim.cmd('colorscheme gruvbox')
	end,
})
```

### Using [lazy](https://github.com/folke/lazy.nvim)

```lua
return {
  "f-person/auto-dark-mode.nvim",
  config = {
    update_interval = 1000,
    set_dark_mode = function()
      vim.api.nvim_set_option("background", "dark")
      vim.cmd("colorscheme gruvbox")
    end,
    set_light_mode = function()
      vim.api.nvim_set_option("background", "light")
      vim.cmd("colorscheme gruvbox")
    end,
  },
}
```

#### Disable
You can disable `auto-dark-mode.nvim` at runtime via `lua require('auto-dark-mode').disable()`.

## Requirements
* macOS or a Linux environment that implements [`org.freedesktop.appearance.color-scheme`](https://github.com/flatpak/xdg-desktop-portal/issues/629)
* Neovim

# Support
If you enjoy the plugin and want to support what I do


<a href="https://www.buymeacoffee.com/fperson" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/default-orange.png" alt="Buy Me A Coffee" height="41"  width="174"></a>
