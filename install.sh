#!/bin/bash

# Цвета для красоты
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${GREEN}=== УСТАНОВКА SPECTER OS ===${NC}"

# 0. Определяем имя пользователя
# Скрипт настроит авто-вход именно для того юзера, который его запустил
CURRENT_USER=$(whoami)
echo "Установка для пользователя: $CURRENT_USER"

# 1. База
echo "Обновление баз данных..."
sudo pacman -Syu --noconfirm
sudo pacman -S --needed --noconfirm base-devel git

# 2. Установка YAY
if ! command -v yay &> /dev/null; then
    echo -e "${GREEN}Установка yay...${NC}"
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
    cd ..
    rm -rf yay
fi

# 3. ПОЛНЫЙ СПИСОК ПАКЕТОВ
# Здесь всё, что мы настраивали
echo -e "${GREEN}Установка программ...${NC}"
PKGS=(
    # Графика и база
    hyprland waybar kitty rofi-wayland sddm
    
    # Красота
    swww hyprlock hypridle wlogout dunst starship fastfetch
    ttf-jetbrains-mono-nerd ttf-font-awesome
    qt5-graphicaleffects qt5-quickcontrols2 qt5-svg # Нужны для тем sddm/rofi

    # Утилиты
    pavucontrol playerctl btop cava zram-generator
    grim slurp wl-clipboard libnotify network-manager-applet
    thunar
)

for pkg in "${PKGS[@]}"; do
    yay -S --needed --noconfirm "$pkg"
done

# 4. Настройка SDDM + Авто-вход (Autologin)
echo -e "${GREEN}Настройка входа в систему...${NC}"
sudo systemctl enable sddm

# Создаем папку конфигов SDDM
sudo mkdir -p /etc/sddm.conf.d

# Пишем файл авто-входа. 
# Теперь комп будет сам заходить в Hyprland, а там встретит Hyprlock.
echo "[Autologin]
User=$CURRENT_USER
Session=hyprland" | sudo tee /etc/sddm.conf.d/autologin.conf > /dev/null

# (Опционально) Ставим тему Catppuccin для SDDM, чтобы при загрузке не моргало синим
yay -S --noconfirm sddm-catppuccin-git
echo "[Theme]
Current=catppuccin" | sudo tee /etc/sddm.conf > /dev/null

# 5. Копирование конфигов
echo -e "${GREEN}Применяем настройки (Dotfiles)...${NC}"
mkdir -p ~/.config
cp -r ./config/* ~/.config/

# 6. Скрипты
mkdir -p ~/.local/bin
cp ./scripts/* ~/.local/bin/
chmod +x ~/.local/bin/*

# Добавляем скрипты в PATH
if ! grep -q "$HOME/.local/bin" ~/.bashrc; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
    echo 'eval "$(starship init bash)"' >> ~/.bashrc
    echo 'fastfetch' >> ~/.bashrc
fi

# 7. Картинки (Восстанавливаем обои и фон терминала)
echo -e "${GREEN}Восстанавливаем обои...${NC}"
mkdir -p ~/Pictures/Wallpapers
mkdir -p ~/Pictures/Wallkitty

cp -r ./assets/Wallpapers/* ~/Pictures/Wallpapers/
cp -r ./assets/Wallkitty/* ~/Pictures/Wallkitty/ 2>/dev/null

# Устанавливаем дефолтные обои
if [ ! -f ~/Pictures/current_wallpaper.jpg ]; then
    FIRST_WALL=$(ls ~/Pictures/Wallpapers | head -1)
    if [ -n "$FIRST_WALL" ]; then
        cp ~/Pictures/Wallpapers/"$FIRST_WALL" ~/Pictures/current_wallpaper.jpg
    fi
fi

echo -e "${GREEN}=== ГОТОВО! ===${NC}"
echo "Теперь перезагрузи компьютер."
echo "Система сама войдет в сеанс и покажет экран блокировки Hyprlock."
