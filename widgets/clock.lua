local gears = require("gears")
local beautiful = require("beautiful")
local wrappers = require("widgets.wrappers")

local clock = wrappers.image_widget("/clock.svg", beautiful.fg_normal)
local clock_widget = wrappers.icon_with_text(clock)

-- `icon_with_text` gave the textbox `id = "text"`. That id is the whole reason we can
-- reach back into a declaratively built widget and change one piece of it.
local set_clock = function()
  local tbox = clock_widget:get_children_by_id("text")[1]
  tbox.text = " " .. os.date("%I:%M")
end

gears.timer({
  timeout = 5,
  autostart = true,
  call_now = true,
  callback = set_clock,
})

return clock_widget
