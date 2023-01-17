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

##### Let's make a couple style changes to make sure it's working
* I like a small gap around my clients.
  `theme.useless_gap = dpi(5)`
* The default wallpaper is cute, but too black for my taste.  You can move wallpapers to the theme directory, or reference your wallpapers directory on your system.  
  `theme.wallpaper = theme_path .. /spaceman.jpg`
* Font can kill a couple birds with 1 stone.  We can get a larger wibar AND titlebars just by increasing font size.  I like JetBrainsMono well enough
  `theme.font = "JetBrainsMono Nerd Font, 12"`

## Credits & Thanks
* [System Crafters's Emacs From Scratch](https://www.youtube.com/playlist?list=PLEoMzSkcN8oPH1au7H6B7bBJ4ZO7BXjSZ)
* [Neovim From Scratch](https://github.com/LunarVim/Neovim-from-scratch)
* & most importantly - [KryptoDigital's Yoshi's Lounge](https://on.soundcloud.com/TjDjm)
