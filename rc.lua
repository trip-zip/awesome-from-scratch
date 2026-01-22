-- awesome_mode: api-level=4:screen=on

-- Add config directory to Lua search path for somewm compatibility
local config_dir = (os.getenv("XDG_CONFIG_HOME") or os.getenv("HOME") .. "/.config") .. "/somewm"
package.path = config_dir .. "/?.lua;" .. config_dir .. "/?/init.lua;" .. package.path

-- If LuaRocks is installed, make sure that packages installed through it are
-- found (e.g. lgi). If LuaRocks is not installed, do nothing.
pcall(require, "luarocks.loader")

-- @DOC_REQUIRE_SECTION@
-- Standard awesome library
local awful = require("awful")
require("awful.autofocus")
-- Widget and layout library
local wibox = require("wibox")
-- Theme handling library
local beautiful = require("beautiful")
-- Notification library
local naughty = require("naughty")
-- Declarative object management
local ruled = require("ruled")
local menubar = require("menubar")
require("awful.hotkeys_popup.keys")
local gears = require("gears")


naughty.connect_signal("request::display_error", function(message, startup)
  naughty.notification({
    urgency = "critical",
    title = "Oops, an error happened" .. (startup and " during startup!" or "!"),
    message = message,
  })
end)

-- {{{ Variable definitions
-- @DOC_LOAD_THEME@
-- Themes define colours, icons, font and wallpapers.
local config_dir = (os.getenv("XDG_CONFIG_HOME") or os.getenv("HOME") .. "/.config") .. "/somewm"
local theme_path = config_dir .. "/theme/"
beautiful.init(theme_path .. "theme.lua")

-- Load notification system (after theme init, before any notifications can fire)
local notifications_ok, notifications_err = pcall(require, "notifications")
if not notifications_ok then
  io.stderr:write("[RC.LUA] Failed to load notifications: " .. tostring(notifications_err) .. "\n")
else
  io.stderr:write("[RC.LUA] Notifications module loaded successfully\n")
end

-- Load and initialize lockscreen module (somewm built-in lock support)
local lockscreen_ok, lockscreen = pcall(require, "lockscreen")
if not lockscreen_ok then
  io.stderr:write("[RC.LUA] Failed to load lockscreen: " .. tostring(lockscreen) .. "\n")
else
  local init_ok, init_err = pcall(lockscreen.init)
  if not init_ok then
    io.stderr:write("[RC.LUA] Failed to init lockscreen: " .. tostring(init_err) .. "\n")
  else
    io.stderr:write("[RC.LUA] Lockscreen initialized successfully\n")
  end
end

-- @DOC_DEFAULT_APPLICATIONS@
-- This is used later as the default terminal and editor to run.
terminal = "ghostty"
editor = os.getenv("EDITOR") or "nvim"
editor_cmd = "ghostty -e " .. editor
filemanager = "thunar" --While I'm in here, may as well make this a variable

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
modkey = "Mod4"
-- }}}

-- {{{ Menu
-- @DOC_MENU@
-- Create a launcher widget and a main menu

local wibar = require("wibar")
local mymainmenu = require("widgets.mainmenu")

-- Menubar configuration
menubar.utils.terminal = terminal -- Set the terminal for applications that require it
-- }}}

-- {{{ Tag layout
-- @DOC_LAYOUT@
-- Table of layouts to cover with awful.layout.inc, order matters.
tag.connect_signal("request::default_layouts", function()
  awful.layout.append_default_layouts({
    awful.layout.suit.tile,
    awful.layout.suit.floating,
    awful.layout.suit.tile.left,
    awful.layout.suit.tile.bottom,
    awful.layout.suit.tile.top,
    awful.layout.suit.fair,
    awful.layout.suit.fair.horizontal,
    awful.layout.suit.spiral,
    awful.layout.suit.spiral.dwindle,
    awful.layout.suit.max,
    awful.layout.suit.max.fullscreen,
    awful.layout.suit.magnifier,
    awful.layout.suit.corner.nw,
  })
end)
-- }}}
--
-- Wallpaper configuration
-- Set your wallpaper paths here, or use a solid color
local wallpaper_path = os.getenv("HOME") .. "/wallpapers/gruvbox"
local wallpapers = {
  wallpaper_path .. "/penguin.jpg",
  wallpaper_path .. "/spaceman.jpg",
}

local function set_wallpaper(s)
  local wp = wallpapers[s.index] or wallpapers[1]
  if wp and gears.filesystem.file_readable(wp) then
    gears.wallpaper.maximized(wp, s, true)
  else
    -- Fallback to gruvbox dark color
    gears.wallpaper.set("#282828")
  end
end

-- {{{ Wallpaper
-- @DOC_WALLPAPER@
screen.connect_signal("request::wallpaper", function(s)
  -- awful.wallpaper({
  --   screen = s,
  --   widget = {
  --     {
  --       image = beautiful.wallpaper,
  --       upscale = true,
  --       downscale = true,
  --       widget = wibox.widget.imagebox,
  --     },
  --     valign = "center",
  --     halign = "center",
  --     tiled = false,
  --     widget = wibox.container.tile,
  --   },
  -- })
  set_wallpaper(s)
end)
-- }}}

-- {{{ Screen scaling
-- Scale up the laptop monitor (screen 1) for better readability
awful.screen.connect_for_each_screen(function(s)
  if s.index == 1 then
    s.scale = 1.5
  end
end)
-- }}}

-- {{{ Wibar

-- Create a textclock widget
mytextclock = wibox.widget.textclock()

-- @DOC_FOR_EACH_SCREEN@
screen.connect_signal("request::desktop_decoration", function(s)
  -- Create a promptbox for each screen
  s.mypromptbox = awful.widget.prompt()

  -- Create an imagebox widget which will contain an icon indicating which layout we're using.
  -- We need one layoutbox per screen.
  s.mylayoutbox = awful.widget.layoutbox({
    screen = s,
    buttons = {
      awful.button({}, 1, function()
        awful.layout.inc(1)
      end),
      awful.button({}, 3, function()
        awful.layout.inc(-1)
      end),
      awful.button({}, 4, function()
        awful.layout.inc(-1)
      end),
      awful.button({}, 5, function()
        awful.layout.inc(1)
      end),
    },
  })

  -- @TASKLIST_BUTTON@
  -- Create a tasklist widget
  s.mytasklist = awful.widget.tasklist({
    screen = s,
    filter = awful.widget.tasklist.filter.currenttags,
    buttons = {
      awful.button({}, 1, function(c)
        c:activate({ context = "tasklist", action = "toggle_minimization" })
      end),
      awful.button({}, 3, function()
        awful.menu.client_list({ theme = { width = 250 } })
      end),
      awful.button({}, 4, function()
        awful.client.focus.byidx(-1)
      end),
      awful.button({}, 5, function()
        awful.client.focus.byidx(1)
      end),
    },
  })
  s.mywibox = wibar(s)
end)

-- {{{ Mouse bindings
-- @DOC_ROOT_BUTTONS@
awful.mouse.append_global_mousebindings({
  awful.button({}, 3, function()
    mymainmenu:toggle()
  end),
  awful.button({}, 4, awful.tag.viewprev),
  awful.button({}, 5, awful.tag.viewnext),
})
-- }}}

require("keybindings")

-- {{{ Rules
-- Rules to apply to new clients.
-- @DOC_RULES@
ruled.client.connect_signal("request::rules", function()
  -- @DOC_GLOBAL_RULE@
  -- All clients will match this rule.
  ruled.client.append_rule({
    id = "global",
    rule = {},
    properties = {
      focus = awful.client.focus.filter,
      raise = true,
      screen = awful.screen.preferred,
      placement = awful.placement.no_overlap + awful.placement.no_offscreen,
      opacity = 0.85,
    },
    callback = function(c)
      c:grant("autoactivate", "switch_tag")
      c:grant("autoactivate", "history")
      c:deny("autoactivate", "mouse_enter")
      c:to_secondary_section()
    end,
  })

  -- @DOC_FLOATING_RULE@
  -- Floating clients.
  ruled.client.append_rule({
    id = "floating",
    rule_any = {
      instance = { "copyq", "pinentry" },
      class = {
        "Arandr",
        "Blueman-manager",
        "Gpick",
        "Kruler",
        "Sxiv",
        "Tor Browser",
        "Wpa_gui",
        "veromix",
        "xtightvncviewer",
      },
      -- Note that the name property shown in xprop might be set slightly after creation of the client
      -- and the name shown there might not match defined rules here.
      name = {
        "Event Tester", -- xev.
      },
      role = {
        "AlarmWindow",   -- Thunderbird's calendar.
        "ConfigManager", -- Thunderbird's about:config.
        "pop-up",        -- e.g. Google Chrome's (detached) Developer Tools.
      },
    },
    properties = { floating = true },
  })

  -- @DOC_DIALOG_RULE@
  -- Add titlebars to normal clients and dialogs
  ruled.client.append_rule({
    -- @DOC_CSD_TITLEBARS@
    id = "titlebars",
    rule_any = { type = { "normal", "dialog" } },
    properties = { titlebars_enabled = true },
  })

  -- Set Firefox to always map on the tag named "2" on screen 1.
  -- ruled.client.append_rule {
  --     rule       = { class = "Firefox"     },
  --     properties = { screen = 1, tag = "2" }
  -- }
end)
-- }}}

-- {{{ Titlebars
-- @DOC_TITLEBARS@
-- Wrap a titlebar button with hover effects
local function with_hover(button, hover_opacity)
  hover_opacity = hover_opacity or 1.0
  local normal_opacity = 0.7
  button.opacity = normal_opacity
  button:connect_signal("mouse::enter", function()
    button.opacity = hover_opacity
  end)
  button:connect_signal("mouse::leave", function()
    button.opacity = normal_opacity
  end)
  return button
end

-- Add a titlebar if titlebars_enabled is set to true in the rules.
client.connect_signal("request::titlebars", function(c)
  -- buttons for the titlebar
  local buttons = {
    awful.button({}, 1, function()
      c:activate({ context = "titlebar", action = "mouse_move" })
    end),
    awful.button({}, 3, function()
      c:activate({ context = "titlebar", action = "mouse_resize" })
    end),
  }

  awful.titlebar(c).widget = {
    { -- Left
      layout = wibox.layout.fixed.horizontal,
      with_hover(awful.titlebar.widget.closebutton(c)),
      with_hover(awful.titlebar.widget.floatingbutton(c)),
      with_hover(awful.titlebar.widget.maximizedbutton(c)),
    },
    { -- Middle
      { -- Title
        halign = "center",
        widget = awful.titlebar.widget.titlewidget(c),
      },
      buttons = buttons,
      layout = wibox.layout.flex.horizontal,
    },
    { -- Right
      layout = wibox.layout.fixed.horizontal(),
    },
    layout = wibox.layout.align.horizontal,
  }
end)
-- }}}

-- Enable sloppy focus, so that focus follows mouse.
-- client.connect_signal("mouse::enter", function(c)
--     c:activate { context = "mouse_enter", raise = false }
-- end)
