local awful = require("awful")
local hotkeys_popup = require("awful.hotkeys_popup")
-- Enable hotkeys help widget for VIM and other apps
-- when client with a matching name is opened:
require("awful.hotkeys_popup.keys")
local menubar = require("menubar")

local function table_to_keybinding(bindings)
  local key_bindings = {}
  for _, g_key in ipairs(bindings) do
    table.insert(key_bindings, awful.key(g_key[1], g_key[2], g_key[3], { description = g_key[4], group = g_key[5] }))
  end
  return key_bindings
end

local global_helpers = {
  launch_lua_prompt = function()
    awful.prompt.run {
      prompt       = "Run Lua code: ",
      textbox      = awful.screen.focused().mypromptbox.widget,
      exe_callback = awful.util.eval,
      history_path = awful.util.get_cache_dir() .. "/history_eval"
    }
  end,
  client_go_back = function()
    awful.client.focus.history.previous()
    if client.focus then
      client.focus:raise()
    end
  end,
  client_restore_minimized = function()
    local c = awful.client.restore()
    -- Focus restored client
    if c then
      c:activate { raise = true, context = "key.unminimize" }
    end
  end
}

local client_helpers = {
  toggle_fullscreen = function(c)
    c.fullscreen = not c.fullscreen
    c:raise()
  end,
  minimize = function(c)
    -- The client currently has the input focus, so it cannot be
    -- minimized, since minimized clients can't have the focus.
    c.minimized = true
  end,
  toggle_maximized = function(c)
    c.maximized = not c.maximized
    c:raise()
  end,
  toggle_maximized_vert = function(c)
    c.maximized_vertical = not c.maximized_vertical
    c:raise()
  end,
  toggle_maximized_horiz = function(c)
    c.maximized_horizontal = not c.maximized_horizontal
    c:raise()
  end,
}

--{modifier(s) table, key string,          function function,                     description string,    group string}
local global_keys = {
  -- no modifiers
  {{},         "XF86AudioLowerVolume",  function() awful.spawn("pamixer -d 3") end,               "decrease volume",                       "media"    },
  {{},         "XF86AudioRaiseVolume",  function() awful.spawn("pamixer -i 3") end,               "increase volume",                       "media"    },
  {{},         "XF86MonBrightnessDown", function() awful.spawn("brightnessctl s +5%") end,        "decrease brightness",                   "media"    },
  {{},         "XF86MonBrightnessUp",   function() awful.spawn("brighnessctl s 5%-") end,         "increase brightness",                   "media"    },
  {{},         "XF86AudioMute",         function() awful.spawn("pamixer -t") end,                 "mute volume",                           "media"    },
  {{},         "XF86AudioNext",         function() awful.spawn("playerctl next") end,             "next track",                            "media"    },
  {{},         "XF86AudioPlay",         function() awful.spawn("playerctl play-pause") end,       "play/pause track",                      "media"    },
  {{},         "XF86AudioPrev",         function() awful.spawn("playerctl previous") end,         "previous track",                        "media"    },
  -- modkey only modifier
  {{ modkey }, "f",                     function () awful.spawn(filemanager) end,                 "open file browser",                     "launcher" },
  {{ modkey }, "h",                     function () awful.tag.incmwfact(-0.05) end,               "decrease master width factor",          "layout"   },
  {{ modkey }, "j",                     function () awful.client.focus.byidx( 1) end,             "focus next by index",                   "client"   },
  {{ modkey }, "k",                     function () awful.client.focus.byidx(-1) end,             "focus previous by index",               "client"   },
  {{ modkey }, "l",                     function () awful.tag.incmwfact( 0.05) end,               "increase master width factor",          "layout"   },
  {{ modkey }, "p",                     function() menubar.show() end,                            "show the menubar",                      "launcher" },
  {{ modkey }, "r",                     function () awful.screen.focused().mypromptbox:run() end, "run prompt",                            "launcher" },
  {{ modkey }, "s",                     hotkeys_popup.show_help,                                  "show help",                             "awesome"  },
  {{ modkey }, "u",                     awful.client.urgent.jumpto,                               "jump to urgent client",                 "client"   },
  {{ modkey }, "w",                     function () mymainmenu:show() end,                        "show main menu",                        "awesome"  },
  {{ modkey }, "x",                     global_helpers.launch_lua_prompt,                         "lua execute prompt",                    "awesome"  },
  {{ modkey }, "Escape",                awful.tag.history.restore,                                "go back",                               "tag"      },
  {{ modkey }, "Left",                  awful.tag.viewprev,                                       "view previous",                         "tag"      },
  {{ modkey }, "Return",                function () awful.spawn(terminal) end,                    "open a terminal",                       "launcher" },
  {{ modkey }, "Right",                 awful.tag.viewnext,                                       "view next",                             "tag"      },
  {{ modkey }, "Tab",                   global_helpers.client_go_back,                            "go back",                               "client"   },
  {{ modkey }, "space",                 function () awful.layout.inc( 1)       end,               "select next",                           "layout"   },
  -- modkey + ctrl modifier
  {{ modkey, "Control" }, "h",          function () awful.tag.incncol( 1, nil, true) end,         "increase the number of columns",        "layout"   },
  {{ modkey, "Control" }, "j",          function () awful.screen.focus_relative( 1) end,          "focus the next screen",                 "screen"   },
  {{ modkey, "Control" }, "k",          function () awful.screen.focus_relative(-1) end,          "focus the previous screen",             "screen"   },
  {{ modkey, "Control" }, "l",          function () awful.tag.incncol(-1, nil, true) end,         "decrease the number of columns",        "layout"   },
  {{ modkey, "Control" }, "n",          global_helpers.client_restore_minimized,                  "restore minimized",                     "client"   },
  {{ modkey, "Control" }, "p",          function() awful.spawn("flameshot gui") end,              "take screenshot",                       "client"   },
  {{ modkey, "Control" }, "r",          awesome.restart,                                          "reload awesome",                        "awesome"  },
  -- modkey + shift modifier
  {{ modkey, "Shift"   }, "h",          function () awful.tag.incnmaster( 1, nil, true) end,      "increase the number of master clients", "layout"   },
  {{ modkey, "Shift"   }, "j",          function () awful.client.swap.byidx(  1) end,             "swap with next client by index",        "client"   },
  {{ modkey, "Shift"   }, "k",          function () awful.client.swap.byidx( -1) end,             "swap with previous client by index",    "client"   },
  {{ modkey, "Shift"   }, "l",          function () awful.tag.incnmaster(-1, nil, true) end,      "decrease the number of master clients", "layout"   },
  {{ modkey, "Shift"   }, "q",          awesome.quit,                                             "quit awesome",                          "awesome"  },
  {{ modkey, "Shift"   }, "space",      function () awful.layout.inc(-1) end,                     "select previous",                       "layout"   },
}

local client_keys = {
  -- modkey only modifier
  {{ modkey },            "f",      client_helpers.toggle_fullscreen,                  "toggle fullscreen",         "client" },
  {{ modkey },            "m",      client_helpers.toggle_maximized,                   "(un)maximize",              "client" },
  {{ modkey },            "n",      client_helpers.minimize,                           "minimize",                  "client" },
  {{ modkey },            "o",      function (c) c:move_to_screen() end,               "move to screen",            "client" },
  {{ modkey },            "q",      function (c) c:kill() end,                         "close",                     "client" },
  {{ modkey },            "t",      function (c) c.ontop = not c.ontop end,            "toggle keep on top",        "client" },
  --modkey ctrl modifier
  {{ modkey, "Control" }, "m",      client_helpers.toggle_maximized_vert,              "(un)maximize vertically",   "client" },
  {{ modkey, "Control" }, "space",  awful.client.floating.toggle,                      "toggle floating",           "client" },
  {{ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end, "move to master",            "client" },
  --modkey shift modifier
  {{ modkey, "Shift"   }, "c",      function (c) c:kill() end,                         "close",                     "client" },
  {{ modkey, "Shift"   }, "m",      client_helpers.toggle_maximized_horiz,             "(un)maximize horizontally", "client" },
}


client.connect_signal("request::default_keybindings", function()
    awful.keyboard.append_client_keybindings(table_to_keybinding(client_keys))
end)
awful.keyboard.append_global_keybindings(table_to_keybinding(global_keys))

-- INFO: Leave these ones as they are.
-- They use the declarative pattern instead of the ones above that use the more basic pattern.
-- Maybe one day...
awful.keyboard.append_global_keybindings({
    awful.key {
        modifiers   = { modkey },
        keygroup    = "numrow",
        description = "only view tag",
        group       = "tag",
        on_press    = function (index)
            local screen = awful.screen.focused()
            local tag = screen.tags[index]
            if tag then
                tag:view_only()
            end
        end,
    },
    awful.key {
        modifiers   = { modkey, "Control" },
        keygroup    = "numrow",
        description = "toggle tag",
        group       = "tag",
        on_press    = function (index)
            local screen = awful.screen.focused()
            local tag = screen.tags[index]
            if tag then
                awful.tag.viewtoggle(tag)
            end
        end,
    },
    awful.key {
        modifiers = { modkey, "Shift" },
        keygroup    = "numrow",
        description = "move focused client to tag",
        group       = "tag",
        on_press    = function (index)
            if client.focus then
                local tag = client.focus.screen.tags[index]
                if tag then
                    client.focus:move_to_tag(tag)
                end
            end
        end,
    },
    awful.key {
        modifiers   = { modkey, "Control", "Shift" },
        keygroup    = "numrow",
        description = "toggle focused client on tag",
        group       = "tag",
        on_press    = function (index)
            if client.focus then
                local tag = client.focus.screen.tags[index]
                if tag then
                    client.focus:toggle_tag(tag)
                end
            end
        end,
    },
    awful.key {
        modifiers   = { modkey },
        keygroup    = "numpad",
        description = "select layout directly",
        group       = "layout",
        on_press    = function (index)
            local t = awful.screen.focused().selected_tag
            if t then
                t.layout = t.layouts[index] or t.layout
            end
        end,
    }
})

-- @DOC_CLIENT_BUTTONS@
client.connect_signal("request::default_mousebindings", function()
    awful.mouse.append_client_mousebindings({
        awful.button({ }, 1, function (c)
            c:activate { context = "mouse_click" }
        end),
        awful.button({ modkey }, 1, function (c)
            c:activate { context = "mouse_click", action = "mouse_move"  }
        end),
        awful.button({ modkey }, 3, function (c)
            c:activate { context = "mouse_click", action = "mouse_resize"}
        end),
    })
end)
