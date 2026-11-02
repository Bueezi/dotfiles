// Discord Rich Presence ("Listening to <song>": artist, album, cover, progress) over the IPC socket
// Vesktop's arRPC serves, like ../../steam-rpc.py. preload.js sends what's playing; a pause or an ad
// clears it. A client id is required (the cover goes through its assets): the one made for
// th-ch/youtube-music; `name` overrides its name, Vesktop keeps it. Vesktop not running: tried
// again at the next change.
const { ipcMain } = require("electron");
const net = require("net");
const path = require("path");

const CLIENT_ID = "1177081335727267940";
// arRPC's own lookup: XDG_RUNTIME_DIR on the PCs, Termux's TMPDIR on the tablet
const dir = process.env.XDG_RUNTIME_DIR || process.env.TMPDIR || process.env.TMP || process.env.TEMP || "/tmp";
let sock, ready = false, song = null;

const frame = (op, data) => {
  const json = Buffer.from(JSON.stringify(data));
  const head = Buffer.alloc(8);
  head.writeInt32LE(op, 0);
  head.writeInt32LE(json.length, 4);
  return Buffer.concat([head, json]);
};
const text = (s) => s && s.slice(0, 128);

function update() {
  if (!sock) return connect();
  if (!ready) return;   // sent once the handshake is answered
  const activity = song && {
    type: 2,   // Listening to
    name: text(song.title),   // the member list's "Listening to …"
    details: text(song.artist),
    state: text(song.album) || undefined,
    assets: song.art && { large_image: song.art },
    timestamps: { start: song.start, end: Number.isFinite(song.duration) ? song.start + song.duration : undefined },
  };
  sock.write(frame(1, { cmd: "SET_ACTIVITY", nonce: String(Date.now()), args: { pid: process.pid, activity } }));
}

// discord-ipc-0 to -9, the first that answers
function connect(i = 0) {
  if (!song) return;
  const s = sock = net.connect(path.join(dir, `discord-ipc-${i}`));
  s.on("connect", () => s.write(frame(0, { v: 1, client_id: CLIENT_ID })));
  s.once("data", () => { ready = true; update(); });
  s.on("error", () => {});
  s.on("close", () => {
    if (sock !== s) return;
    sock = null;
    if (!ready && i < 9) connect(i + 1);
    ready = false;
  });
}

ipcMain.on("now-playing", (_, now) => { song = now; update(); });
