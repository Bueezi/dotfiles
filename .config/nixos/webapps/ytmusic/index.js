// YouTube Music (see ../webapp.js). Google's sign-in pages stay in the window
require("../webapp.js")({
  dir: __dirname,
  title: "YouTube Music",
  url: "https://music.youtube.com/",
  domains: ["youtube.com", "google.com"],
  background: "#030303",
  // Ad servers and the player's ad requests (the free tier's ads between songs). The ads that come
  // inside YouTube's own responses: preload.js
  block: [
    "*://*.doubleclick.net/*",
    "*://*.googlesyndication.com/*",
    "*://*.googleadservices.com/*",
    "*://*.youtube.com/pagead/*",
    "*://*.youtube.com/api/stats/ads*",
    "*://*.youtube.com/get_midroll_*",
  ],
  preload: "preload.js",
});
