local awful = require("awful")
local beautiful = require("beautiful")
local gears = require("gears")
local wibox = require("wibox")

local titlebar = {}

-- Configuration
local config = {
    button_size = 14,
    button_spacing = 8,
    button_margin = 10,
    height = 32,
    -- Traffic light colors
    colors = {
        close = {
            normal = "#cc241d",
            hover = "#fb4934",
            unfocused = "#928374",
        },
        minimize = {
            normal = "#d79921",
            hover = "#fabd2f",
            unfocused = "#928374",
        },
        maximize = {
            normal = "#98971a",
            hover = "#b8bb26",
            unfocused = "#928374",
        },
    },
}

--- Create a titlebar button
-- @param c The client
-- @param action "close" | "minimize" | "maximize" | "floating"
-- @param colors Table with normal, hover, unfocused colors
-- @param callback Function to call on click
local function create_button(c, action, colors, callback)
    local button = wibox.widget({
        {
            forced_width = config.button_size,
            forced_height = config.button_size,
            widget = wibox.widget.base.empty_widget,
        },
        bg = colors.normal,
        shape = beautiful.shape_small or gears.shape.circle,
        widget = wibox.container.background,
    })

    local is_focused = client.focus == c

    -- Update button appearance based on focus state
    local function update_focus()
        is_focused = client.focus == c
        if not button._is_hovered then
            button.bg = is_focused and colors.normal or colors.unfocused
        end
    end

    -- Track hover state
    button._is_hovered = false

    button:connect_signal("mouse::enter", function()
        button._is_hovered = true
        button.bg = colors.hover
    end)

    button:connect_signal("mouse::leave", function()
        button._is_hovered = false
        button.bg = is_focused and colors.normal or colors.unfocused
    end)

    -- Click handler
    button:buttons(gears.table.join(
        awful.button({}, 1, function()
            callback(c)
        end)
    ))

    -- Listen for focus changes
    c:connect_signal("focus", update_focus)
    c:connect_signal("unfocus", update_focus)

    -- Initial state
    update_focus()

    return button
end

--- Create the button group (traffic lights)
local function create_button_group(c)
    local close_btn = create_button(c, "close", config.colors.close, function(client)
        client:kill()
    end)

    local minimize_btn = create_button(c, "minimize", config.colors.minimize, function(client)
        client.minimized = true
    end)

    local maximize_btn = create_button(c, "maximize", config.colors.maximize, function(client)
        client.maximized = not client.maximized
    end)

    local button_group = wibox.widget({
        close_btn,
        minimize_btn,
        maximize_btn,
        spacing = config.button_spacing,
        layout = wibox.layout.fixed.horizontal,
    })

    return wibox.widget({
        button_group,
        left = config.button_margin,
        right = config.button_margin,
        widget = wibox.container.margin,
    })
end

--- Create the title widget
local function create_title(c)
    local title = wibox.widget({
        halign = "center",
        widget = awful.titlebar.widget.titlewidget(c),
    })

    -- Update title opacity based on focus
    local function update_focus()
        local is_focused = client.focus == c
        title.opacity = is_focused and 1.0 or 0.5
    end

    c:connect_signal("focus", update_focus)
    c:connect_signal("unfocus", update_focus)
    update_focus()

    return title
end

--- Setup titlebar for a client
function titlebar.setup(c)
    -- Titlebar drag/resize buttons
    local buttons = {
        awful.button({}, 1, function()
            c:activate({ context = "titlebar", action = "mouse_move" })
        end),
        awful.button({}, 3, function()
            c:activate({ context = "titlebar", action = "mouse_resize" })
        end),
    }

    -- Create the titlebar
    local tb = awful.titlebar(c, {
        size = config.height,
        bg_normal = beautiful.bg_normal,
        bg_focus = beautiful.bg_normal,
    })

    -- Build the layout
    tb.widget = {
        { -- Left: traffic light buttons
            create_button_group(c),
            layout = wibox.layout.fixed.horizontal,
        },
        { -- Middle: title (with drag)
            create_title(c),
            buttons = buttons,
            layout = wibox.layout.flex.horizontal,
        },
        { -- Right: empty (could add more buttons)
            layout = wibox.layout.fixed.horizontal,
        },
        layout = wibox.layout.align.horizontal,
    }
end

--- Initialize the titlebar system
-- Call this from rc.lua to replace the default titlebar handler
function titlebar.init()
    client.connect_signal("request::titlebars", function(c)
        titlebar.setup(c)
    end)
end

return titlebar
