#!/bin/bash

# Цвета для вывода
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== НАЧАЛО УСТАНОВКИ SPECTER DOTFILES ===${NC}"

# 1. Проверка и установка yay (если нет)
if ! command -v yay &> /dev/null; then
    echo "Устанавливаем yay..."
    sudo pacman -S --needed base-devel git
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si
    cd ..
    rm -rf yay
fi

# 2. Установка пакетов
echo -e "${GREEN}Устанавливаем пакеты...${NC}"
PKGS=(
    hyprland waybar kitty rofi-wayland dunst starship
    swww hyprlock hypridle wlogout
    ttf-jetbrains-mono-nerd ttf-font-awesome
    pavucontrol grim slurp wl-clipboard
    playerctl btop cava zram-generator fastfetch
    thunar
)

for pkg in "${PKGS[@]}"; do
    yay -S --needed --noconfirm "$pkg"
done

# 3. Копирование конфигов
echo -e "${GREEN}Копируем конфиги...${NC}"
mkdir -p ~/.config
cp -r ./config/* ~/.config/

# 4. Копирование скриптов
echo -e "${GREEN}Настраиваем скрипты...${NC}"
mkdir -p ~/.local/bin
cp ./scripts/* ~/.local/bin/
chmod +x ~/.local/bin/*

# Добавляем путь в PATH, если его нет
if ! grep -q "$HOME/.local/bin" ~/.bashrc; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
    echo 'eval "$(starship init bash)"' >> ~/.bashrc
    echo 'fastfetch' >> ~/.bashrc
fi

# 5. Копирование обоев
echo -e "${GREEN}Копируем обои...${NC}"
mkdir -p ~/Pictures/Wallpapers
cp -r ./assets/Wallpapers/* ~/Pictures/Wallpapers/

# Создаем дефолтные обои, если нет
if [ ! -f ~/Pictures/current_wallpaper.jpg ]; then
    FIRST_WALL=$(ls ~/Pictures/Wallpapers | head -1)
    cp ~/Pictures/Wallpapers/"$FIRST_WALL" ~/Pictures/current_wallpaper.jpg
fi

echo -e "${GREEN}=== УСТАНОВКА ЗАВЕРШЕНА! ===${NC}"
echo "Перезагрузи компьютер или Hyprland."
