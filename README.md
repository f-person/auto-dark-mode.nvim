# auto-dark-mode.nvim
A Neovim plugin for macOS, Linux, and Windows that automatically changes the
editor appearance based on system settings.

<!-- panvimdoc-ignore-start -->

<div style="display: flex; justify-content: center;">
	<img src="https://user-images.githubusercontent.com/79978224/257745167-36f16e78-e4d0-47d7-a395-8b2abba8ea88.gif" alt="macOS demo" style="max-width: 800px; object-fit: contain;"/>
</div>

<details>
<summary>Linux demo</summary>

<div style="display: flex; justify-content: center;">
	<img src="https://user-images.githubusercontent.com/79978224/257745238-699764e1-2fcb-4c47-b353-7c90235a12e1.gif" alt="Linux demo" style="max-width: 800px; object-fit: contain;"/>
</div>

</details>

<details>
<summary>Windows demo</summary>

<div style="display: flex; justify-content: center;">
	<img src="https://user-images.githubusercontent.com/25822972/260328314-20057463-a27c-4296-a701-3b7603aa0781.gif" alt="Windows demo" style="max-width: 800px; object-fit: contain;"/>
</div>

</details>

<!-- panvimdoc-ignore-end -->

## Installation

### Using [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'f-person/auto-dark-mode.nvim'
```

## Requirements
* macOS, a Linux environment that implements
  [`org.freedesktop.appearance.color-scheme`](https://github.com/flatpak/xdg-desktop-portal/issues/629),
  Windows 10+ or WSL
* Neovim

## Configuration
You need to call `setup` for initialization.
`setup` accepts a table with options – `set_dark_mode` function,
`set_light_mode` function, and `update_interval` integer.

`set_dark_mode` is called when the system appearance changes to dark mode, and
`set_light_mode` is called when it changes to light mode.
By default, they just change the background option, but you can do whatever you like.

`update_interval` is how frequently the system appearance is checked.
The value needs to be larger than whatever time your system takes to query dark mode.
Otherwise you risk freezing neovim on shutdown.
The value is stored in milliseconds.
Defaults to `3000`.

```lua
local auto_dark_mode = require('auto-dark-mode')

auto_dark_mode.setup({
	update_interval = 1000,
	set_dark_mode = function()
		vim.api.nvim_set_option_value('background', 'dark', {})
		vim.cmd('colorscheme gruvbox')
	end,
	set_light_mode = function()
		vim.api.nvim_set_option_value('background', 'light', {})
		vim.cmd('colorscheme gruvbox')
	end,
})
```

### Using [lazy](https://github.com/folke/lazy.nvim)

```lua
return {
  "f-person/auto-dark-mode.nvim",
  opts = {
    update_interval = 1000,
    set_dark_mode = function()
      vim.api.nvim_set_option_value("background", "dark", {})
      vim.cmd("colorscheme gruvbox")
    end,
    set_light_mode = function()
      vim.api.nvim_set_option_value("background", "light", {})
      vim.cmd("colorscheme gruvbox")
    end,
  },
}
```

#### Disable
You can disable `auto-dark-mode.nvim` at runtime via `lua require('auto-dark-mode').disable()`.

## Thanks To
* [@nekowinston](https://github.com/nekowinston) for implementing Linux support and other contributions! <3
* [@adityamwagh](https://github.com/adityamwagh) for implementing Windows support

# Support
If you enjoy the plugin and want to support what I do

<a href="https://www.buymeacoffee.com/fperson" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/default-orange.png" alt="Buy Me A Coffee" height="41"  width="174"></a>
