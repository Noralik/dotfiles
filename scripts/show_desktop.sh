
#!/usr/bin/env bash
set -euo pipefail

STATE="${XDG_RUNTIME_DIR:-/tmp}/show-desktop-${UID}.json"

# Скрываем Dashboard из этой операции.
get_clients() {
    hyprctl -j clients | jq '
        [
            .[] |
            select((.class | startswith("dashboard-")) | not) |
            select((.workspace.name | startswith("special:")) | not)
        ]
    '
}

hide_desktop() {
    if [[ -f "$STATE" ]]; then
        restore_desktop
        return
    fi

    local clients
    clients="$(get_clients)"

    # Сохраняем адрес, монитор и исходный workspace каждого окна.
    jq '
        [
            .[] |
            {
                address: .address,
                monitor: .monitor,
                workspace: .workspace.id
            }
        ]
    ' <<< "$clients" > "$STATE"

    while IFS=$'\t' read -r address monitor; do
        [[ -z "$address" ]] && continue

        # Переносим окно в отдельный scratchpad его монитора.
        hyprctl dispatch movetoworkspacesilent \
            "special:showdesktop-${monitor},address:${address}" \
            >/dev/null
    done < <(
        jq -r '.[] | [.address, .monitor] | @tsv' "$STATE"
    )
}

restore_desktop() {
    [[ -f "$STATE" ]] || return 0

    # Сначала создаём исходные рабочие пространства
    # на тех мониторах, где они находились.
    while IFS=$'\t' read -r monitor workspace; do
        hyprctl dispatch focusmonitor "$monitor" >/dev/null
        hyprctl dispatch workspace "$workspace" >/dev/null
    done < <(
        jq -r '[.[] | [.monitor, .workspace]] | unique[] | @tsv' "$STATE"
    )

    # Возвращаем каждое окно на прежний workspace.
    while IFS=$'\t' read -r address monitor workspace; do
        hyprctl dispatch focusmonitor "$monitor" >/dev/null

        hyprctl dispatch movetoworkspacesilent \
            "${workspace},address:${address}" \
            >/dev/null
    done < <(
        jq -r '.[] | [.address, .monitor, .workspace] | @tsv' "$STATE"
    )

    rm -f "$STATE"
}

case "${1:-toggle}" in
    toggle)
        hide_desktop
        ;;
    restore)
        restore_desktop
        ;;
    *)
        echo "Usage: $0 [toggle|restore]"
        exit 1
        ;;
esac
