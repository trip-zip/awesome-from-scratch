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
        -- Style the original widget based on cell type
        if flag == "header" then
            -- Month/Year header
            widget.font = "JetBrainsMono Nerd Font Bold 12"
            widget.markup = '<span color="' .. (beautiful.primary_color or "#d65d0e") .. '">' .. (widget.text or "") .. '</span>'
            return widget
        elseif flag == "weekday" then
            -- Day names
            widget.font = "JetBrainsMono Nerd Font Bold 10"
            widget.markup = '<span color="' .. (beautiful.fg_normal or "#ebdbb2") .. '88">' .. (widget.text or "") .. '</span>'
            return widget
        elseif flag == "focus" then
            -- Today - orange background (no forced size, let it match other cells)
            widget.font = "JetBrainsMono Nerd Font Bold 10"
            return wibox.widget({
                widget,
                bg = beautiful.primary_color or "#d65d0e",
                fg = beautiful.bg_normal or "#282828",
                shape = function(cr, w, h)
                    gears.shape.rounded_rect(cr, w, h, 4)
                end,
                widget = wibox.container.background,
            })
        elseif flag == "blank" then
            -- Empty cells
            return widget
        else
            -- Normal days and other month days
            widget.font = "JetBrainsMono Nerd Font 10"
            if flag ~= "normal" then
                -- Other month days - dimmed
                widget.markup = '<span color="' .. (beautiful.fg_normal or "#ebdbb2") .. '44">' .. (widget.text or "") .. '</span>'
            end
            return widget
        end
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
            cal,
            top = 8,
            widget = wibox.container.margin,
        },
        spacing = 8,
        layout = wibox.layout.fixed.vertical,
    })
end

return calendar_widget
