local awful = require("awful")
local beautiful = require("beautiful")
local gears = require("gears")
local wibox = require("wibox")

local profile = {}

-- Battery state (updated by timer)
local battery_state = {
  percentage = "N/A",
  status = "unknown",
  time = "N/A",
}

-- Update battery info
local function update_battery()
  local cmd = [[
        if command -v upower >/dev/null 2>&1; then
            upower -i $(upower -e | grep 'BAT') | grep -E "state|to full|to empty|percentage" | cut -d ':' -f2 | awk '{$1=$1};1'
        else
            if [ -f /sys/class/power_supply/BAT1/capacity ] && [ -f /sys/class/power_supply/BAT1/status ]; then
                cat /sys/class/power_supply/BAT1/status
                echo "N/A"
                echo "$(cat /sys/class/power_supply/BAT1/capacity)%"
            else
                echo "unknown"
                echo "N/A"
                echo "N/A"
            fi
        fi
    ]]

  awful.spawn.easy_async_with_shell(cmd, function(stdout)
    local data = gears.string.split(stdout, "\n")
    battery_state.status = data[1] or "unknown"
    battery_state.time = data[2] or "N/A"
    battery_state.percentage = data[3] or "N/A"
  end)
end

-- Start battery update timer
gears.timer({
  timeout = 30,
  autostart = true,
  call_now = true,
  callback = update_battery,
})

-- Get greeting based on time of day
local function get_greeting()
  local hour = tonumber(os.date("%H"))
  local user = os.getenv("USER") or "user"

  if hour >= 5 and hour < 12 then
    return "Good morning, " .. user
  elseif hour >= 12 and hour < 17 then
    return "Good afternoon, " .. user
  elseif hour >= 17 and hour < 21 then
    return "Good evening, " .. user
  else
    return "Good night, " .. user
  end
end

--- Create the profile widget
function profile.create()
  -- Time display
  local time_widget = wibox.widget({
    format = "%H:%M",
    font = beautiful.font_size(48, "Bold"),
    halign = "center",
    widget = wibox.widget.textclock,
  })

  -- Date display
  local date_widget = wibox.widget({
    format = "%A, %B %d",
    font = beautiful.font_size(14),
    halign = "center",
    widget = wibox.widget.textclock,
  })

  -- Greeting
  local greeting_widget = wibox.widget({
    text = get_greeting(),
    font = beautiful.font_size(12),
    halign = "center",
    widget = wibox.widget.textbox,
  })

  -- Update greeting periodically
  gears.timer({
    timeout = 60,
    autostart = true,
    call_now = true,
    callback = function()
      greeting_widget.text = get_greeting()
    end,
  })

  -- Battery indicator
  local function get_battery_icon()
    local status = battery_state.status:lower()
    if status:find("charging") then
      return "󰂄" -- charging icon
    elseif battery_state.percentage ~= "N/A" then
      local pct = tonumber(battery_state.percentage:match("(%d+)")) or 0
      if pct >= 90 then
        return "󰁹"
      elseif pct >= 70 then
        return "󰂁"
      elseif pct >= 50 then
        return "󰁿"
      elseif pct >= 30 then
        return "󰁽"
      elseif pct >= 10 then
        return "󰁻"
      else
        return "󰁺"
      end
    end
    return "󰁹"
  end

  local function get_battery_text()
    local pct = battery_state.percentage
    local status = battery_state.status:lower()
    local time = battery_state.time

    local text = pct
    if status:find("charging") and time ~= "N/A" then
      text = text .. " · " .. time .. " until full"
    elseif status:find("discharging") and time ~= "N/A" then
      text = text .. " · " .. time .. " remaining"
    elseif status:find("full") or (not status:find("charging") and not status:find("discharging")) then
      text = text .. " · Plugged in"
    end
    return text
  end

  local battery_icon = wibox.widget({
    text = get_battery_icon(),
    font = beautiful.font_size(14),
    widget = wibox.widget.textbox,
  })

  local battery_text = wibox.widget({
    text = get_battery_text(),
    font = beautiful.font_size(11),
    widget = wibox.widget.textbox,
  })

  local battery_widget = wibox.widget({
    {
      battery_icon,
      battery_text,
      spacing = 8,
      layout = wibox.layout.fixed.horizontal,
    },
    halign = "center",
    widget = wibox.container.place,
  })

  -- Update battery display periodically
  gears.timer({
    timeout = 30,
    autostart = true,
    call_now = true,
    callback = function()
      battery_icon.text = get_battery_icon()
      battery_text.text = get_battery_text()
    end,
  })

  -- User icon (optional - can use profile picture if available)
  local user_icon = wibox.widget({
    {
      text = "",
      font = beautiful.font_size(36),
      halign = "center",
      valign = "center",
      widget = wibox.widget.textbox,
    },
    fg = beautiful.primary_color or beautiful.fg_normal,
    widget = wibox.container.background,
  })

  return wibox.widget({
    {
      {
        user_icon,
        {
          time_widget,
          date_widget,
          {
            greeting_widget,
            fg = beautiful.fg_normal .. "AA",
            widget = wibox.container.background,
          },
          spacing = 4,
          layout = wibox.layout.fixed.vertical,
        },
        spacing = 16,
        layout = wibox.layout.fixed.vertical,
      },
      halign = "center",
      widget = wibox.container.place,
    },
    {
      {
        battery_widget,
        fg = beautiful.fg_normal .. "CC",
        widget = wibox.container.background,
      },
      top = 12,
      widget = wibox.container.margin,
    },
    {
      {
        orientation = "horizontal",
        forced_height = 1,
        color = beautiful.fg_normal .. "33",
        widget = wibox.widget.separator,
      },
      top = 16,
      widget = wibox.container.margin,
    },
    layout = wibox.layout.fixed.vertical,
  })
end

return profile
