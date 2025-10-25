# Neovim Get current filename

In Neovim, there are multiple ways to get the current file name, including its full path or just the base name.

1. Displaying the file name:

Ctrl-G: In Normal mode, pressing Ctrl-G will display the current file name (relative to the current working directory), the cursor position, and file status in the command line.

1Ctrl-G: Prepending 1 to Ctrl-G will display the full path of the current file.

2. Inserting the file name into the buffer or command line:

Insert Mode (Ctrl-R %): In Insert mode, type Ctrl-R followed by % to insert the current file name into the buffer at the cursor's position.

Command Mode (Ctrl-R %): When in command mode (after typing :), type Ctrl-R followed by % to insert the current file name into the command line.

Normal Mode ("%p): In Normal mode, type "%p to put the current file name after the cursor, or "%P to insert it before the cursor. 

3. Using Lua API (for scripting):

vim.fn.expand('%:p'): This Lua function call returns the full path of the current file. The %:p modifier ensures that the full path is returned, regardless of the current working directory.

vim.api.nvim_buf_get_name(0): This function returns the full path to the file associated with the current buffer (buffer ID 0 refers to the current buffer).

Example using Lua to print the full path:

```

print(vim.fn.expand('%:p'))
```


Example using Lua to get the filename from the current buffer:

```
local filename = vim.api.nvim_buf_get_name(0)
print(filename)

```



