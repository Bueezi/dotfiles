#!/usr/bin/env bash
# Keybind cheatsheet: parse bindsym lines from the WM config (and the common.conf it includes)
# into a menu. Picking an entry runs its command. Sway: wm/sway, fuzzel, swaymsg. i3: wm/i3, rofi, i3-msg.
# Sections: comments of one or two words ("# Apps", "# Move window") name the keys below them.

if [ -n "$SWAYSOCK" ]; then
    wm=sway msg=swaymsg menu=(fuzzel --dmenu --prompt "keys ❯ " --width 110 --lines 20)
else
    wm=i3 msg=i3-msg menu=(rofi -dmenu -i -p keys -l 20)
fi
config="${1:-$HOME/.config/wm/$wm}"

# Inline `include` lines (~ expanded, globs allowed), so the shared keys show up too
flatten() {
    local line f
    while IFS= read -r line || [ -n "$line" ]; do
        if [[ $line =~ ^[[:space:]]*include[[:space:]]+(.+)$ ]]; then
            for f in ${BASH_REMATCH[1]/#\~/$HOME}; do [ -f "$f" ] && flatten < "$f"; done
        else
            printf '%s\n' "$line"
        fi
    done
}

list=$(flatten < "$config" | awk '
    function expand(s,   n, i, k) {
        # Substitute $vars, longest names first so $scripts wins over $s
        n = 0; for (k in vars) keys[++n] = k
        for (i = 1; i <= n; i++) for (j = i + 1; j <= n; j++)
            if (length(keys[j]) > length(keys[i])) { t = keys[i]; keys[i] = keys[j]; keys[j] = t }
        for (i = 1; i <= n; i++) while ((p = index(s, keys[i])) > 0)
            s = substr(s, 1, p - 1) vars[keys[i]] substr(s, p + length(keys[i]))
        return s
    }
    function pretty(k) {
        gsub(/Mod4/, "Super", k); gsub(/Mod1/, "Alt", k); gsub(/Control/, "Ctrl", k)
        return k
    }
    function emit(line,   key, cmd) {
        sub(/^[ \t]+/, "", line)
        while (line ~ /^--/) sub(/^--[^ \t]+[ \t]+/, "", line)   # drop --locked, --release, ...
        key = line; sub(/[ \t].*/, "", key)
        cmd = line; sub(/^[^ \t]+[ \t]+/, "", cmd)
        key = pretty(expand(key)); cmd = expand(cmd)
        printf "%-8s %-22s %s\n", (mode == "" ? section : "[" mode "]"), key, cmd
    }

    /^[ \t]*#[ \t]*[A-Z][a-z]+([ \t][a-z]+)?[ \t]*$/ {
        s = $0; sub(/^[ \t]*#[ \t]*/, "", s); sub(/[ \t]+$/, "", s); section = tolower(s); gsub(/[ \t]+/, "-", section)
        next
    }
    /^[ \t]*#/ { next }
    /^[ \t]*$/ { next }
    /^set[ \t]+\$/ { v = $3; for (i = 4; i <= NF; i++) v = v " " $i; vars[$2] = v; next }
    /^mode[ \t]/ { mode = $0; sub(/^mode[ \t]+"?/, "", mode); sub(/"?[ \t]*\{.*/, "", mode); next }
    /^[ \t]*bindsym.*\{[ \t]*$/ { inblock = 1; section = "misc"; if ($0 ~ /--locked/) section = "media"; next }
    /^[ \t]*\}/ { if (inblock) inblock = 0; else mode = ""; next }
    inblock { emit($0); next }
    /^[ \t]*bindsym[ \t]/ { l = $0; sub(/^[ \t]*bindsym[ \t]+/, "", l); emit(l) }
')

choice=$(printf '%s\n' "$list" | "${menu[@]}") || exit 0

# Everything after the section and key columns is the command
cmd=$(printf '%s' "$choice" | awk '{ $1 = ""; $2 = ""; sub(/^[ \t]+/, ""); print }')
[ -n "$cmd" ] && $msg -- "$cmd" >/dev/null
