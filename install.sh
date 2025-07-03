#!/bin/bash
# Check if running as root
if [ "$EUID" -eq 0 ]; then 
    echo "Please do not run as root/sudo. Script will ask for elevation when needed."
    exit 1
fi

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Spinner function for loading animation
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# Function to print status messages
print_status() {
    echo -e "\n${BLUE}[*]${NC} $1"
}

# Function to print success messages
print_success() {
    echo -e "${GREEN}[+]${NC} $1"
}

# Function to print error messages
print_error() {
    echo -e "${RED}[-]${NC} $1"
}

# Function to show progress
show_progress() {
    echo -ne "${YELLOW}Progress: [$1] ${2}%${NC}\r"
}

# Function to notify
notify() {
    if command -v notify-send &> /dev/null; then
        notify-send "$1" "$2" -u normal
    fi
}

# Function to run command with sudo and spinner
run_sudo_command() {
    local command_description=$1
    shift
    
    print_status "$command_description"
    
    # First authenticate with sudo to cache credentials
    sudo -v
    
    # Then run the actual command with spinner
    sudo "$@" &
    local pid=$!
    spinner $pid
    wait $pid
    local exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        print_success "$command_description completed"
    else
        print_error "$command_description failed with exit code $exit_code"
    fi
    
    return $exit_code
}

# Function to run regular command with spinner
run_command() {
    local command_description=$1
    shift
    
    print_status "$command_description"
    "$@" &
    local pid=$!
    spinner $pid
    wait $pid
    local exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        print_success "$command_description completed"
    else
        print_error "$command_description failed with exit code $exit_code"
    fi
    
    return $exit_code
}

# Welcome message
clear
echo -e "${GREEN}=================================${NC}"
echo -e "${GREEN}  Hyprland Installation Script   ${NC}"
echo -e "${GREEN}=================================${NC}\n"

# Pre-authenticate sudo to avoid password prompts during operations
print_status "Please enter your password to proceed with installation"
sudo -v

# Keep sudo credentials fresh for the duration of the script
(while true; do sudo -v; sleep 60; done) &
SUDO_KEEP_ALIVE_PID=$!

# Check if script directory has dotconfigs folder
if [ ! -d "$(dirname "$0")/dotconfigs" ]; then
    print_error "Could not find dotconfigs directory. Make sure you run this script from its directory."
    print_error "Current directory: $(pwd)"
    echo "Directory contents:"
    ls -la
    exit 1
fi

# Update system
run_sudo_command "Updating system" pacman -Syu --noconfirm

# Installing git and base-devel
run_sudo_command "Installing git and base-devel" pacman -S --needed base-devel git --noconfirm

# Installing tmux
run_sudo_command "Installing tmux" pacman -S --needed tmux --noconfirm

# Installing yay
print_status "Installing yay AUR helper..."
mkdir -p ~/Applications
cd ~/Applications || exit
if [ ! -d "yay" ]; then
    git clone https://aur.archlinux.org/yay.git
    cd yay || exit
    run_command "Building yay" makepkg -si --noconfirm
else
    cd yay || exit
    git pull
    run_command "Updating yay" makepkg -si --noconfirm
fi
cd - || exit  # Return to original directory

# Install required packages
run_sudo_command "Installing required packages" pacman -S --noconfirm hyprland fastfetch ttf-jetbrains-mono-nerd noto-fonts-emoji nautilus xdg-desktop-portal-hyprland rofi-wayland rofi-emoji kitty hyprpaper hypridle neovim blueman bluez bluez-utils network-manager-applet pavucontrol playerctl libnotify cliphist wl-clipboard grim slurp imagemagick pipewire pipewire-pulse zoxide zathura brightnessctl zsh polkit-gnome ufw plocate fzf yazi gnome-system-monitor fwupd exfat-utils ntfs-3g hyprpicker power-profiles-daemon hyprlock hyprsunset skim pacman-contrib alsa-utils
# power-profiles-daemon - used by hyprpanel (instead of tlp)
# if using waybar the following 2 packages needs to be installed
# dunst  - replaced with hyprpanel installation
# waybar - replaced waybar with ags-hyprpanel-git (hyprpanel)
# wlsunset - replaced with hyprsunset

# Installing AUR packages
run_command "Installing AUR packages" yay -S --noconfirm brave-bin bibata-cursor-theme  zsh-completions nvm eog wofi-emoji ags-hyprpanel-git ghostty
# replaced swaylock-effects with hyprlock

# Setting up zsh shell
print_status "Setting up zsh shell..."
if [ "$SHELL" != "$(which zsh)" ]; then
    run_sudo_command "Changing default shell to zsh" chsh -s "$(which zsh)" "$USER"
else
    print_success "ZSH is already the default shell"
fi

# Configure bluetooth
print_status "Configuring bluetooth..."
run_sudo_command "Enabling bluetooth service" systemctl enable bluetooth 
run_sudo_command "Starting bluetooth service" systemctl start bluetooth

# Create configuration directories
print_status "Creating configuration directories..."
mkdir -p ~/.config/{hypr,hyprpanel,rofi,fastfetch,nvim,ghostty,kitty,swaylock,tmux,yazi}

# Save current directory to return to it later
SCRIPT_DIR="$(pwd)"

# Copy configuration files
print_status "Copying configuration files..."
dirs=("fastfetch" "ghostty" "hypr" "hyprpanel" "kitty" "nvim" "rofi" "scripts" "tmux" "yazi" "zathura")
total_dirs=${#dirs[@]}
for i in "${!dirs[@]}"; do
    dir="${dirs[$i]}"
    source_dir="$SCRIPT_DIR/dotconfigs/$dir"
    target_dir="$HOME/.config/$dir"
    
    if [ -d "$source_dir" ]; then
        mkdir -p "$target_dir"
        cp -r "$source_dir"/* "$target_dir"/ 2>/dev/null || true
        print_success "Copied $dir configuration"
    else
        print_error "Source directory $source_dir not found"
    fi
    
    # Calculate progress percentage
    progress=$(( (i+1) * 100 / total_dirs ))
    show_progress "##########" $progress
done
echo  # Add a newline after progress bar

# Copy other config files
# if [ -f "$SCRIPT_DIR/dotconfigs/.bashrc" ]; then
#     cp -r "$SCRIPT_DIR/dotconfigs/.bashrc" ~/.config/.bashrc
#     print_success "Copied .bashrc"
# else
#     print_error "dotconfigs/.bashrc not found"
# fi

if [ -f "$SCRIPT_DIR/dotconfigs/.zshrc" ]; then
    cp -r "$SCRIPT_DIR/dotconfigs/.zshrc" ~/.config/.zshrc
    print_success "Copied .zshrc"
else
    print_error "dotconfigs/.zshrc not found"
fi

# Symlink .zshrc from .config folder to home
ln -s ~/.config/.zshrc ~/.zshrc

# Setup TPM (Tmux Plugin Manager)
print_status "Setting up TPM (Tmux Plugin Manager)..."
TPM_DIR="$HOME/.tmux/plugins/tpm"
if [ ! -d "$TPM_DIR" ]; then
    mkdir -p "$HOME/.tmux/plugins"
    git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
    print_success "TPM installed successfully"
else
    print_status "TPM already exists, updating..."
    cd "$TPM_DIR" && git pull
    print_success "TPM updated successfully"
fi

# Install tmux plugins using TPM
print_status "Installing tmux plugins..."
if [ -f "$HOME/.config/tmux/tmux.conf" ]; then
    # Create symlink for tmux config in expected location
    # ln -sf ~/.config/tmux/tmux.conf ~/.tmux.conf
    
    # Install plugins using TPM
    "$TPM_DIR/bin/install_plugins"
    print_success "Tmux plugins installed successfully"
    
    # Reload tmux configuration if tmux is running
    if pgrep -x tmux > /dev/null; then
        tmux source-file ~/.tmux.conf
        print_success "Tmux configuration reloaded"
    fi
else
    print_error "Tmux configuration file not found at ~/.config/tmux/tmux.conf"
    print_error "TPM plugins cannot be installed without tmux configuration"
fi

# Configure cursor theme
run_sudo_command "Configuring cursor theme" mkdir -p /usr/share/icons/default/
cat << EOF | sudo tee /usr/share/icons/default/index.theme > /dev/null
[Icon Theme]
Inherits=Bibata-Modern-Classic
EOF

# Configure GTK-3.0 settings
mkdir -p ~/.config/gtk-3.0/
cat << EOF > ~/.config/gtk-3.0/settings.ini
[Settings]
gtk-cursor-theme-name=Bibata-Modern-Classic
EOF

# Configure Hyprland cursor
HYPR_CONF="$HOME/.config/hypr/hyprland.conf"
if [ ! -f "$HYPR_CONF" ]; then
    mkdir -p "$(dirname "$HYPR_CONF")"
    touch "$HYPR_CONF"
fi
if ! grep -q "XCURSOR_THEME" "$HYPR_CONF"; then
    echo -e "\n# Cursor configuration" >> "$HYPR_CONF"
    echo "env = XCURSOR_THEME,Bibata-Modern-Classic" >> "$HYPR_CONF"
    echo "env = XCURSOR_SIZE,20" >> "$HYPR_CONF"
fi

# Setting up ufw (firewall)
run_sudo_command "Enabling firewall" ufw enable

# Setting up TLP for (Power saving) - replaced with power-profiles-daemon(hyprpanel)
# run_sudo_command "Installing TLP" pacman -S tlp tlp-rdw --noconfirm
# run_sudo_command "Enabling TLP service" systemctl enable tlp
# run_sudo_command "Starting TLP service" systemctl start tlp
   
# Setup wallpaper
print_status "Setting up wallpaper..."
mkdir -p ~/Pictures/Wallpapers/
if [ -f "$SCRIPT_DIR/images/boy-coding-wallpaper.jpg" ]; then
    cp "$SCRIPT_DIR/images/boy-coding-wallpaper.jpg" ~/Pictures/Wallpapers/
    print_success "Copied wallpaper"
else
    print_error "Wallpaper not found at $SCRIPT_DIR/images/boy-coding-wallpaper.jpg"
fi
if [ -f "$SCRIPT_DIR/images/darkwallpaper.jpg" ]; then
    cp "$SCRIPT_DIR/images/darkwallpaper.jpg" ~/Pictures/Wallpapers/
    print_success "Copied wallpaper"
else
    print_error "Wallpaper not found at $SCRIPT_DIR/images/darkwallpaper.jpg"
fi

# Make sure hyprpaper configuration is correct
HYPRPAPER_CONF="$HOME/.config/hypr/hyprpaper.conf"
if [ -f "$HYPRPAPER_CONF" ]; then
    # Update wallpaper path in hyprpaper.conf
    sed -i "s|^preload =.*$|preload = ~/Pictures/Wallpapers/darkwallpaper.jpg|" "$HYPRPAPER_CONF"
    sed -i "s|^wallpaper =.*$|wallpaper = ,~/Pictures/Wallpapers/darkwallpaper.jpg|" "$HYPRPAPER_CONF"
    print_success "Updated hyprpaper configuration"
fi

# Restart services
print_status "Restarting services..."
# Check if Hyprland is running before trying to restart services
if [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
    pkill hyprpaper || true
    sleep 1
    hyprpaper &
    
    # Check if hyprpanel is installed before trying to run it
    if command -v hyprpanel &> /dev/null; then
        pkill hyprpanel || true
        sleep 1
        hyprpanel &
    fi
    print_success "Services restarted"
else
    print_status "Hyprland is not running. Services will start on next login."
fi

# Kill the sudo credential keeper
kill $SUDO_KEEP_ALIVE_PID 2>/dev/null || true

# Final notification
notify "Installation Complete" "Please restart Hyprland for all changes to take effect"

# Final message
echo -e "\n${GREEN}=================================${NC}"
echo -e "${GREEN}    Installation Complete!         ${NC}"
echo -e "${GREEN}=================================${NC}"
echo -e "\nPlease ${YELLOW}restart Hyprland${NC} for all changes to take effect.\n"
echo -e "${BLUE}Tmux Plugin Manager (TPM) has been installed.${NC}"
echo -e "${BLUE}To manually install plugins later, press ${YELLOW}prefix + I${NC} ${BLUE}in tmux${NC}"
echo -e "${BLUE}To update plugins, press ${YELLOW}prefix + U${NC} ${BLUE}in tmux${NC}"
echo -e "${BLUE}To remove plugins, press ${YELLOW}prefix + alt + u${NC} ${BLUE}in tmux${NC}\n"
