-- Advanced Notification System for AwesomeWM
-- This module provides comprehensive notification handling with:
-- - Rule-based filtering and styling
-- - Interactive notifications with actions
-- - Custom positioning and layouts
-- - App-specific handling
-- - Notification center/history

local awful = require("awful")
local gears = require("gears")
local wibox = require("wibox")
local ruled = require("ruled")
local naughty = require("naughty")
local beautiful = require("beautiful")

-- Module table
local M = {}

-- Configuration
M.config = {
  -- Default timeout for notifications (seconds)
  default_timeout = 5,
  
  -- Position presets
  positions = {
    top_right = "top_right",
    top_left = "top_left",
    bottom_right = "bottom_right",
    bottom_left = "bottom_left",
    top_middle = "top_middle",
    bottom_middle = "bottom_middle",
  },
  
  -- Special contacts for custom styling
  special_contacts = {
    wife = { "Wife", "Honey", "Love" }, -- Add actual contact names
  },
  
  -- DND mode settings
  dnd_mode = false,
  focus_mode = false,
  
  -- Sound settings
  enable_sounds = true,
  sound_files = {
    normal = "/usr/share/sounds/freedesktop/stereo/message.oga",
    critical = "/usr/share/sounds/freedesktop/stereo/complete.oga",
  },
}

-- Notification history storage
M.history = {}
M.unread_count = 0
M.max_history = 50
M.active_notifications = {} -- Track currently active notifications

-- Helper function to check if notification matches special contact
local function is_special_contact(notification, contact_group)
  if not notification.message then return false end
  
  for _, name in ipairs(M.config.special_contacts[contact_group] or {}) do
    if notification.message:match(name) or 
       (notification.title and notification.title:match(name)) then
      return true
    end
  end
  return false
end

-- Helper function to add notification to history
local function add_to_history(notification)
  local history_item = {
    title = notification.title,
    message = notification.message,
    app_name = notification.app_name,
    timestamp = os.time(),
    urgency = notification.urgency,
    icon = notification.icon,
    id = notification.id or tostring(os.time() .. math.random()),
    is_read = false,
  }
  
  table.insert(M.history, 1, history_item)
  M.unread_count = M.unread_count + 1
  
  -- Store reference to active notification
  if notification.resident then
    M.active_notifications[history_item.id] = notification
  end
  
  -- Trim history if too long
  while #M.history > M.max_history do
    local removed = table.remove(M.history)
    if not removed.is_read then
      M.unread_count = math.max(0, M.unread_count - 1)
    end
    if M.active_notifications[removed.id] then
      M.active_notifications[removed.id] = nil
    end
  end
end

-- Helper function to play notification sound
local function play_sound(urgency)
  if not M.config.enable_sounds then return end
  
  local sound_file = M.config.sound_files[urgency] or M.config.sound_files.normal
  if sound_file then
    awful.spawn.easy_async("paplay " .. sound_file, function() end)
  end
end

-- Create notification center widget
M.notification_center = awful.popup({
  ontop = true,
  visible = false,
  shape = function(cr, width, height)
    gears.shape.rounded_rect(cr, width, height, beautiful.border_radius or 8)
  end,
  border_width = beautiful.border_width or 2,
  border_color = beautiful.border_focus or beautiful.bg_focus or "#3c3836",
  preferred_positions = "bottom",
  preferred_anchors = "middle",
  minimum_width = 400,
  maximum_width = 500,
  minimum_height = 100,
  maximum_height = 600,
  offset = { y = 5 },
  widget = {},
})

-- Update notification center content
local function update_notification_center()
  local rows = { layout = wibox.layout.fixed.vertical, spacing = 5 }
  
  -- Header
  local unread_text = M.unread_count > 0 and " (" .. M.unread_count .. " unread)" or ""
  local header = wibox.widget({
    {
      {
        markup = "<b>Notifications</b>" .. unread_text,
        font = (beautiful.font and beautiful.font:match("^[^,]+") or "sans") .. " Bold 14",
        widget = wibox.widget.textbox,
      },
      nil,
      {
        {
          {
            text = "Clear Read",
            align = "center",
            widget = wibox.widget.textbox,
          },
          widget = wibox.container.background,
          bg = beautiful.bg_minimize,
          shape = gears.shape.rounded_rect,
          forced_width = 80,
          forced_height = 25,
          buttons = awful.button({}, 1, function()
            local new_history = {}
            for _, notif in ipairs(M.history) do
              if not notif.is_read then
                table.insert(new_history, notif)
              else
                if M.active_notifications[notif.id] then
                  M.active_notifications[notif.id] = nil
                end
              end
            end
            M.history = new_history
            awesome.emit_signal("notification::unread_count", M.unread_count)
            update_notification_center()
          end),
        },
        {
          {
            text = "Clear All",
            align = "center",
            widget = wibox.widget.textbox,
          },
          widget = wibox.container.background,
          bg = beautiful.bg_urgent,
          fg = beautiful.fg_urgent,
          shape = gears.shape.rounded_rect,
          forced_width = 80,
          forced_height = 25,
          buttons = awful.button({}, 1, function()
            M.history = {}
            M.unread_count = 0
            M.active_notifications = {}
            awesome.emit_signal("notification::unread_count", M.unread_count)
            update_notification_center()
          end),
        },
        layout = wibox.layout.fixed.horizontal,
        spacing = 5,
      },
      layout = wibox.layout.align.horizontal,
    },
    widget = wibox.container.margin,
    margins = 10,
  })
  
  table.insert(rows, header)
  table.insert(rows, wibox.widget({
    widget = wibox.widget.separator,
    orientation = "horizontal",
    thickness = 1,
    color = beautiful.border_color,
  }))
  
  -- Notification items  
  if #M.history == 0 then
    table.insert(rows, wibox.container.margin(wibox.widget({
      text = "No notifications",
      align = "center",
      widget = wibox.widget.textbox,
    }), 10, 10, 50, 50))
  else
    local notification_list = { layout = wibox.layout.fixed.vertical, spacing = 5 }
    
    for i, notif in ipairs(M.history) do
      if i > 20 then break end -- Limit displayed items
      
      local time_str = os.date("%H:%M", notif.timestamp)
      local time_diff = os.time() - notif.timestamp
      local time_ago = ""
      if time_diff < 60 then
        time_ago = "now"
      elseif time_diff < 3600 then
        time_ago = math.floor(time_diff / 60) .. "m ago"
      elseif time_diff < 86400 then
        time_ago = math.floor(time_diff / 3600) .. "h ago"
      else
        time_ago = os.date("%b %d", notif.timestamp)
      end
      
      local item_bg = notif.is_read and beautiful.bg_minimize or beautiful.bg_normal
      if notif.urgency == "critical" and not notif.is_read then
        item_bg = beautiful.bg_urgent
      end
      
      local item = wibox.widget({
        {
          {
            {
              {
                markup = (notif.is_read and "" or "● ") .. "<b>" .. (notif.title or "Notification") .. "</b>",
                widget = wibox.widget.textbox,
                forced_width = 300,
              },
              nil,
              {
                {
                  text = time_ago,
                  opacity = 0.6,
                  font = (beautiful.font and beautiful.font:match("^[^,]+") or "sans") .. " 9",
                  widget = wibox.widget.textbox,
                },
                {
                  {
                    text = "×",
                    align = "center",
                    font = (beautiful.font and beautiful.font:match("^[^,]+") or "sans") .. " Bold 12",
                    widget = wibox.widget.textbox,
                  },
                  widget = wibox.container.background,
                  bg = beautiful.bg_minimize,
                  shape = gears.shape.circle,
                  forced_width = 20,
                  forced_height = 20,
                  buttons = awful.button({}, 1, function()
                    -- Remove this notification
                    for idx, h in ipairs(M.history) do
                      if h.id == notif.id then
                        table.remove(M.history, idx)
                        if not h.is_read then
                          M.unread_count = math.max(0, M.unread_count - 1)
                          awesome.emit_signal("notification::unread_count", M.unread_count)
                        end
                        if M.active_notifications[h.id] then
                          M.active_notifications[h.id] = nil
                        end
                        break
                      end
                    end
                    update_notification_center()
                  end),
                },
                layout = wibox.layout.fixed.horizontal,
                spacing = 8,
              },
              layout = wibox.layout.align.horizontal,
            },
            {
              {
                text = notif.app_name or "",
                opacity = 0.5,
                font = (beautiful.font and beautiful.font:match("^[^,]+") or "sans") .. " 9",
                widget = wibox.widget.textbox,
              },
              {
                text = notif.message or "",
                widget = wibox.widget.textbox,
                wrap = "word",
                forced_width = 450,
              },
              layout = wibox.layout.fixed.vertical,
              spacing = 2,
            },
            layout = wibox.layout.fixed.vertical,
            spacing = 4,
          },
          widget = wibox.container.margin,
          margins = 10,
        },
        widget = wibox.container.background,
        bg = item_bg,
        shape = gears.shape.rounded_rect,
        buttons = awful.button({}, 1, function()
          -- Mark as read on click
          if not notif.is_read then
            notif.is_read = true
            M.unread_count = math.max(0, M.unread_count - 1)
            awesome.emit_signal("notification::unread_count", M.unread_count)
            update_notification_center()
          end
        end),
      })
      
      table.insert(notification_list, item)
    end
    
    -- Wrap in scrollable container
    local scrollable = wibox.widget({
      notification_list,
      forced_height = math.min(400, #M.history * 85),
      widget = wibox.container.constraint,
    })
    
    table.insert(rows, wibox.container.margin(scrollable, 5, 5, 5, 5))
  end
  
  -- Scrollable container
  M.notification_center:setup({
    rows,
    layout = wibox.layout.fixed.vertical,
  })
end

-- Toggle notification center visibility
function M.toggle_notification_center(widget_geometry)
  update_notification_center()
  
  if M.notification_center.visible then
    M.notification_center.visible = false
  else
    -- Position below the clock widget if geometry provided, otherwise use mouse position
    if widget_geometry then
      M.notification_center:move_next_to(widget_geometry)
    else
      -- Fallback to center of screen
      local s = awful.screen.focused()
      M.notification_center.x = s.geometry.x + (s.geometry.width - M.notification_center.width) / 2
      M.notification_center.y = s.geometry.y + (beautiful.wibar_height or 30) + 5
    end
    M.notification_center.visible = true
  end
end

-- Setup notification rules
ruled.notification.connect_signal("request::rules", function()
  -- Default rule for all notifications
  ruled.notification.append_rule({
    rule = {},
    properties = {
      screen = awful.screen.preferred,
      implicit_timeout = M.config.default_timeout,
      position = M.config.positions.top_right,
    },
  })
  
  -- Critical notifications
  ruled.notification.append_rule({
    rule = { urgency = "critical" },
    properties = {
      bg = beautiful.bg_urgent or "#ff0000",
      fg = beautiful.fg_urgent or "#ffffff",
      timeout = 0, -- Never timeout
      border_color = "#ff0000",
      position = M.config.positions.top_middle,
    },
    callback = function(n)
      play_sound("critical")
    end,
  })
  
  -- Low priority notifications
  ruled.notification.append_rule({
    rule = { urgency = "low" },
    properties = {
      bg = beautiful.bg_minimize or beautiful.bg_normal,
      fg = beautiful.fg_minimize or beautiful.fg_normal,
      timeout = 3,
      opacity = 0.8,
    },
  })
  
  -- Browser notifications
  ruled.notification.append_rule({
    rule_any = { 
      app_name = { "Firefox", "Chrome", "Chromium", "Brave" },
    },
    properties = {
      position = M.config.positions.bottom_right,
    },
    callback = function(n)
      -- Check if it's from wife/special contact
      if is_special_contact(n, "wife") then
        n.bg = "#ff69b4" -- Pink background for wife's messages
        n.fg = "#000000"
        n.urgency = "critical"
        n.timeout = 0 -- Don't auto-dismiss
        
        -- Add quick reply action
        n:append_actions(naughty.action({
          name = "Reply",
          icon = beautiful.awesome_icon,
        }))
      end
    end,
  })
  
  -- Discord/Slack notifications
  ruled.notification.append_rule({
    rule_any = {
      app_name = { "discord", "Discord", "slack", "Slack" },
    },
    properties = {
      position = M.config.positions.top_left,
      timeout = 10,
    },
    callback = function(n)
      -- Add actions for messaging apps
      n:append_actions(naughty.action({
        name = "Open",
      }))
      n:append_actions(naughty.action({
        name = "Mark Read",
      }))
    end,
  })
  
  -- Email notifications
  ruled.notification.append_rule({
    rule_any = {
      app_name = { "Thunderbird", "Evolution", "Geary" },
      category = { "email", "email.arrived" },
    },
    properties = {
      position = M.config.positions.bottom_left,
      timeout = 8,
    },
    callback = function(n)
      n:append_actions(naughty.action({
        name = "Read",
      }))
      n:append_actions(naughty.action({
        name = "Archive",
      }))
    end,
  })
  
  -- Media player notifications
  ruled.notification.append_rule({
    rule_any = {
      app_name = { "Spotify", "spotify", "vlc", "mpv" },
      category = { "media", "music" },
    },
    properties = {
      position = M.config.positions.bottom_middle,
      timeout = 4,
    },
  })
  
  -- System notifications
  ruled.notification.append_rule({
    rule_any = {
      category = { "device", "device.added", "device.removed" },
    },
    properties = {
      position = M.config.positions.top_middle,
      timeout = 5,
    },
  })
  
  -- Battery notifications
  ruled.notification.append_rule({
    rule_any = {
      category = { "battery", "power" },
    },
    properties = {
      urgency = "critical",
      position = M.config.positions.top_middle,
      bg = "#ffa500",
      fg = "#000000",
    },
  })
end)

-- Handle notification display
naughty.connect_signal("request::display", function(n)
  -- Set resident for important notifications
  if n.urgency == "critical" or n.app_name == "System" then
    n.resident = true
  end
  
  -- Add to history
  add_to_history(n)
  
  -- Emit signal for unread count change
  awesome.emit_signal("notification::unread_count", M.unread_count)
  
  -- Check DND mode
  if M.config.dnd_mode and n.urgency ~= "critical" then
    return -- Don't display non-critical notifications in DND mode
  end
  
  -- Check focus mode
  if M.config.focus_mode then
    local c = client.focus
    if c and c.fullscreen and n.urgency ~= "critical" then
      return -- Don't show notifications over fullscreen apps
    end
  end
  
  -- Play sound
  play_sound(n.urgency or "normal")
  
  -- Create custom notification layout with actions
  if n.actions and #n.actions > 0 then
    -- Create action buttons
    local actions = wibox.widget({
      notification = n,
      widget = naughty.list.actions,
    })
    
    -- Custom widget template with actions
    n.widget_template = {
      {
        {
          {
            {
              {
                naughty.widget.icon,
                forced_width = 48,
                forced_height = 48,
                widget = wibox.container.constraint,
              },
              margins = 5,
              widget = wibox.container.margin,
            },
            {
              {
                naughty.widget.title,
                font = (beautiful.font and beautiful.font:match("^[^,]+") or "sans") .. " Bold 11",
                widget = wibox.container.scroll.horizontal,
                step_function = wibox.container.scroll.step_functions.waiting_nonlinear_back_and_forth,
                speed = 50,
              },
              {
                naughty.widget.message,
                widget = wibox.container.scroll.horizontal,
                step_function = wibox.container.scroll.step_functions.waiting_nonlinear_back_and_forth,
                speed = 50,
              },
              layout = wibox.layout.fixed.vertical,
            },
            layout = wibox.layout.fixed.horizontal,
          },
          actions,
          layout = wibox.layout.fixed.vertical,
        },
        margins = 10,
        widget = wibox.container.margin,
      },
      widget = wibox.container.background,
      shape = gears.shape.rounded_rect,
      bg = n.bg or beautiful.bg_normal,
      fg = n.fg or beautiful.fg_normal,
      border_width = beautiful.notification_border_width or 2,
      border_color = n.border_color or beautiful.border_normal,
    }
  end
  
  -- Display the notification
  naughty.layout.box({ notification = n })
end)

-- Handle action invocation
naughty.connect_signal("destroyed", function(n, reason)
  if reason == naughty.notification_closed_reason.dismissed_by_user then
    -- User dismissed the notification
  end
end)

-- Toggle functions
function M.toggle_dnd_mode()
  M.config.dnd_mode = not M.config.dnd_mode
  naughty.notify({
    title = "DND Mode",
    text = M.config.dnd_mode and "Enabled" or "Disabled",
    timeout = 2,
  })
end

function M.toggle_focus_mode()
  M.config.focus_mode = not M.config.focus_mode
  naughty.notify({
    title = "Focus Mode",
    text = M.config.focus_mode and "Enabled" or "Disabled",
    timeout = 2,
  })
end

-- Test notification function
function M.test_notification(urgency, app_name)
  naughty.notification({
    title = "Test Notification",
    message = "This is a test notification with urgency: " .. (urgency or "normal"),
    urgency = urgency or "normal",
    app_name = app_name or "Test App",
    actions = {
      naughty.action({ name = "Accept" }),
      naughty.action({ name = "Decline" }),
    },
  })
end

-- Function to generate sample notifications for testing
function M.generate_sample_notifications()
  local samples = {
    { title = "System Update", message = "3 packages can be upgraded", app_name = "System", urgency = "normal" },
    { title = "Low Battery", message = "Battery at 15%", app_name = "Power Manager", urgency = "critical" },
    { title = "New Message", message = "You have a new message from John", app_name = "Discord", urgency = "normal" },
    { title = "Download Complete", message = "awesome-wm-config.tar.gz", app_name = "Firefox", urgency = "low" },
    { title = "Calendar Reminder", message = "Meeting in 15 minutes", app_name = "Calendar", urgency = "normal" },
  }
  
  for i, sample in ipairs(samples) do
    gears.timer.start_new(i * 0.5, function()
      naughty.notification(sample)
      return false
    end)
  end
end

-- Export old function for compatibility
M.toggle_notif_list = M.toggle_notification_center

return M