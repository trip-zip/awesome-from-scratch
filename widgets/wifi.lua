local awful = require("awful")
local gears = require("gears")
local recolor = require("gears").color.recolor_image
local beautiful = require("beautiful")
local wrappers = require("widgets.wrappers")

local icon_color = beautiful.fg_normal
local background_color = beautiful.accent
local background_color_hover = beautiful.accent_hover

local wifi = wrappers.image_widget("/wifi.svg", icon_color)
-- local wifi_widget = wrappers.square_icon(wifi, background_color, background_color_hover)
local wifi_widget = wrappers.icon_with_text(wifi)
wifi_widget.tooltip = awful.tooltip({
  objects = { wifi_widget },
})

local function update()
  -- Since I only have 2 wifi svgs, it's either on or off.  So I only really need to get the ssid and set a tooltip.
  -- I'll do a little check to see if it says "Not connected", if so, I'll set the svg to wifi-off.svg
  awful.spawn.easy_async_with_shell("iwgetid -r", function(ssid)
    local ssid_string = string.gsub(ssid, "\n", "")
    wifi_widget.tooltip.text = ssid_string
    local tbox = wifi_widget:get_children_by_id("text")[1]
    wifi_widget.tooltip.text = " " .. ssid_string
    tbox.text = " " .. ssid_string
    if string.find(ssid, "Not connected") or ssid == "" then
      wifi.image = recolor(beautiful.icon_dir .. "/wifi-off.svg", icon_color)
    else
      wifi.image = recolor(beautiful.icon_dir .. "/wifi.svg", icon_color)
    end
  end)
end

gears.timer({
  timeout = 60,
  autostart = true,
  call_now = true,
  callback = update,
})

return wifi_widget
