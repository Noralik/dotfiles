
#!/usr/bin/env bash
set -euo pipefail

DASHBOARD_MONITOR="DVI-D-1"
KITTY_CONFIG="$HOME/.config/kitty/dashboard.conf"
STATE_FILE="${XDG_RUNTIME_DIR:-/tmp}/hypr-dashboard-${UID}.state"

get_window() {
    hyprctl -j clients | jq -r --arg c "$1" \
        '.[] | select(.class == $c) | .address' | head -n 1
}

is_visible() {
    hyprctl -j monitors | jq -e --arg m "$DASHBOARD_MONITOR" '
        any(.[]; .name == $m and
        ((.specialWorkspace.name // "") | endswith("dashboard")))
    ' >/dev/null
}


launch_if_missing() {
    local class="$1"
    local title="$2"
    shift 2

    if [[ -z "$(get_window "$class")" ]]; then
        if [[ "$class" == "dashboard-fastfetch" ]]; then
            kitty --hold --config "$KITTY_CONFIG" \
                --class "$class" \
                --title "$title" \
                -e "$@" >/dev/null 2>&1 &
        else
            kitty --config "$KITTY_CONFIG" \
                --class "$class" \
                --title "$title" \
                -e "$@" >/dev/null 2>&1 &
        fi
    fi
}



wait_window() {
    local class="$1"

    for _ in {1..80}; do
        local address
        address="$(get_window "$class")"

        if [[ -n "$address" ]]; then
            echo "$address"
            return 0
        fi

        sleep 0.1
    done

    echo "Window not found: $class" >&2
    return 1
}


place_window() {
    local class="$1"
    local x="$2"
    local y="$3"
    local w="$4"
    local h="$5"

    local address
    address="$(wait_window "$class")"

    # Переводим конкретное окно в плавающий режим
    hyprctl dispatch setfloating "address:$address" >/dev/null

    # Изменяем размер именно этого окна
    hyprctl dispatch resizewindowpixel "exact $w $h,address:$address" >/dev/null

    # Перемещаем именно это окно
    hyprctl dispatch movewindowpixel "exact $x $y,address:$address" >/dev/null
}


show_dashboard() {
    # Сохраняем исходный монитор и workspace один раз
    if [[ ! -f "$STATE_FILE" ]]; then
        hyprctl -j monitors | jq -r '
            .[] | select(.focused) |
            [.name, .activeWorkspace.id] | @tsv
        ' > "$STATE_FILE"

        pkill -x -USR1 waybar 2>/dev/null || true
    fi

    # Переходим на Fujitsu
    hyprctl dispatch focusmonitor "$DASHBOARD_MONITOR" >/dev/null

    # Показываем special workspace, только если он скрыт
    if ! is_visible; then
        hyprctl dispatch togglespecialworkspace dashboard >/dev/null
    fi

    # Все новые окна запускаются непосредственно на Dashboard
    launch_if_missing dashboard-btop btop btop
    launch_if_missing dashboard-clock Clock tty-clock -cxC 6
    launch_if_missing dashboard-fastfetch Fastfetch fastfetch
    launch_if_missing dashboard-cava Cava cava
    launch_if_missing dashboard-cmatrix Matrix cmatrix -b -C blue

    # Ждём создания окон
    sleep 1


    # Раскладка для Fujitsu 1680x1050

    # Слева сверху — системная информация
    place_window dashboard-fastfetch   40  50 760 300

    # Слева посередине — аудиовизуализация
    place_window dashboard-cava        40 380 760 250

    # Слева снизу — Matrix
    place_window dashboard-cmatrix     40 660 760 330

    # Справа сверху — часы
    place_window dashboard-clock      850  50 790 150

    # Справа снизу — btop
    place_window dashboard-btop       850 240 790 750

}

hide_dashboard() {
    if [[ ! -f "$STATE_FILE" ]]; then
        exit 0
    fi

    hyprctl dispatch focusmonitor "$DASHBOARD_MONITOR" >/dev/null

    if is_visible; then
        hyprctl dispatch togglespecialworkspace dashboard >/dev/null
    fi

    pkill -x -USR1 waybar 2>/dev/null || true

    # Возвращаемся туда, откуда открыли Dashboard
    if [[ -s "$STATE_FILE" ]]; then
        IFS=$'\t' read -r prev_monitor prev_workspace < "$STATE_FILE"

        if [[ -n "${prev_monitor:-}" ]]; then
            hyprctl dispatch focusmonitor "$prev_monitor" >/dev/null
        fi

        if [[ "${prev_workspace:-0}" =~ ^[0-9]+$ ]] &&
           (( prev_workspace > 0 )); then
            hyprctl dispatch workspace "$prev_workspace" >/dev/null
        fi
    fi

    rm -f "$STATE_FILE"
}

case "${1:-toggle}" in
    show) show_dashboard ;;
    hide) hide_dashboard ;;
    toggle)
        if [[ -f "$STATE_FILE" ]]; then
            hide_dashboard
        else
            show_dashboard
        fi
        ;;
    *)
        echo "Usage: $0 {show|hide|toggle}"
        exit 1
        ;;
esac
