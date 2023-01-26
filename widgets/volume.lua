local awful = require("awful")
local recolor = require("gears").color.recolor_image
local beautiful = require("beautiful")
local wrappers = require("widgets.wrappers")
local icon_dir = string.format("%s/.config/awesome/icons", os.getenv("HOME"))

--[[
I have 4 volume related svgs, so I'll need to be a little weird about how to display it.
volume-x.svg will only be used for mute.
volume.svg will be for 0-25% volume.  I don't want it to go higher than that since the svg looks almost empty
volume-1 will be for 26-75% volume. 
volume-2 will be for 76-100% volume. 
pamixer is what I use for volume.  Change the cmd if you use something different.  Just make sure the output doesn't have the % symbol to deal with.
]]

local icon_color = beautiful.fg_normal
local background_color = beautiful.highlight
local background_color_hover = beautiful.highlight_hover
local volume = wrappers.image_widget("/volume-2.svg", icon_color)
-- local volume_widget = wrappers.square_icon(volume, background_color, background_color_hover)
local volume_widget = wrappers.icon_with_text(volume)

volume_widget.tooltip = awful.tooltip({
  objects = { volume_widget },
})

local function update_volume()
  awful.spawn.easy_async_with_shell("pamixer --get-volume", function(vol)
    -- INFO: This stdout contains a \n character that messes up how the tooltip looks.
    local vol_string = string.gsub(vol, "\n", "")
    local tbox = volume_widget:get_children_by_id("text")[1]
    volume_widget.tooltip.text = " " .. vol_string .. "%"
    tbox.text = " " .. vol_string .. "%"

    --INFO: The way pamixer works, if you increase volume, it does not break `mute`.  So I want to update the tooltip, but not the icon, that's why I have it nested instead of a separate function.
    awful.spawn.easy_async_with_shell("pamixer --get-mute", function(mute)
      if string.find(mute, "true") then
        volume.image = recolor(icon_dir .. "/volume-x.svg", icon_color)
      else
        local volume_level = tonumber(vol)
        if volume_level == 0 then
          volume.image = recolor(icon_dir .. "/volume-x.svg", icon_color)
        elseif volume_level <= 25 then
          volume.image = recolor(icon_dir .. "/volume.svg", icon_color)
        elseif volume_level <= 75 then
          volume.image = recolor(icon_dir .. "/volume-1.svg", icon_color)
        else
          volume.image = recolor(icon_dir .. "/volume-2.svg", icon_color)
        end
      end
    end)
  end)
end

update_volume()

awesome.connect_signal("volume::update", function()
  update_volume()
end)

return volume_widget
