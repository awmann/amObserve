amObserve is an IDL routine designed to help while at the telescope/observing. It is currently a pretty basic tool, but I’m hoping to expand it into something much more useful as time moves on.


To get you started:
.r amobserve
amobserve
click on 'Load'
read in a file like the test.txt or test_types.txt file I attached
Then click plot

You will see the current distribution of targets on the sky, colored by ‘type’. Technically type was designed for standards versus targets, but you can use any reasonable string and up to 4 unique types (I can expand this but the plot gets quite confusing). 

Click on a target and it will show an airmass plot of that target for the night in local and UTC time. The selected target should be highlighted in red on the upper plot.
You can keep clicking on targets.
To escape the target clicking mode click anywhere ‘off’ the plot (try clicking the bottom plot).
Note that you cannot hit any of the buttons (well you can but they won’t work) while you are clicking on targets. I can't figure out a way to get around this yet (limitations of cursor.pro)

Airmass and Altitude buttons switch between linear in airmass and linear in altitude in the plot. You have to hit ‘plot’ to realize the change.

Quit doesn’t work, not sure why, just use .reset to quit.


You can change to any date by typing in the YYYYMMDDHH.HH (hit return after changing, you will get a confirmation in the terminal). I think this is UTC time, but I'll adjust to local time in a future version (or let user specify). Refresh will undo this change (refresh sets to current time).

You can change observatories, but there are just 3 options.

If you change anything you have to hit 'refresh' or 'plot'. The difference is that refresh does not let you click on stars for an airmass plot. Refresh also 'resets' the time, so good to hit once in a while while observing.

To work you need to be setup to 'click' on x11 windows. This means adding: 
defaults write com.apple.x11 wm_click_through -bool true
to your .cshrc or .bashrc
and changing x11 preferences (windows) to activate 'click through inactive windows'


Things not included but I'm currently working on:
Ability to mark a target as observed to remove from list
'Suggested' next targets with short slews (complicated)
Multiple targets in airmass plot
Get rid of the 'flicker' effect when you click on stars (it's trying to re-plot the whole thing)
Moon on overhead plot
auto-updating (no need to hit refresh)
A more attractive GUI (this comes last)
Suggestions welcome!
