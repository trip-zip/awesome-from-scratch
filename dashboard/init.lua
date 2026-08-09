local awful = require("awful")
local beautiful = require("beautiful")
local gears = require("gears")
local wibox = require("wibox")
local modal = require("modal")

local dashboard = {}

-- Load submodules
local profile = require("dashboard.profile")
local sliders = require("dashboard.sliders")
local toggles = require("dashboard.toggles")
local calendar = require("dashboard.calendar")

-- Configuration
local config = {
  width = 440,
  margin = 20,
  spacing = 16,
  bg = beautiful.bg_normal .. "F2", -- Slightly transparent
  border_width = beautiful.border_width or 1,
  border_color = beautiful.primary_color,
}

--- Create the main dashboard widget
local function create_dashboard_widget()
  return wibox.widget({
    {
      {
        -- Profile section (user info + time)
        profile.create(),
        -- Sliders section (volume, brightness)
        sliders.create(),
        -- Quick toggles section
        toggles.create(),
        -- Calendar section
        calendar.create(),
        spacing = config.spacing,
        layout = wibox.layout.fixed.vertical,
      },
      margins = config.margin,
      widget = wibox.container.margin,
    },
    bg = config.bg,
    shape = beautiful.shape,
    forced_width = config.width,
    widget = wibox.container.background,
  })
end

-- Docked top right, under the bar, on whatever screen the popup is on
local function place(d)
  awful.placement.top_right(d, {
    margins = {
      top = beautiful.wibar_height + beautiful.useless_gap * 3,
      right = beautiful.useless_gap * 2,
    },
    parent = d.screen,
  })
end

-- The modal controller owns visibility, click-outside/tag-change dismissal,
-- Escape, and the dashboard::visible signal. The widget tree is built once
-- (build_popup runs on first show); rebuilding it per open would also
-- re-create each section's timers and signal connections - a leak.
local controller = modal.new({
  name = "dashboard",
  build_popup = function()
    return awful.popup({
      widget = create_dashboard_widget(),
      screen = awful.screen.focused(),
      ontop = true,
      visible = false,
      bg = "#00000000", -- Fully transparent (widget has its own bg)
      shape = beautiful.shape,
      border_width = config.border_width,
      border_color = config.border_color,
      -- Placement lives on the popup itself, not in on_show: awful.popup
      -- re-applies it whenever the popup's size changes, which covers the
      -- first show, when the widget has not been measured yet.
      placement = place,
    })
  end,
  on_show = function(popup)
    place(popup)

    -- Sync sections that mirror system state (volume, brightness, radios)
    sliders.refresh()
    toggles.refresh()
  end,
})

dashboard.show = controller.show
dashboard.hide = controller.hide
dashboard.toggle = controller.toggle
dashboard.is_visible = controller.is_visible

return dashboard
