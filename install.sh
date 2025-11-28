#!/bin/bash

# Цвета
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}=== УСТАНОВКА SPECTER OS ===${NC}"

# 1. Обновляем систему и ставим базу (Git, компиляторы)
echo "Подготовка системы..."
sudo pacman -Syu --noconfirm
sudo pacman -S --needed --noconfirm base-devel git

# 2. Установка YAY (Помощник AUR)
if ! command -v yay &> /dev/null; then
    echo -e "${GREEN}Установка yay...${NC}"
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
    cd ..
    rm -rf yay
else
    echo "yay уже установлен."
fi

# 3. Установка пакетов (Добавил sddm и rofi-wayland явно)
echo -e "${GREEN}Установка программ...${NC}"
PKGS=(
    hyprland waybar kitty rofi-wayland dunst starship
    swww hyprlock hypridle wlogout
    ttf-jetbrains-mono-nerd ttf-font-awesome
    pavucontrol grim slurp wl-clipboard
    playerctl btop cava zram-generator fastfetch
    thunar sddm qt5-graphicaleffects qt5-quickcontrols2 qt5-svg
)

for pkg in "${PKGS[@]}"; do
    yay -S --needed --noconfirm "$pkg"
done

# 4. Настройка экрана входа (SDDM)
# Это решит проблему с "черным экраном" на старте
echo -e "${GREEN}Включаем экран входа (SDDM)...${NC}"
sudo systemctl enable sddm

# (Опционально) Ставим тему Catppuccin для SDDM
echo "Ставим тему для экрана входа..."
yay -S --noconfirm sddm-catppuccin-git
# Создаем конфиг для темы
echo "[Theme]
Current=catppuccin" | sudo tee /etc/sddm.conf > /dev/null

# 5. Копирование конфигов
echo -e "${GREEN}Копируем настройки...${NC}"
mkdir -p ~/.config
cp -r ./config/* ~/.config/

# 6. Копирование скриптов
echo -e "${GREEN}Копируем скрипты...${NC}"
mkdir -p ~/.local/bin
cp ./scripts/* ~/.local/bin/
chmod +x ~/.local/bin/*

# Добавляем PATH в .bashrc (чтобы работали команды типа setwall)
if ! grep -q "$HOME/.local/bin" ~/.bashrc; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
    echo 'eval "$(starship init bash)"' >> ~/.bashrc
    echo 'fastfetch' >> ~/.bashrc
fi

# 7. Восстановление картинок (Обои + Терминал)
echo -e "${GREEN}Восстанавливаем картинки...${NC}"
mkdir -p ~/Pictures/Wallpapers
mkdir -p ~/Pictures/Wallkitty

cp -r ./assets/Wallpapers/* ~/Pictures/Wallpapers/
cp -r ./assets/Wallkitty/* ~/Pictures/Wallkitty/ 2>/dev/null

# Ставим дефолтные обои
if [ ! -f ~/Pictures/current_wallpaper.jpg ]; then
    FIRST_WALL=$(ls ~/Pictures/Wallpapers | head -1)
    if [ -n "$FIRST_WALL" ]; then
        cp ~/Pictures/Wallpapers/"$FIRST_WALL" ~/Pictures/current_wallpaper.jpg
    fi
fi

echo -e "${GREEN}=== ГОТОВО! ===${NC}"
echo "Перезагрузи компьютер. Тебя должен встретить экран входа SDDM."
