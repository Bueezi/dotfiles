// YouTube Music without the free tier's ads, like uBlock Origin's YouTube filters. Runs in the page
// before its own scripts (executeInMainWorld: the code is copied over, it can't use anything here).
// 1. The player learns where ads go from fields in YouTube's JSON (the player response): those are
//    removed as the page reads them, through JSON.parse and fetch's .json(), and from the copy built
//    into the first page (ytInitialPlayerResponse).
// 2. An ad that still starts (YouTube changes these fields now and then): jumped to its end, or its
//    skip button clicked.
// Below: what's playing, for Discord (discord.js).
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
  },
});

// Every 2 s, sent when the song, play/pause or the position (a seek) changes. This side shares the
// page's DOM and media session, not its JavaScript
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
