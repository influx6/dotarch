# Replace With New Line

In Neovim, when performing a search and replace operation using the :s command, special characters are used to represent newlines.
To replace a character or pattern with a newline:
Use \r in the replacement part: In the :s command, \r represents a newline character in the replacement string.
Code

    :%s/pattern/\r/g
This command replaces all occurrences of pattern with a newline character throughout the entire file (%).
Example: To replace all commas with newlines:
Code

    :%s/,/\r/g
Note on \n: While \n is used to search for newline characters, using \n in the replacement part of the :s command will insert a null byte (0x00 or ^@), not a newline. This is a common point of confusion in Vim/Neovim.
