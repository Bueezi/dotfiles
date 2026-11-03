#!/bin/sh
# Brightness with the night light: down at sunset, back up at sunrise, for Noctalia's [location]
# (~/.config/noctalia/config.toml; times from heliocron, session.nix). Only when that changes, and at
# login after sunset, so a brightness set by hand stays until the next sunset or sunrise. Checks
# every 5 minutes, so a sleep across sunset is caught on wake. Started by Umbriel's autostart.
night=40% day=100%

# Noctalia starts next to this: wait for its IPC
until lat=$(noctalia msg config-get location.latitude 2>/dev/null); do sleep 2; done
lon=$(noctalia msg config-get location.longitude)

phase() {
    t=$(heliocron -l "$lat" -o "$lon" report --json) || return 1
    now=$(date +%s)
    rise=$(date -d "$(printf '%s' "$t" | jq -r .sunrise)" +%s) || return 1
    down=$(date -d "$(printf '%s' "$t" | jq -r .sunset)" +%s) || return 1
    if [ "$now" -ge "$rise" ] && [ "$now" -lt "$down" ]; then echo day; else echo night; fi
}

last=day   # a login in the day leaves the brightness alone
while :; do
    p=$(phase)
    if [ -n "$p" ] && [ "$p" != "$last" ]; then
        if [ "$p" = night ]; then v=$night; else v=$day; fi
        noctalia msg brightness-set all "$v" >/dev/null && last=$p
    fi
    sleep 300
done
