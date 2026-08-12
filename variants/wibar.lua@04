local awful = require("awful")
local beautiful = require("beautiful")
local wibox = require("wibox")
local widgets = require("widgets")
local dpi = require("beautiful.xresources").apply_dpi

return function(s)
  -- The right-hand section is assembled rather than written as one literal,
  -- because the systray is only on one screen. Building the array with
  -- table.insert keeps it free of holes: a nil sitting in the middle of a
  -- declarative table makes the layout's child count undefined.
  local right = {
    spacing = beautiful.widget_group_spacing,
    layout = wibox.layout.fixed.horizontal,
  }

  -- The systray is a single system-wide widget: it can only live in one bar,
  -- so on a multi-monitor setup only the primary screen gets one. A
  -- margin-background-margin sandwich gives it an inset chip look.
  if s == screen.primary then
    table.insert(right, {
      {
        {
          wibox.widget.systray(),
          margins = dpi(4),
          widget = wibox.container.margin,
        },
        bg = beautiful.bg_focus,
        shape = beautiful.shape_small,
        widget = wibox.container.background,
      },
      left = dpi(8),
      right = dpi(8),
      top = dpi(4),
      bottom = dpi(4),
      widget = wibox.container.margin,
    })
  end

  -- The status readouts, spaced as a group of their own
  table.insert(right, {
    widgets.volume,
    widgets.wifi,
    widgets.battery.widget,
    spacing = beautiful.widget_spacing,
    layout = wibox.layout.fixed.horizontal,
  })

  table.insert(right, {
    {
      s.mylayoutbox,
      forced_height = beautiful.wibar_height * 0.6,
      forced_width = beautiful.wibar_height * 0.6,
      widget = wibox.container.constraint,
    },
    halign = "center",
    valign = "center",
    widget = wibox.container.place,
  })

  local wibar = awful.wibar({
    position = "top",
    screen = s,
    widget = {
      {
        widgets.taglist(s),
        -- The prompt for Mod+R (run) and Mod+X (Lua): without a home in the
        -- bar, prompts still run but type into an invisible textbox
        s.mypromptbox,
        spacing = beautiful.widget_group_spacing,
        layout = wibox.layout.fixed.horizontal,
      },
      {
        nil,
        widgets.clock,
        nil,
        expand = "none",
        layout = wibox.layout.align.horizontal,
      },
      right,
      layout = wibox.layout.align.horizontal,
    },
  })
  return wibar
end
