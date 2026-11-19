// Ad removal from the player response (like uBlock's filters), skipping any that still play, and
// what's playing for discord.js. executeInMainWorld copies the code: it can't use anything here
require("electron").contextBridge.executeInMainWorld({
  func: () => {
    const adKeys = ["adPlacements", "playerAds", "adSlots", "adBreakHeartbeatParams"];
    const prune = (o) => {
      if (Array.isArray(o)) o.forEach(prune);
      else if (o && typeof o === "object") {
        for (const k of adKeys) delete o[k];
        if (o.playerResponse) prune(o.playerResponse);
      }
      return o;
    };

    const parse = JSON.parse;
    JSON.parse = function (...args) { return prune(parse.apply(this, args)); };
    const json = Response.prototype.json;
    Response.prototype.json = function () { return json.call(this).then(prune); };
    let initial;
    Object.defineProperty(window, "ytInitialPlayerResponse", {
      configurable: true,
      get: () => initial,
      set: (v) => { initial = prune(v); },
    });

    setInterval(() => {
      const player = document.querySelector("#movie_player");
      if (!player || !player.classList.contains("ad-showing")) return;
      const video = player.querySelector("video");
      if (video && Number.isFinite(video.duration)) video.currentTime = video.duration;
      player.querySelector(".ytp-ad-skip-button, .ytp-ad-skip-button-modern, .ytp-skip-ad-button")?.click();
    }, 500);

    // Against "Video paused. Continue watching?"
    setInterval(() => {
      window._lact = Date.now();
      const dialog = document.querySelector("ytmusic-you-there-renderer");
      if (!dialog || !dialog.offsetParent) return;
      dialog.querySelector("button, yt-button-renderer, tp-yt-paper-button")?.click();
      document.querySelector("video")?.play();
    }, 5000);
  },
});

const { ipcRenderer } = require("electron");
let sent = null;
const changed = (a, b) => !a || !b ? a !== b : a.title !== b.title || a.artist !== b.artist || Math.abs(a.start - b.start) > 3000;
setInterval(() => {
  const video = document.querySelector("video");
  const meta = navigator.mediaSession.metadata;
  const ad = document.querySelector("#movie_player.ad-showing");
  const now = video && meta && !video.paused && !ad ? {
    title: meta.title,
    artist: meta.artist,
    album: meta.album,
    art: meta.artwork.at(-1)?.src,
    start: Math.round(Date.now() - video.currentTime * 1000),
    duration: Math.round(video.duration * 1000),
  } : null;
  if (changed(now, sent)) ipcRenderer.send("now-playing", now);
  sent = now;
}, 2000);
