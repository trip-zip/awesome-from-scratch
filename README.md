###### Table of Contents
* Section 0 - Default Config
* Section 1 - Theme & Keybindings
* Section 2 - Wibar
* Section 3 - Notifications
* Section 4 - Titlebars
* Section 5 - Logout Screen
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

#### Titlebar functionality
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
  * We'll also disable the icons in the `tasklist` up at the top by setting `theme.tasklist_disable_icon = true`.  Much easier.  We'll change how the titlebar works soon.
