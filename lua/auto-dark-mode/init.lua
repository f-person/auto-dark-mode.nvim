local utils = require 'auto-dark-mode.utils'

---@param callback fun(is_dark_mode: boolean)
local function check_is_dark_mode(callback)
    utils.start_job('defaults read -g AppleInterfaceStyle', {
        on_exit = function(exit_code)
            local is_dark_mode = exit_code == 0
            callback(is_dark_mode)
        end
    })
end
