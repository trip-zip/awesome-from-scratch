---------------------------------------------------------------------------
--- Dashboard Calendar Section
--
-- A clean calendar widget with today highlighted.
--
-- @author awesome-from-scratch
-- @copyright 2025
---------------------------------------------------------------------------

local awful = require("awful")
local beautiful = require("beautiful")
local gears = require("gears")
local wibox = require("wibox")

local calendar_widget = {}

--- Create the calendar section
function calendar_widget.create()
    -- Calendar styling functions
    local function decorate_cell(widget, flag, date)
        local props = {
            markup = widget.text,
            halign = "center",
            valign = "center",
            widget = wibox.widget.textbox,
        }

        if flag == "header" then
            -- Month/Year header
            props.font = "JetBrainsMono Nerd Font Bold 12"
            props.markup = '<span color="' .. (beautiful.primary_color or "#d65d0e") .. '">' .. widget.text .. '</span>'
        elseif flag == "weekday" then
            -- Day names
            props.font = "JetBrainsMono Nerd Font Bold 10"
            props.markup = '<span color="' .. (beautiful.fg_normal or "#ebdbb2") .. '88">' .. widget.text .. '</span>'
        elseif flag == "normal" then
            -- Regular days
            props.font = "JetBrainsMono Nerd Font 10"
        elseif flag == "focus" then
            -- Today
            props.font = "JetBrainsMono Nerd Font Bold 10"
            return wibox.widget({
                {
                    props,
                    halign = "center",
                    valign = "center",
                    widget = wibox.container.place,
                },
                bg = beautiful.primary_color or "#d65d0e",
                fg = beautiful.bg_normal or "#282828",
                shape = gears.shape.circle,
                forced_width = 28,
                forced_height = 28,
                widget = wibox.container.background,
            })
        else
            -- Other month days
            props.font = "JetBrainsMono Nerd Font 10"
            props.markup = '<span color="' .. (beautiful.fg_normal or "#ebdbb2") .. '44">' .. widget.text .. '</span>'
        end

        return wibox.widget({
            {
                props,
                halign = "center",
                valign = "center",
                widget = wibox.container.place,
            },
            forced_width = 28,
            forced_height = 28,
            widget = wibox.container.background,
        })
    end

    -- Create the calendar
    local cal = wibox.widget({
        date = os.date("*t"),
        font = "JetBrainsMono Nerd Font 10",
        spacing = 4,
        start_sunday = false,
        long_weekdays = false,
        fn_embed = decorate_cell,
        widget = wibox.widget.calendar.month,
    })

    -- Navigation buttons
    local prev_button = wibox.widget({
        {
            text = "󰅁",
            font = "JetBrainsMono Nerd Font 14",
            halign = "center",
            widget = wibox.widget.textbox,
        },
        widget = wibox.container.background,
    })

    local next_button = wibox.widget({
        {
            text = "󰅂",
            font = "JetBrainsMono Nerd Font 14",
            halign = "center",
            widget = wibox.widget.textbox,
        },
        widget = wibox.container.background,
    })

    local today_button = wibox.widget({
        {
            text = "Today",
            font = "JetBrainsMono Nerd Font 10",
            halign = "center",
            widget = wibox.widget.textbox,
        },
        fg = beautiful.primary_color or "#d65d0e",
        widget = wibox.container.background,
    })

    -- Current displayed date (for navigation)
    local displayed_date = os.date("*t")

    -- Update calendar display
    local function update_calendar()
        cal.date = {
            year = displayed_date.year,
            month = displayed_date.month,
            day = os.date("*t").day, -- Keep today highlighted
        }
    end

    -- Navigation actions
    prev_button:buttons(gears.table.join(
        awful.button({}, 1, function()
            displayed_date.month = displayed_date.month - 1
            if displayed_date.month < 1 then
                displayed_date.month = 12
                displayed_date.year = displayed_date.year - 1
            end
            update_calendar()
        end)
    ))

    next_button:buttons(gears.table.join(
        awful.button({}, 1, function()
            displayed_date.month = displayed_date.month + 1
            if displayed_date.month > 12 then
                displayed_date.month = 1
                displayed_date.year = displayed_date.year + 1
            end
            update_calendar()
        end)
    ))

    today_button:buttons(gears.table.join(
        awful.button({}, 1, function()
            displayed_date = os.date("*t")
            update_calendar()
        end)
    ))

    -- Hover effects
    for _, btn in ipairs({ prev_button, next_button, today_button }) do
        btn:connect_signal("mouse::enter", function()
            btn.fg = beautiful.primary_color_hover or "#fe8019"
        end)
        btn:connect_signal("mouse::leave", function()
            btn.fg = btn == today_button and (beautiful.primary_color or "#d65d0e") or beautiful.fg_normal
        end)
    end

    return wibox.widget({
        {
            {
                text = "Calendar",
                font = "JetBrainsMono Nerd Font Bold 11",
                widget = wibox.widget.textbox,
            },
            nil,
            {
                prev_button,
                today_button,
                next_button,
                spacing = 12,
                layout = wibox.layout.fixed.horizontal,
            },
            layout = wibox.layout.align.horizontal,
        },
        {
            {
                cal,
                halign = "center",
                widget = wibox.container.place,
            },
            top = 8,
            widget = wibox.container.margin,
        },
        spacing = 8,
        layout = wibox.layout.fixed.vertical,
    })
end

return calendar_widget
