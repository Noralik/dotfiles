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
echo -e "${GREEN}Установка программ...${NC}"
PKGS=(
    # --- ГРАФИЧЕСКАЯ БАЗА ---
    hyprland waybar kitty rofi-wayland sddm

    # --- ФАЙЛЫ, ТЕЛЕФОН И ПРОСМОТР ---
    thunar                  # Файловый менеджер
    thunar-archive-plugin   # Чтобы в Thunar работали архивы (ZIP/RAR)
    file-roller             # Программа-архиватор
    gvfs gvfs-mtp           # "Мозги" для флешек и подключения Android по кабелю
    viewnior                # Легкий просмотр картинок
    kdeconnect              # Беспроводная связь с телефоном (файлы, буфер обмена)
    filezilla               # FTP-клиент (для сложных задач)
    unzip
    # --- КРАСОТА И ОФОРМЛЕНИЕ ---
    swww                    # Демон обоев
    hyprlock hypridle       # Экран блокировки и авто-сон
    wlogout                 # Красивое меню выхода
    dunst                   # Уведомления
    starship fastfetch      # Стиль терминала
    ttf-jetbrains-mono-nerd # Главный шрифт с иконками (ОБЯЗАТЕЛЬНО)
    ttf-font-awesome        # Доп. иконки для Waybar
    qt5-graphicaleffects qt5-quickcontrols2 qt5-svg # Библиотеки, чтобы темы SDDM не ломались

    # --- ПОЛЕЗНЫЕ УТИЛИТЫ ---
    pavucontrol             # Настройка звука (GUI)
    playerctl               # Управление плеером (кнопки Назад/Вперед)
    cava                    # Эквалайзер
    btop                    # Диспетчер задач (нагрузка CPU/RAM)
    zram-generator          # Оптимизация памяти (чтобы комп не зависал)
    grim slurp              # Инструменты для скриншотов
    wl-clipboard            # Работа буфера обмена (Ctrl+C / Ctrl+V)
    libnotify               # Чтобы скрипты могли слать уведомления
    network-manager-applet  # Иконка Wi-Fi в трее

    # --- УТИЛИТЫ ФАЙЛОВОЙ СИСТЕМЫ ---
    dosfstools
    ntfs-3g

    # --- УЛУЧШЕНИЯ ИНТЕРФЕЙСА ---
    nwg-look                # Настройка темы GTK
    catppuccin-gtk-theme-mocha # Темная тема окон
    
    # --- УТИЛИТЫ ---
    cliphist                # История буфера обмена (как Win+V)
    hyprpicker              # Пипетка цвета
    kooha                   # Запись экрана
    dosfstools ntfs-3g      # (То, что мы чинили для дисков)
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

# --- НАСТРОЙКА ZRAM (Сжатие памяти) ---
echo -e "${GREEN}Настройка оптимизации памяти (ZRAM)...${NC}"
echo "[zram0]
zram-size = min(ram, 8192)
compression-algorithm = zstd" | sudo tee /etc/systemd/zram-generator.conf > /dev/null

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
