# Discord Rich Presence for native Linux Steam games, through Vesktop's arRPC.
# arRPC finds games by process name, and Discord's list mostly has only Windows .exe names,
# so native games (CS2, Factorio...) go unseen; Proton ones are already found.
# Steam logs "Game process added : AppID N" / "Game process removed: AppID N" in console_log.txt:
# `tail -F` waits on inotify (no polling); on a start the game's name (its appmanifest) is looked
# up in Discord's list and its activity is set over arRPC's IPC socket, kept open while it runs.
# Games already running when it starts are found once in /proc.
#   steam-rpc.py --build arRpcWorker.js.map > games.tsv   (at build time, see gaming.nix)
#   steam-rpc.py games.tsv                               (the user service)
import json, os, re, socket, struct, subprocess, sys, time, unicodedata

STEAM = os.path.expanduser("~/.local/share/Steam")
LINE = re.compile(r'Game process (added|removed) ?: AppID (\d+) "(.*?)", ProcID (\d+)')
PROTON = re.compile(r"/proton['\"]?\s+(waitforexitandrun|run)\b")


def norm(name):
    name = unicodedata.normalize("NFKD", re.sub("[™®©]", "", name)).lower()
    return re.sub(r"[^a-z0-9]", "", name)


def build(sourcemap):
    m = json.load(open(sourcemap))
    db = next(json.loads(c) for s, c in zip(m["sources"], m["sourcesContent"]) if s.endswith("/detectable.json"))
    for g in db:  # one "name<TAB>id<TAB>display name" line each, read line by line at a game start
        for n in {norm(n) for n in [g["name"], *g.get("aliases", [])]}:
            print(n, g["id"], g["name"], sep="\t")


def lookup(games_file, name):
    key = norm(name) + "\t"
    with open(games_file) as f:
        for line in f:
            if line.startswith(key):
                return line.rstrip("\n").split("\t")[1:]


def steam_name(appid):
    vdf = open(f"{STEAM}/steamapps/libraryfolders.vdf").read()
    for lib in re.findall(r'"path"\s+"(.*?)"', vdf):
        try:
            acf = open(f"{lib}/steamapps/appmanifest_{appid}.acf", errors="replace").read()
        except OSError:
            continue
        if m := re.search(r'"name"\s+"(.*?)"', acf):
            return m.group(1)


def frame(op, data):
    data = json.dumps(data).encode()
    return struct.pack("<ii", op, len(data)) + data


def set_activity(client_id, name, pid):
    for i in range(10):
        s = socket.socket(socket.AF_UNIX)
        try:
            s.settimeout(2)
            s.connect(f"{os.environ['XDG_RUNTIME_DIR']}/discord-ipc-{i}")
            s.sendall(frame(0, {"v": 1, "client_id": client_id}))
            s.recv(65536)  # READY, so the next frame comes after the handshake
            s.sendall(frame(1, {"cmd": "SET_ACTIVITY", "nonce": "1", "args": {"pid": pid, "activity": {
                "name": name, "timestamps": {"start": int(time.time() * 1000)}}}}))
            return s
        except OSError:
            s.close()
    print("no Discord IPC socket (Vesktop not running?)", flush=True)


def already_running():
    # Games started before this service (login, restart): their `reaper SteamLaunch AppId=N`, once
    for pid in filter(str.isdigit, os.listdir("/proc")):
        try:
            argv = open(f"/proc/{pid}/cmdline").read().split("\0")
        except OSError:
            continue
        if argv[0].endswith("/reaper") and "SteamLaunch" in argv:
            if m := re.search(r"\bAppId=(\d+)", " ".join(argv)):
                yield m.group(1), " ".join(argv), pid


def main(games_file):
    running = {}  # appid -> open IPC socket (closing it clears the activity)

    def start(appid, command, pid):
        if appid in running or PROTON.search(command):
            return
        name = steam_name(appid)
        game = name and lookup(games_file, name)
        if not game:
            print(f"AppID {appid} ({name}) isn't in Discord's list", flush=True)
            return
        if s := set_activity(game[0], game[1], int(pid)):
            print(f"playing {game[1]}", flush=True)
            running[appid] = s

    tail = subprocess.Popen(["tail", "-F", "-n0", f"{STEAM}/logs/console_log.txt"],
                            stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True, errors="replace")
    for game in already_running():
        start(*game)
    for line in tail.stdout:
        m = LINE.search(line)
        if not m:
            continue
        event, appid, command, pid = m.groups()
        if event == "removed":
            if s := running.pop(appid, None):
                s.close()
        else:
            start(appid, command, pid)
    sys.exit("tail exited")


if __name__ == "__main__":
    build(sys.argv[2]) if sys.argv[1] == "--build" else main(sys.argv[1])
