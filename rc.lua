-- awesome_mode: api-level=4:screen=on

-- Add this config's own directory to the Lua search path, so that `require("wibar")`
-- and `require("widgets.clock")` resolve to the files sitting next to this rc.lua.
--
-- `get_configuration_dir()` reads `awesome.conffile`, which is the rc.lua the running
-- compositor actually loaded. Both somewm and AwesomeWM implement it identically, so
-- this one line covers ~/.config/somewm, ~/.config/awesome, and a git checkout you
-- pointed a nested compositor at. It always ends in a slash.
local config_dir = require("gears.filesystem").get_configuration_dir()
package.path = config_dir .. "?.lua;" .. config_dir .. "?/init.lua;" .. package.path

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
beautiful.init(config_dir .. "theme/theme.lua")

-- These two modules are the ones most likely to break a config badly enough that you
-- cannot log in. Load them behind pcall and report the failure as a notification, so a
-- typo costs you one missing feature instead of a session.
--
-- Report failures on both channels on purpose. If the module that failed is
-- `notifications`, then nothing ever registered a `request::display` handler and the
-- notification below paints nowhere, so stderr is the only thing you will actually see.
local function try(name, fn)
  local ok, err = pcall(fn)
  if not ok then
    io.stderr:write(("[rc.lua] %s failed to load: %s\n"):format(name, tostring(err)))
    naughty.notification({
      urgency = "critical",
      title = name .. " failed to load",
      message = tostring(err),
    })
  end
  return ok
end

-- Notification system: after theme init, before anything can fire a notification.
try("notifications", function()
  require("notifications")
end)

-- Lockscreen: somewm's built-in session lock support.
try("lockscreen", function()
  require("lockscreen").init()
end)

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

-- The workspaces, defined once. Each tag carries the icon the taglist renders
-- for it (files in icons/); the demo rules further down route apps to tags by
-- these names, so rename in both places or a rule will quietly stop matching.
local tags = {
  { name = "code", icon = "terminal.svg" },
  { name = "web", icon = "chrome.svg" },
  { name = "chat", icon = "slack.svg" },
  { name = "db", icon = "server.svg" },
  { name = "games", icon = "play.svg" },
}
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
-- Wallpaper configuration.
-- One entry per screen, indexed by screen number. These paths are relative to this
-- config so a fresh clone has something to show. Point them anywhere you like.
local wallpapers = {
  config_dir .. "wallpapers/penguin.jpg",
  config_dir .. "theme/spaceman.jpg",
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
-- `screen.scale` is a somewm addition: fractional output scaling, which X11 has no
-- equivalent for. This is a personal tweak for a HiDPI laptop panel. Set it to the
-- screens you actually want scaled, or delete this block entirely.
local screen_scales = {
  -- [1] = 1.5,
}

awful.screen.connect_for_each_screen(function(s)
  local scale = screen_scales[s.index]
  if scale then
    s.scale = scale
  end
end)
-- }}}

-- {{{ Wibar
-- @DOC_FOR_EACH_SCREEN@
screen.connect_signal("request::desktop_decoration", function(s)
  -- Create this screen's tags from the table defined at the top
  for i, t in ipairs(tags) do
    awful.tag.add(t.name, {
      screen = s,
      layout = awful.layout.layouts[1],
      selected = i == 1,
      icon_name = t.icon,
    })
  end

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
    mymainmenu.toggle()
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
      -- Uncomment to fade every window slightly. It looks nice over a wallpaper and it
      -- is confusing the first time a screenshot comes out washed out, so it is off by
      -- default.
      -- opacity = 0.85,
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
        "AlarmWindow", -- Thunderbird's calendar.
        "ConfigManager", -- Thunderbird's about:config.
        "pop-up", -- e.g. Google Chrome's (detached) Developer Tools.
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

  -- ==========================================
  -- DEMO RULES: Showcasing AwesomeWM capabilities
  -- ==========================================

  -- Tag assignment: Browsers always open on "web" tag
  ruled.client.append_rule({
    id = "browsers",
    rule_any = {
      class = { "firefox", "Firefox", "chromium", "Chromium", "Google-chrome" },
    },
    properties = { tag = "web" },
  })

  -- Tag assignment: Chat/communication apps on "chat" tag
  ruled.client.append_rule({
    id = "chat",
    rule_any = {
      class = { "discord", "Discord", "Slack", "TelegramDesktop", "Signal" },
    },
    properties = { tag = "chat" },
  })

  -- Picture-in-Picture: Always floating, ontop, sticky, positioned top-right
  ruled.client.append_rule({
    id = "pip",
    rule_any = {
      name = { "Picture-in-Picture", "Picture in picture" },
    },
    properties = {
      floating = true,
      ontop = true,
      sticky = true,
      skip_taskbar = true,
    },
    callback = function(c)
      -- Position at top-right with margin
      awful.placement.top_right(c, { margins = { top = 50, right = 20 } })
      -- Make it smaller (good for video)
      c:geometry({ width = 480, height = 270 })
    end,
  })

  -- Spotify: Force to "db" tag (closest to media)
  ruled.client.append_rule({
    id = "spotify",
    rule = { class = "Spotify" },
    properties = { tag = "db" },
  })

  -- File manager: Slightly larger default size
  ruled.client.append_rule({
    id = "filemanager",
    rule_any = {
      class = { "Thunar", "Nautilus", "Pcmanfm", "Nemo" },
    },
    callback = function(c)
      c:geometry({ width = 1000, height = 700 })
      awful.placement.centered(c)
    end,
  })

  -- Steam: Handle various Steam windows properly
  ruled.client.append_rule({
    id = "steam",
    rule = { class = "Steam" },
    properties = { tag = "games" },
  })

  -- Steam friends list and chat: floating
  ruled.client.append_rule({
    id = "steam-dialogs",
    rule_any = {
      name = { "Friends List", "Steam - News" },
      class = { "Steam" },
      type = { "dialog" },
    },
    except = { name = "Steam" }, -- Main window excluded
    properties = { floating = true },
  })
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
