---------------------------------------------------------------------------
--- Dashboard Sliders Section
--
-- Volume and brightness sliders with icons.
--
-- @author awesome-from-scratch
-- @copyright 2025
---------------------------------------------------------------------------

local awful = require("awful")
local beautiful = require("beautiful")
local gears = require("gears")
local wibox = require("wibox")

local sliders = {}

-- Slider configuration
local slider_config = {
    bar_height = 6,
    handle_width = 16,
    forced_height = 24,
}

--- Create a labeled slider widget
-- @tparam string icon The icon character
-- @tparam string color The accent color
-- @tparam function get_cmd Command to get current value
-- @tparam function set_cmd Function that takes value and returns set command
-- @tparam string signal Signal to listen for updates
local function create_slider(icon, color, get_cmd, set_cmd, signal)
    local slider = wibox.widget({
        bar_shape = gears.shape.rounded_bar,
        bar_height = slider_config.bar_height,
        bar_color = beautiful.bg_focus or "#3c3836",
        bar_active_color = color,
        handle_shape = gears.shape.circle,
        handle_width = slider_config.handle_width,
        handle_color = color,
        handle_border_width = 0,
        value = 50,
        minimum = 0,
        maximum = 100,
        forced_height = slider_config.forced_height,
        widget = wibox.widget.slider,
    })

    local icon_widget = wibox.widget({
        text = icon,
        font = "JetBrainsMono Nerd Font 18",
        halign = "center",
        valign = "center",
        widget = wibox.widget.textbox,
    })

    local value_widget = wibox.widget({
        text = "50%",
        font = "JetBrainsMono Nerd Font 11",
        halign = "right",
        forced_width = 40,
        widget = wibox.widget.textbox,
    })

    -- Update value display when slider changes
    slider:connect_signal("property::value", function()
        local value = math.floor(slider.value)
        value_widget.text = value .. "%"

        -- Update system value
        if set_cmd then
            awful.spawn.with_shell(set_cmd(value))
        end
    end)

    -- Get initial value
    if get_cmd then
        awful.spawn.easy_async_with_shell(get_cmd, function(stdout)
            local value = tonumber(stdout:match("(%d+)")) or 50
            slider.value = math.min(100, math.max(0, value))
            value_widget.text = math.floor(slider.value) .. "%"
        end)
    end

    -- Listen for external updates
    if signal then
        awesome.connect_signal(signal, function(value)
            if value then
                slider.value = math.min(100, math.max(0, value))
            end
        end)
    end

    return wibox.widget({
        {
            icon_widget,
            fg = color,
            widget = wibox.container.background,
        },
        {
            slider,
            left = 12,
            right = 12,
            widget = wibox.container.margin,
        },
        value_widget,
        layout = wibox.layout.align.horizontal,
    })
end

--- Create the sliders section
function sliders.create()
    -- Volume slider
    local volume_slider = create_slider(
        "󰕾",
        beautiful.primary_color or "#d65d0e",
        [[wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | awk '{print int($2*100)}' || echo 50]],
        function(value)
            return string.format("wpctl set-volume @DEFAULT_AUDIO_SINK@ %d%%", value)
        end,
        "volume::update"
    )

    -- Brightness slider
    local brightness_slider = create_slider(
        "󰃟",
        beautiful.accent or "#d79921",
        [[brightnessctl -m 2>/dev/null | cut -d',' -f4 | tr -d '%' || echo 50]],
        function(value)
            return string.format("brightnessctl set %d%%", value)
        end,
        "brightness::update"
    )

    return wibox.widget({
        {
            text = "Controls",
            font = "JetBrainsMono Nerd Font Bold 11",
            widget = wibox.widget.textbox,
        },
        {
            {
                volume_slider,
                brightness_slider,
                spacing = 12,
                layout = wibox.layout.fixed.vertical,
            },
            top = 8,
            widget = wibox.container.margin,
        },
        {
            {
                orientation = "horizontal",
                forced_height = 1,
                color = beautiful.fg_normal .. "33",
                widget = wibox.widget.separator,
            },
            top = 16,
            widget = wibox.container.margin,
        },
        layout = wibox.layout.fixed.vertical,
    })
end

return sliders
