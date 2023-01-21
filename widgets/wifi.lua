local awful = require("awful")
local gears = require("gears")
local beautiful = require("beautiful")
local wrappers = require("widgets.wrappers")

local wifi = wrappers.image_widget("/wifi.svg", beautiful.bg_normal)
local wifi_widget = wrappers.square_icon(wifi, beautiful.accent, beautiful.accent_hover)
wifi_widget.tooltip = awful.tooltip({
  objects = { wifi_widget },
})

local function update()
  -- Since I only have 2 wifi svgs, it's either on or off.  So I only really need to get the ssid and set a tooltip.
  -- I'll do a little check to see if it says "Not connected", if so, I'll set the svg to wifi-off.svg
  awful.spawn.easy_async_with_shell("iwgetid -r", function(stdout)
    wifi_widget.tooltip.text = stdout
    if string.find(stdout, "Not connected") then
      wifi.image = beautiful.icon_dir .. "/wifi-off.svg"
    else
      wifi.image = beautiful.icon_dir .. "/wifi.svg"
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
