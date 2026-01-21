---------------------------------------------------------------------------
--- Exit Screen
--
-- A full-screen power menu with keyboard navigation.
-- Options: Lock, Logout, Suspend, Reboot, Shutdown
--
-- @author awesome-from-scratch
-- @copyright 2025
---------------------------------------------------------------------------

local awful = require("awful")
local beautiful = require("beautiful")
local gears = require("gears")
local wibox = require("wibox")

local exitscreen = {}

-- State
local exitscreen_visible = false
local exitscreen_grabber = nil
local selected_index = 1
local exitscreen_popup = nil

-- Power options
local options = {
    {
        name = "Lock",
        icon = "󰌾",
        key = "l",
        command = function()
            -- Try common lock commands
            awful.spawn.with_shell([[
                if command -v swaylock >/dev/null 2>&1; then
                    swaylock -f
                elif command -v hyprlock >/dev/null 2>&1; then
                    hyprlock
                elif command -v i3lock >/dev/null 2>&1; then
                    i3lock -c 282828
                else
                    echo "No screen locker found" >&2
                fi
            ]])
        end,
    },
    {
        name = "Logout",
        icon = "󰗼",
        key = "e",
        command = function()
            awesome.quit()
        end,
    },
    {
        name = "Suspend",
        icon = "󰤄",
        key = "s",
        command = function()
            awful.spawn("systemctl suspend")
        end,
    },
    {
        name = "Reboot",
        icon = "󰜉",
        key = "r",
        command = function()
            awful.spawn("systemctl reboot")
        end,
    },
    {
        name = "Shutdown",
        icon = "󰐥",
        key = "p",
        command = function()
            awful.spawn("systemctl poweroff")
        end,
    },
}

-- Configuration
local config = {
    button_size = 100,
    icon_size = 36,
    spacing = 40,
}

--- Create a power button widget
local function create_button(option, index)
    local is_selected = index == selected_index

    local button = wibox.widget({
        {
            {
                {
                    text = option.icon,
                    font = "JetBrainsMono Nerd Font " .. config.icon_size,
                    halign = "center",
                    valign = "center",
                    widget = wibox.widget.textbox,
                },
                {
                    text = option.name,
                    font = "JetBrainsMono Nerd Font 12",
                    halign = "center",
                    widget = wibox.widget.textbox,
                },
                {
                    text = "[" .. option.key .. "]",
                    font = "JetBrainsMono Nerd Font 10",
                    halign = "center",
                    widget = wibox.widget.textbox,
                },
                spacing = 8,
                layout = wibox.layout.fixed.vertical,
            },
            margins = 16,
            widget = wibox.container.margin,
        },
        bg = is_selected and (beautiful.primary_color or "#d65d0e") or (beautiful.bg_focus or "#3c3836"),
        fg = is_selected and beautiful.bg_normal or beautiful.fg_normal,
        shape = beautiful.shape,
        forced_width = config.button_size,
        forced_height = config.button_size + 30,
        widget = wibox.container.background,
    })

    -- Click handler
    button:buttons(gears.table.join(
        awful.button({}, 1, function()
            exitscreen.hide()
            option.command()
        end)
    ))

    -- Hover
    button:connect_signal("mouse::enter", function()
        selected_index = index
        exitscreen.refresh()
    end)

    return button
end

--- Create the exit screen widget
local function create_exitscreen_widget()
    local buttons = {}
    for i, option in ipairs(options) do
        table.insert(buttons, create_button(option, i))
    end

    return wibox.widget({
        {
            {
                -- Title
                {
                    text = "What would you like to do?",
                    font = "JetBrainsMono Nerd Font Bold 18",
                    halign = "center",
                    widget = wibox.widget.textbox,
                },
                -- Buttons
                {
                    table.unpack(buttons),
                    spacing = config.spacing,
                    layout = wibox.layout.fixed.horizontal,
                },
                -- Hint
                {
                    text = "Press Escape to cancel",
                    font = "JetBrainsMono Nerd Font 11",
                    halign = "center",
                    widget = wibox.widget.textbox,
                },
                spacing = 32,
                layout = wibox.layout.fixed.vertical,
            },
            halign = "center",
            valign = "center",
            widget = wibox.container.place,
        },
        bg = (beautiful.bg_normal or "#282828") .. "E8",
        fg = beautiful.fg_normal,
        widget = wibox.container.background,
    })
end

--- Refresh the exit screen
function exitscreen.refresh()
    if exitscreen_popup then
        exitscreen_popup.widget = create_exitscreen_widget()
    end
end

--- Execute the selected option
local function execute_selected()
    if options[selected_index] then
        exitscreen.hide()
        options[selected_index].command()
    end
end

--- Start the key grabber
local function start_grabber()
    exitscreen_grabber = awful.keygrabber({
        autostart = true,
        stop_key = "Escape",
        stop_callback = function()
            exitscreen.hide()
        end,
        keypressed_callback = function(_, _, key, _)
            if key == "Return" then
                execute_selected()
            elseif key == "Left" or key == "h" then
                selected_index = math.max(1, selected_index - 1)
                exitscreen.refresh()
            elseif key == "Right" or key == "l" then
                selected_index = math.min(#options, selected_index + 1)
                exitscreen.refresh()
            else
                -- Check for shortcut keys
                for i, option in ipairs(options) do
                    if key == option.key then
                        selected_index = i
                        exitscreen.refresh()
                        -- Small delay for visual feedback
                        gears.timer.start_new(0.15, function()
                            execute_selected()
                            return false
                        end)
                        return
                    end
                end
            end
        end,
    })
end

--- Show the exit screen
function exitscreen.show()
    if exitscreen_visible then
        return
    end

    selected_index = 1

    local s = awful.screen.focused()

    if not exitscreen_popup then
        exitscreen_popup = awful.popup({
            widget = create_exitscreen_widget(),
            screen = s,
            placement = awful.placement.maximize,
            ontop = true,
            visible = false,
            bg = "#00000000",
        })
    end

    exitscreen_popup.screen = s
    awful.placement.maximize(exitscreen_popup)
    exitscreen_popup.widget = create_exitscreen_widget()
    exitscreen_popup.visible = true
    exitscreen_visible = true

    start_grabber()

    awesome.emit_signal("exitscreen::visible", true)
end

--- Hide the exit screen
function exitscreen.hide()
    if not exitscreen_visible then
        return
    end

    if exitscreen_grabber then
        exitscreen_grabber:stop()
        exitscreen_grabber = nil
    end

    if exitscreen_popup then
        exitscreen_popup.visible = false
    end

    exitscreen_visible = false
    awesome.emit_signal("exitscreen::visible", false)
end

--- Toggle the exit screen
function exitscreen.toggle()
    if exitscreen_visible then
        exitscreen.hide()
    else
        exitscreen.show()
    end
end

--- Check if exit screen is visible
function exitscreen.is_visible()
    return exitscreen_visible
end

return exitscreen
