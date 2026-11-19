// Discord "Listening to" over the IPC socket. Client id: th-ch/youtube-music's (needed for the cover)
const { ipcMain } = require("electron");
const net = require("net");
const path = require("path");

const CLIENT_ID = "1177081335727267940";
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
    name: text(song.title),
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
