# Fold Naviagtion

To place the top of a fold at the top of your screen in Neovim, you can move your cursor to the fold and use zV (normal mode), which opens and centers the fold. You can also get to the top of the fold by navigating to the fold's start with zj (jump to next fold) and then using zo (open the fold at the cursor) to unfold it and center it on the screen. 

## Open the fold and keep it on top of the screen

Navigate to the fold you want to view.
Press zV in normal mode to open all nested folds at the cursor and center them on the screen. 


## Navigate to the fold and then open it

Use zj to move the cursor to the start of the next fold.
Use zk to move the cursor to the previous fold.
Once your cursor is on the first line of the fold, press zo to open it and zv to open the fold and center the line. 

## Other useful fold commands

zc: Closes the fold at the cursor.
za: Toggles the fold at the cursor (opens if closed, closes if open).
zM: Closes all folds in the buffer.
zR: Opens all folds in the buffe

## Go to the top of folds

To go to the top of the current open fold in Neovim, use the built-in command [z in Normal mode. This moves the cursor to the first line of the fold your cursor is currently inside. 

Other useful fold navigation commands
[z: Moves to the start of the current fold, or the containing fold if already at the start.
]z: Moves to the end of the current fold, or the containing fold if already at the end.
zj: Moves to the start of the next fold.
zk: Moves to the end of the previous fold. 
Opening and closing folds
zo: Opens the fold under the cursor.
zc: Closes the fold under the cursor.
za: Toggles the fold under the cursor.
zO: Opens all folds under the cursor recursively.
zC: Closes all folds under the cursor recursively.
zR: Opens all folds in the buffer.
zM: Closes all folds in the buffer. 
If [z is not working
If [z and ]z are not working, your foldmethod might be set to manual. Try using these commands after creating folds. 
