local awful = require("awful")
local gears = require("gears")
local wibox = require("wibox")
local beautiful = require("beautiful")

-- Both mutable parts carry an id, so building the widget and updating it later
-- go through the same door: get_children_by_id.
local wifi_widget = wibox.widget({
  {
    {
      id = "icon",
      image = beautiful.icon("wifi.svg"),
      halign = "center",
      valign = "center",
      widget = wibox.widget.imagebox,
    },
    margins = beautiful.widget_icon_margins,
    widget = wibox.container.margin,
  },
  {
    id = "text",
    widget = wibox.widget.textbox,
  },
  spacing = beautiful.widget_icon_spacing,
  layout = wibox.layout.fixed.horizontal,
})

wifi_widget.tooltip = awful.tooltip({
  objects = { wifi_widget },
})

local function get_ssid_cmd()
  return [[
    # Try iw first (modern, Wayland-friendly)
    if command -v iw >/dev/null 2>&1; then
      interface=$(iw dev 2>/dev/null | grep "Interface" | head -1 | awk '{print $2}')
      if [ -n "$interface" ]; then
        iw dev "$interface" link 2>/dev/null | grep "SSID" | awk '{$1=""; print $0}' | xargs
      fi
    # Fallback to iwgetid
    elif command -v iwgetid >/dev/null 2>&1; then
      iwgetid -r 2>/dev/null
    fi
  ]]
end

local function update()
  -- Since I only have 2 wifi svgs, it's either on or off.  So I only really need to get the ssid and set a tooltip.
  -- I'll do a little check to see if it says "Not connected", if so, I'll set the svg to wifi-off.svg
  awful.spawn.easy_async_with_shell(get_ssid_cmd(), function(ssid)
    local ssid_string = string.gsub(ssid, "\n", "")
    local connected = ssid_string ~= "" and not string.find(ssid_string, "Not connected")

    wifi_widget:get_children_by_id("text")[1].text = connected and ssid_string or ""
    wifi_widget.tooltip.text = connected and ssid_string or "Not connected"
    wifi_widget:get_children_by_id("icon")[1].image = beautiful.icon(connected and "wifi.svg" or "wifi-off.svg")
  end)
end

gears.timer({
  timeout = 60,
  autostart = true,
  call_now = true,
  callback = update,
})

return wifi_widget
