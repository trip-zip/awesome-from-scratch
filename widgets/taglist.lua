local beautiful = require("beautiful")
local gears = require("gears")
local awful = require("awful")
local wibox = require("wibox")

local tag_to_image_map = {
  code = "/terminal.svg",
  web = "/chrome.svg",
  chat = "/slack.svg",
  db = "/server.svg",
  games = "/play.svg",
}

return function(s)
  awful.tag({ "code", "web", "chat", "db", "games" }, s, awful.layout.layouts[1])

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
    local icon_name = tag_to_image_map[tag.name]
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

    w.image = gears.color.recolor_image(beautiful.icon_dir .. icon_name, color)
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
      nil,
      {
        {
          id = "icon_role",
          widget = wibox.widget.imagebox,
        },
        margins = beautiful.wibar_height * 0.25,
        widget = wibox.container.margin,
      },
      layout = wibox.layout.fixed.vertical,
      create_callback = update_tag,
      update_callback = update_tag,
    },
  })
end
