###### Table of Contents
* [Section 0 - Default Config](https://github.com/trip-zip/awesome-from-scratch/tree/00-default)
* [Section 1 - Theme](https://github.com/trip-zip/awesome-from-scratch/tree/01-theme)
* [Section 2 - Keybindings](https://github.com/trip-zip/awesome-from-scratch/tree/02-keybindings)
* [Section 3 - Wibar](https://github.com/trip-zip/awesome-from-scratch/tree/03-wibar)
* Section 4 - Notifications
* Section 5 - Titlebars
* Section 6 - Logout Screen
* ??



## Theme

#### Theme
* There are a few built in themes in the default config.  I'm going to stick with the default, though `zenburn` is a good choice too.
* To start altering the theme, I'll copy the theme directory into this project, and I'll start making changes.  You can see the theme directories have lots of image files in them to be used in different widgets and bars.
* Normally, your themes will be installed in `/usr/share/awesome/themes`, but verify that on your setup.
`cp -r /usr/local/share/awesome/themes/default ~/.config/awesome/theme`
* Now that we have the themes in our project, we can reference the new theme directory with a relative path.
  Beautiful is the theme library, so calling beautiful.init() with the theme file will kick off our new theme.
(rc.lua)
```
local theme_path = string.format("%s/.config/awesome/theme/", os.getenv("HOME"))
beautiful.init(theme_path .. "/theme.lua")
```

* We'll also want to make a couple minor updates to that theme.lua file to make sure that the `themes_path` variable is referencing this project instead of that default themes_dir
1. There's not a good reason now to reference the entire themes directory.  This theme only needs to reference itself.
(theme/theme.lua)
```
local theme_path = string.format("%s/.config/awesome/theme", os.getenv("HOME"))
```
2. Then, we'll want to search and replace the rest of those references to `themes_path` and make them `theme_path`
3. Finally, there are a ton of hardcoded strings referencing the "default" theme.  No good.  Let's search and replace all of those to be empty strings instead.

* Now when we make changes to the `theme/theme.lua` file, they'll take effect whenever we restart awesome.

#### Let's get EVERY theme variable into our theme.lua file to have an easy place to reference them.
* [The docs](https://awesomewm.org/apidoc/documentation/06-appearance.md.html) have a reference to the theme.lua file with a commented out list of all theme vars at the bottom.
* Let's copy that list into our theme.lua file and make sure we don't have any conflicts with the default config.  This will give us a nice reference to all the theme vars we can change.

##### Let's make a couple style changes to make sure it's working
* I like a small gap around my clients.
  `theme.useless_gap = dpi(5)`
* The default wallpaper is cute, but too black for my taste.  You can move wallpapers to the theme directory, or reference your wallpapers directory on your system.  
  `theme.wallpaper = theme_path .. /spaceman.jpg`
* Font can kill a couple birds with 1 stone.  We can get a larger wibar AND titlebars just by increasing font size.  I like JetBrainsMono well enough
  `theme.font = "JetBrainsMono Nerd Font, 12"`

#### First, let's tackle some colors.
* I sometimes like to switch between a couple colorschemes, so I'll make a simple "colors" table with basic gruvbox colors and basic nord colors.
* I'll keep it simple for now, but we'll expand on that in the future with better semantic naming, and using them for more than just these few options.
* Pick colors that make sense for you, or set them to nil if you don't want something like border colors on your clients

#### Titlebar tweaks
* First, everything is kind of tiny on my huge monitor.  Increase your font size to automatically increase the height of the titlebars (and the wibar as well)
  * I admit, I like the default theme fine, but I NEVER use most of the buttons on the titlebar.  Let's just remove the ones I don't use.
  * I don't like the `maximize` (and consequently `minimize`), `sticky`, or `ontop` buttons.  I will add some keybindings to handle those if I need, but I can probably get by with just the `floating` and the `close` buttons.  Let's just set the titlebar_button images to `nil`.  Technically you could remove the delete the theme options completely OR just comment them out.  I will set them to nil so it's clear what's happening under the hood, not just relying on silent defaults.
  * I'll try to find some buttons that are a little more like what I'm looking for.
  * Simple colored squares are probably fine for now.
  * We can use the built in `gears.color.recolor_image` on the titlebar buttons, the layout images up on the wibar, and the submenu dropdown.
* I really don't like the client icons in the top left.  I know what client I'm working on based on position or context.
  * Let's head to the rc.lua file again and jump to where titlebars are defined & just comment out the iconwidget line
  ```
    -- {{{ Titlebars
    -- @DOC_TITLEBARS@
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
          -- awful.titlebar.widget.iconwidget(c), <---------------------------This line
          buttons = buttons,
          layout = wibox.layout.fixed.horizontal,
        },
        { -- Middle
          { -- Title
            halign = "center",
  ```
#### Wibar tweaks
  * Let's start left to right.
  * I'll leave the awesome icon launcher on the far left for now.
  * Taglist can use a little work
    * I appreciate the indication that a tag has clients in it, but I think I would rather just color the numbered text instead
    * Let's remove the `taglist_squares` and add some colors for the taglist variables.  If the tag is empty, just show the fg color
  * We'll also disable the icons in the `tasklist` up at the top by setting `theme.tasklist_disable_icon = true`.  Much easier.  We'll change how the titlebar works soon.
  * I generally don't like having the systray always visible since it's not as easy to style the way I want.
    * [Pavel Makhov](https://pavelmakhov.com/awesome-wm-widgets/) not only wrote a great resource for widgets, but also wrote a few tips & tricks that are super useful.  Let's follow how "Systray Tip" to make our systray toggle-able.  But defaults to `visible = false`
    ```
      s.systray = wibox.widget.systray()
      s.systray.visible = false

      -- @DOC_WIBAR@
      -- Create the wibox
      s.mywibox = awful.wibar({
        position = "top",
        screen = s,
        -- @DOC_SETUP_WIDGETS@
        widget = {
          layout = wibox.layout.align.horizontal,
          { -- Left widgets
            layout = wibox.layout.fixed.horizontal,
            mylauncher,
            s.mytaglist,
            s.mypromptbox,
          },
          s.mytasklist, -- Middle widget
          { -- Right widgets
            layout = wibox.layout.fixed.horizontal,
            mykeyboardlayout,
            s.systray,  <----------------Replace the old systray with our new one
            mytextclock,
            s.mylayoutbox,
          },
          buttons = {
            awful.button({}, 2, function()
            s.systray.visible = not s.systray.visible
          end)
         }
        },
      })
    ```
    * Instead of using the keybinding he likes, I want to add a button to the entire wibar.  If I click the scrollwheel (mouse button 2), I want the systray to toggle visibility.
  * Last, let's get rid of the `mykeyboard` layout widget.
#### Finish up and minor cleanup
* I'm going to use [stylua](https://github.com/JohnnyMorganz/StyLua) to auto-format my code.
* Let's make it so we start with the `tile` layout instead of floating by reordering the layouts in the rc.lua
* Lastly, when I open a new client, I want to preserve the `primary` client in its position.  So let's add a callback to the global client rule that will place the client in the secondary section.
```
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
      },
      callback = function(c) <---------This is the difference maker here
        c:to_secondary_section()
      end,
    })
```

* While I'm at it, I think I like the idea of having 3 buttons on the left side of the client like the macos style.  But I'll do "Close", "Floating", and "Maximize"
* I'll also use a more squared off svg as the "square" and name the other one "rounded_square" in case I want to toggle between a more sharp theme and a more rounded flow-y theme down the road.

### Follow along in [Section 2 - Keybindings](https://github.com/trip-zip/awesome-from-scratch/tree/02-keybindings)
