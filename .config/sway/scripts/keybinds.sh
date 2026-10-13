#!/usr/bin/env bash
# Keybind cheatsheet: parse bindsym lines from the sway config into fuzzel.
# Picking an entry runs its command through swaymsg.

config="${1:-$HOME/.config/sway/config}"

list=$(awk '
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

    /^[ \t]*#/ {
        # Comments inside a bindsym block name the section ("# Apps", "# Focus"...)
        if (inblock) { s = $0; sub(/^[ \t]*#[ \t]*/, "", s); section = tolower(s); gsub(/[ \t]+/, "-", section) }
        next
    }
    /^[ \t]*$/ { next }
    /^set[ \t]+\$/ { v = $3; for (i = 4; i <= NF; i++) v = v " " $i; vars[$2] = v; next }
    /^mode[ \t]/ { mode = $0; sub(/^mode[ \t]+"?/, "", mode); sub(/"?[ \t]*\{.*/, "", mode); next }
    /^[ \t]*bindsym.*\{[ \t]*$/ { inblock = 1; section = "misc"; if ($0 ~ /--locked/) section = "media"; next }
    /^[ \t]*\}/ { if (inblock) inblock = 0; else mode = ""; next }
    inblock { emit($0); next }
    /^[ \t]*bindsym[ \t]/ { section = "misc"; l = $0; sub(/^[ \t]*bindsym[ \t]+/, "", l); emit(l) }
' "$config")

choice=$(printf '%s\n' "$list" | fuzzel --dmenu --prompt "keys ❯ " --width 110 --lines 20) || exit 0

# Everything after the section and key columns is the command
cmd=$(printf '%s' "$choice" | awk '{ $1 = ""; $2 = ""; sub(/^[ \t]+/, ""); print }')
[ -n "$cmd" ] && swaymsg -- "$cmd" >/dev/null
