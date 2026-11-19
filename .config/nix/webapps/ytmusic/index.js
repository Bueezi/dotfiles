require("../webapp.js")({
  dir: __dirname,
  title: "YouTube Music",
  url: "https://music.youtube.com/",
  domains: ["youtube.com", "google.com"],
  background: "#030303",
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
require("./discord.js");
