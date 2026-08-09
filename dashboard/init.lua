local awful = require("awful")
local beautiful = require("beautiful")
local gears = require("gears")
local wibox = require("wibox")

local dashboard = {}

-- Dashboard state
local dashboard_visible = false
local dashboard_popup = nil

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

--- Toggle dashboard visibility
function dashboard.toggle()
  if dashboard_visible then
    dashboard.hide()
  else
    dashboard.show()
  end
end

--- Show the dashboard
function dashboard.show()
  if dashboard_visible then
    return
  end

  local s = awful.screen.focused()

  -- Build the widget tree once. Rebuilding it on every open would also
  -- re-create each section's timers and signal connections — a leak.
  if not dashboard_popup then
    dashboard_popup = awful.popup({
      widget = create_dashboard_widget(),
      screen = s,
      ontop = true,
      visible = false,
      bg = "#00000000", -- Fully transparent (widget has its own bg)
      shape = beautiful.shape,
      border_width = config.border_width,
      border_color = config.border_color,
    })
  end

  -- Update screen placement
  dashboard_popup.screen = s
  awful.placement.top_right(dashboard_popup, {
    margins = {
      top = beautiful.wibar_height + beautiful.useless_gap * 3,
      right = beautiful.useless_gap * 2,
    },
    parent = s,
  })

  -- Sync sections that mirror system state (volume, brightness, radios)
  sliders.refresh()
  toggles.refresh()

  dashboard_popup.visible = true
  dashboard_visible = true

  -- Emit signal for other widgets to react
  awesome.emit_signal("dashboard::visible", true)
end

--- Hide the dashboard
function dashboard.hide()
  if not dashboard_visible then
    return
  end

  if dashboard_popup then
    dashboard_popup.visible = false
  end

  dashboard_visible = false
  awesome.emit_signal("dashboard::visible", false)
end

--- Check if dashboard is visible
function dashboard.is_visible()
  return dashboard_visible
end

-- Close dashboard when clicking outside
client.connect_signal("button::press", function()
  if dashboard_visible then
    dashboard.hide()
  end
end)

-- Close on tag change
tag.connect_signal("property::selected", function()
  if dashboard_visible then
    dashboard.hide()
  end
end)

return dashboard
