# Bash AutoComplete

1. Check Key Bindings
The arrow keys need to be correctly mapped to the history navigation function.
Test the current binding: In your terminal, type read and press the Up arrow key. It should output something like ^[[A or ^[OA.
Verify zsh binding: Run bindkey | grep up-line-or-search. It should show a line like "^[[A" up-line-or-search.
Fix if different: If the output from read and bindkey doesn't match or the binding is missing, you need to set it in your ~/.zshrc file:
bash
bindkey '^[[A' up-line-or-search
bindkey '^[[B' down-line-or-search
Replace ^[[A and ^[[B with the actual output you got from the read command if it was different. 
