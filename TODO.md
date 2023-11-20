## TODO

- Game Menu
  - Colors
 - Exit
- Help Menu
- about modal
- Cheat code
- You can't lose on your first click
- Non Color Mode
- defaults for custom field modal
- persist board and game state between tab reloads
- stop clock cheat
- main window needs to be disabled when modals are open

### Errata
- ding animation isn't quite right
- minesweeper window needs to defocus when custom is open
- flags are ignored when clearing

## Done:
- Blind mode scaling
- Best Times
- persist high scores
- secret no rules custom mode???
- Timer starts at one
- Implement winning
- Fix top bar layout
- Variable board sizing
- Game Menu
 - New
 - Difficulty
 - Marks
 - Custom difficulty dialog
 - Sound
- Canvas resizing (run at native resolution in browser)
- Sound
- Title bar dragging
- You win popup dialog thing -> fastest time dialog

### Errata
- minesweeper window resizes when you resize window
- Timer value is not reset
- right clicking is extremely screwed up after drag
- question marks should be clickable
- It plays the wrong game over music??
- Clicking on menu bar causes mouth to open
- Face reacts to clicking anywhere in game instead of just within the window

## Devblog

### 11/11/2023

Made good progress on menus, checkboxes, and sound support. Turns out non-square
grid sizes were 100% broken, had a lot of x and y confusion spread around.

Spent a long time rabbit holing trying to find the font that Windows 2000 uses 
for dialog boxes so that the inputs for the custom dialog would at least have 
the correct font. Tried to use the Wine fonts that ship for this exact purpose, 
but it seems like they only work in godot at certain pixel sizes. The Windows 
font viewer also is broken with these fonts. Frustrating because I almost got it 
to work, but only at the wrong font size. 