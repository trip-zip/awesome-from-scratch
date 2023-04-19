###### Table of Contents
* [Section 0 - Default Config](https://github.com/trip-zip/awesome-from-scratch/tree/00-default)
* [Section 1 - Theme](https://github.com/trip-zip/awesome-from-scratch/tree/01-theme)
* [Section 2 - Keybindings](https://github.com/trip-zip/awesome-from-scratch/tree/02-keybindings)
* [Section 3 - Wibar](https://github.com/trip-zip/awesome-from-scratch/tree/03-wibar)
* [Section 4 - Notifications](https://github.com/trip-zip/awesome-from-scratch/tree/04-notifications)
* Section 5 - Titlebars
* Section 6 - Logout Screen
* ??



## Notifications
### Goals:
1. Better looking notification widget.
2. Notification "center" with list of active notifications.
3. "Do Not Disturb" mode to pause notifications
4. Destroy all notifications button
5. Some basic logic to do different things (maybe just prioritize focus) if my wife or son send me a message via text.

### Let's consolidate some of the notification rules & styles
* `notifications.lua` to store everything but the beautiful theme variables.
* Rip out the notification rules from the `rc.lua`file and `theme.lua` files
* 
