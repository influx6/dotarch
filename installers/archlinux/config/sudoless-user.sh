# Setup sudo-less controls for controlling brightness on Apple Displays
echo "$USER ALL=(ALL) NOPASSWD: ALL" | sudo tee "/etc/sudoers.d/00-$USER"
sudo chmod 440 "/etc/sudoers.d/00-$USER"
