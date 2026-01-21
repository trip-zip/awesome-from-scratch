---------------------------------------------------------------------------
--- Dashboard Profile Section
--
-- Displays user info, time, and date with a greeting.
--
-- @author awesome-from-scratch
-- @copyright 2025
---------------------------------------------------------------------------

local awful = require("awful")
local beautiful = require("beautiful")
local gears = require("gears")
local wibox = require("wibox")

local profile = {}

-- Get greeting based on time of day
local function get_greeting()
    local hour = tonumber(os.date("%H"))
    local user = os.getenv("USER") or "user"

    if hour >= 5 and hour < 12 then
        return "Good morning, " .. user
    elseif hour >= 12 and hour < 17 then
        return "Good afternoon, " .. user
    elseif hour >= 17 and hour < 21 then
        return "Good evening, " .. user
    else
        return "Good night, " .. user
    end
end

--- Create the profile widget
function profile.create()
    -- Time display
    local time_widget = wibox.widget({
        format = "%H:%M",
        font = "JetBrainsMono Nerd Font Bold 48",
        halign = "center",
        widget = wibox.widget.textclock,
    })

    -- Date display
    local date_widget = wibox.widget({
        format = "%A, %B %d",
        font = "JetBrainsMono Nerd Font 14",
        halign = "center",
        widget = wibox.widget.textclock,
    })

    -- Greeting
    local greeting_widget = wibox.widget({
        text = get_greeting(),
        font = "JetBrainsMono Nerd Font 12",
        halign = "center",
        widget = wibox.widget.textbox,
    })

    -- Update greeting periodically
    gears.timer({
        timeout = 60,
        autostart = true,
        call_now = true,
        callback = function()
            greeting_widget.text = get_greeting()
        end,
    })

    -- User icon (optional - can use profile picture if available)
    local user_icon = wibox.widget({
        {
            text = "",
            font = "JetBrainsMono Nerd Font 36",
            halign = "center",
            valign = "center",
            widget = wibox.widget.textbox,
        },
        fg = beautiful.primary_color or beautiful.fg_normal,
        widget = wibox.container.background,
    })

    return wibox.widget({
        {
            {
                user_icon,
                {
                    time_widget,
                    date_widget,
                    {
                        greeting_widget,
                        fg = (beautiful.fg_normal or "#ebdbb2") .. "AA",
                        widget = wibox.container.background,
                    },
                    spacing = 4,
                    layout = wibox.layout.fixed.vertical,
                },
                spacing = 16,
                layout = wibox.layout.fixed.vertical,
            },
            halign = "center",
            widget = wibox.container.place,
        },
        {
            {
                orientation = "horizontal",
                forced_height = 1,
                color = (beautiful.fg_normal or "#ebdbb2") .. "33",
                widget = wibox.widget.separator,
            },
            top = 16,
            widget = wibox.container.margin,
        },
        layout = wibox.layout.fixed.vertical,
    })
end

return profile
