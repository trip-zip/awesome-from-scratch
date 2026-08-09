local beautiful = require("beautiful")
local awful = require("awful")
local wibox = require("wibox")

-- `modkey` is the global rc.lua sets before any of this loads, the same one
-- keybindings.lua reads. The buttons below are built when the taglist is
-- created per screen, long after rc.lua has set it.
return function(s)
  local taglist_buttons = {
    awful.button({}, 1, function(t)
      t:view_only()
    end),
    awful.button({ modkey }, 1, function(t)
      if client.focus then
        client.focus:move_to_tag(t)
      end
    end),
    awful.button({}, 3, awful.tag.viewtoggle),
    awful.button({ modkey }, 3, function(t)
      if client.focus then
        client.focus:toggle_tag(t)
      end
    end),
    awful.button({}, 4, function(t)
      awful.tag.viewprev(t.screen)
    end),
    awful.button({}, 5, function(t)
      awful.tag.viewnext(t.screen)
    end),
  }

  local update_tag = function(widget, tag, index, taglist)
    local w = widget:get_children_by_id("icon_role")[1]
    local indicator = widget:get_children_by_id("indicator")[1]
    -- Tags carry their icon (set in rc.lua); anything without one gets a
    -- generic marker instead of crashing the taglist
    local icon_name = tag.icon_name or "grid.svg"
    local color

    if tag.selected then
      color = beautiful.primary_color
      indicator.bg = beautiful.primary_color
    elseif tag.urgent then
      color = beautiful.bg_urgent
      indicator.bg = beautiful.bg_normal
    elseif #tag:clients() > 0 then
      color = beautiful.active_hover
      indicator.bg = beautiful.bg_normal
    else
      color = beautiful.fg_normal
      indicator.bg = beautiful.bg_normal
    end

    w.image = beautiful.icon(icon_name, color)
  end

  return awful.widget.taglist({
    screen = s,
    filter = awful.widget.taglist.filter.all,
    buttons = taglist_buttons,
    widget_template = {
      {
        id = "indicator",
        wibox.widget.base.make_widget(),
        forced_height = 2,
        bg = beautiful.bg_normal,
        widget = wibox.container.background,
      },
      {
        {
          id = "icon_role",
          widget = wibox.widget.imagebox,
        },
        margins = beautiful.widget_icon_margins,
        widget = wibox.container.margin,
      },
      layout = wibox.layout.fixed.vertical,
      create_callback = update_tag,
      update_callback = update_tag,
    },
  })
end
