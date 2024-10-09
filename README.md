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

## 📋 Requirements
Your operating system needs to be:

- a Linux desktop environment that implements
  [`org.freedesktop.appearance.color-scheme`](https://github.com/flatpak/xdg-desktop-portal/issues/629),
  such as
  - [Gnome](https://gnome.org)
  - [KDE](https://kde.org)
  - [darkman](https://gitlab.com/WhyNotHugo/darkman) for window managers
- macOS Mojave or newer
- Windows 10 or newer (or WSL)

## 📦 Installation

Install the plugin with your preferred package manager:

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
-- Lua
{
  "f-person/auto-dark-mode.nvim",
  opts = {
    -- your configuration comes here
    -- or leave it empty to use the default settings
    -- refer to the configuration section below
  }
}
```

### [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'f-person/auto-dark-mode.nvim'
```

## ⚙️ Configuration

**auto-dark-mode** comes with the following defaults:

```lua
{
    set_dark_mode = function()
        vim.api.nvim_set_option_value("background", "dark", {})
    end,
    set_light_mode = function()
        vim.api.nvim_set_option_value("background", "light", {})
    end,
    update_interval = 3000,
    fallback = "dark"
}
```

`set_dark_mode` and `set_light_mode` are the hooks called when the system
appearance changes. By default, they change the
[background](https://neovim.io/doc/user/options.html#'background') option,
overriding the function allows for further customization.

`update_interval` is how frequently the system appearance is checked, in
milliseconds. The value needs to be higher than the amount of milliseconds it
takes to query your system for the dark mode state. Otherwise, you risk
freezing neovim on shutdown.

`fallback` specifies the theme to use when the auto-detection fails. This can
be particularly useful to specify a default version when remotely connecting
via SSH, or when using neovim on a tty.

## 🚀 Usage

### Disabling at runtime

You can disable `auto-dark-mode.nvim` at runtime via `lua require('auto-dark-mode').disable()`.

## Thanks To
* [@nekowinston](https://github.com/nekowinston) for implementing Linux support and other contributions! <3
* [@adityamwagh](https://github.com/adityamwagh) for implementing Windows support

# Support
If you enjoy the plugin and want to support what I do

<a href="https://www.buymeacoffee.com/fperson" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/default-orange.png" alt="Buy Me A Coffee" height="41"  width="174"></a>
