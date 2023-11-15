TODO

- Game Menu
  - Colors
  - Best Times
 - Exit
- Help Menu
- Cheat code
- You win popup dialog thing -> fastest time dialog
- You can't lose on your first click
- Title bar dragging
- Blind mode scaling
- Non Color Mode
- Canvas resizing (run at native resolution in browser)
- secret no rules custom mode???

Errata
- Clicking on menu bar causes mouth to open
- Face reacts to clicking anywhere in game instead of just within the window
- It plays the wrong game over music??

Done:
- Timer starts at one
- Timer value is not reset
- Implement winning
- Fix top bar layout
- Variable board sizing
- Game Menu
 - New
 - Difficulty
 - Marks
 - Custom difficulty dialog
 - Sound

- Sound

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