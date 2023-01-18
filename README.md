###### Table of Contents
* Section 0 - Default Config
* Section 1 - Theme Variables
* Section 2 - Keybindings
* Section 3 - Wibar
* Section 4 - Notifications
* Section 5 - Titlebars
* Section 6 - Logout Screen
* ??



## Keybindings

### I'm going to come out of the gates speaking nonsense.
* I hate the format of the awesomewm keybindings.
* The bindings themselves are fine, it's just the readability of the code that I find hard to reason about. HOW AM I SUPPOSED TO SEARCH FOR awful.key({modkey      },         "u"...??!! Am I really going to bust out a regex to filter out the whitespace, extraneous brackets and commas??? To me, it makes sense to sort keybindings alphabetically so I know for sure I am not duplicating existing bindings. I want to remove large functions from the actual key declarations so I can see exactly what each binding does at a glance. If you write a little function that turns an array into a key declaration, you can prioritize readability
##### This:
```
    awful.key({ modkey,           }, "s",      hotkeys_popup.show_help,
              {description="show help", group="awesome"}),
    awful.key({ modkey,           }, "w", function () mymainmenu:show() end,
              {description = "show main menu", group = "awesome"}),
    awful.key({ modkey, "Control" }, "r", awesome.restart,
              {description = "reload awesome", group = "awesome"}),
    awful.key({ modkey }, "x",
              function ()
                  awful.prompt.run {
                    prompt       = "Run Lua code: ",
                    textbox      = awful.screen.focused().mypromptbox.widget,
                    exe_callback = awful.util.eval,
                    history_path = awful.util.get_cache_dir() .. "/history_eval"
                  }
              end,
              {description = "lua execute prompt", group = "awesome"}),
    awful.key({ modkey,           }, "Return", function () awful.spawn(terminal) end,
              {description = "open a terminal", group = "launcher"}),
    awful.key({ modkey },            "r",     function () awful.screen.focused().mypromptbox:run() end,
              {description = "run prompt", group = "launcher"}),
    awful.key({ modkey,           }, "u", awful.client.urgent.jumpto,
              {description = "jump to urgent client", group = "client"}),
    awful.key({ modkey,           }, "Left",   awful.tag.viewprev,
              {description = "view previous", group = "tag"}),
    awful.key({ modkey,           }, "Right",  awful.tag.viewnext,
              {description = "view next", group = "tag"}),
    awful.key({ modkey,           }, "Escape", awful.tag.history.restore,
              {description = "go back", group = "tag"}),
    awful.key({ modkey,           }, "Tab",
        function ()
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end,
        {description = "go back", group = "client"}),
    awful.key({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster( 1, nil, true) end,
              {description = "increase the number of master clients", group = "layout"}),
    awful.key({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster(-1, nil, true) end,
    awful.key({ modkey,           }, "space", function () awful.layout.inc( 1)                end,
              {description = "select next", group = "layout"}),
```
##### Would be way more readable if it looked like this:
```
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
  ```
* It's certainly a tradeoff since you need to write a wrapper function and if you really want to commit to single lining the key declarations themselves, you'll need to abstract out some of the multi-line functions (or functions that require arguments).  But in my opinion, it's HIGHLY worth the tradeoff for readability.

Let's write a little lua function that will turn a table into an awful.keybinding
```
  local function table_to_keybinding(bindings)
    local key_bindings = {}
    for _, g_key in ipairs(bindings) do
      table.insert(key_bindings, awful.key(g_key[1], g_key[2], g_key[3], { description = g_key[4], group = g_key[5] }))
    end
    return key_bindings
  end
```

* All this does is take a table of our keybinding tables and inserts them as `awful.key()` calls.
* I think later we can make this even simpler by using the other keybinding declaration style, but for now, this makes a world of difference.

### Let's start reformatting
* First, move all those keybindings over to a new file named `keybindings.lua`
* We're going to leave the GLOBAL mousebindings in the rc.lua file for now.  We'll come back to those later, but for now, leave them there they are. (That'll let us right click the wallpaper and get the mainmenu and some tag switching with a scroll wheel.)
* Where the rest of the keybindings used to be, `require("keybindings")`
* Now in the new keybindings.lua file you can copy the ones I just did, or I recommend you get familiar with writing macros in your editor (or pop on a show you like and get to transforming those bindings the long way)
* I'm pretty meticulous about sorting them alphabetically and grouping them by the modifiers they'll use.  That way at a glance, I can recognize every binding I have set.
* If a keybinding is a single line, I'll put it on a single line.  If it's a multi-line function, I'll extract the function to a `helper` table that refers to the hotkey group  (tag functions go in a tag_helper, media functions go in a media_helper).  Some people will think this is overkill.  Glanceability is my #1 priority with keybindings.  I can look at how the function is implemented if I need to, but I want to see them all on one line each.
* In a future refactor, we'll probably extract those helpers to their own files to keep the keybinding declarations a little less visually cluttered.

### Media Keys
* I need all my normal volume/brightness keys working properly.  I use [pamixer](https://github.com/cdemoulins/pamixer), [playerctl](https://github.com/altdesktop/playerctl) and [brightnessctl](https://github.com/Hummer12007/brightnessctl).  So I can just map a key to an `awful.spawn` call and execute the cli commands directly.  If you prefer a different CLI tool, just use your tool directly instead of mine.
```
  {{},         "XF86AudioLowerVolume",  function() awful.spawn("pamixer -d 3") end,               "decrease volume",                       "media"    },
  {{},         "XF86AudioRaiseVolume",  function() awful.spawn("pamixer -i 3") end,               "increase volume",                       "media"    },
  {{},         "XF86MonBrightnessDown", function() awful.spawn("brightnessctl s +5%") end,        "decrease brightness",                   "media"    },
  {{},         "XF86MonBrightnessUp",   function() awful.spawn("brighnessctl s 5%-") end,         "increase brightness",                   "media"    },
  {{},         "XF86AudioMute",         function() awful.spawn("pamixer -t") end,                 "mute volume",                           "media"    },
  {{},         "XF86AudioNext",         function() awful.spawn("playerctl next") end,             "next track",                            "media"    },
  {{},         "XF86AudioPlay",         function() awful.spawn("playerctl play-pause") end,       "play/pause track",                      "media"    },
  {{},         "XF86AudioPrev",         function() awful.spawn("playerctl previous") end,         "previous track",                        "media"    },
```
* I'm a pretty normal guy.  I do one weird thing.  I increase and decrease my volume by 3%...

### Update default applications 
* While we're in here updating keybinding functionality, I want to just update the default applications & these couple global variables to be the tools I like to work with.
* Awesome has some global variables set to basic applications and keyboard keys.
  Set them to your preferred applications and keyboard keys.
  I use wezterm and nvim.
  NOTE: The reason the editor_cmd works in the default settings is because the `-e` flag is supported by the `xterm` terminal.  
  (from the xterm man page)
```
-e program [ arguments ... ]
               This option specifies the program (and its command line
               arguments) to be run in the xterm window.  It also sets the
               window title and icon name to be the basename of the program
               being executed if neither -T nor -n are given on the command
               line.

               NOTE: This must be the last option on the command line.
```
* Wezterm does NOT support this flag, so I need to set the `editor_cmd` to something that opens wezterm AND launches neovim. `wezterm start -- nvim`
  If you use a different terminal or a GUI, just make sure you set your `editor_cmd` to a string that will open the rc.lua file the way you like.
  Now when you click "edit config" in the launcher menu, your config will open in your preferred editor
```
terminal = "wezterm"
editor = os.getenv("EDITOR") or "nvim"
editor_cmd = "wezterm start -- " .. editor
filemanager = "thunar" --While I'm in here, may as well make this a variable
```

### Cleanup
* I know this doesn't fit here, but I HATE sloppy mouse focus.  I accidentally bump the mouse while I'm typing and there goes the text...
* The final lines in the rc.lua file have to go.
```
-- Enable sloppy focus, so that focus follows mouse.
client.connect_signal("mouse::enter", function(c)
  c:activate({ context = "mouse_enter", raise = false })
end)
```
