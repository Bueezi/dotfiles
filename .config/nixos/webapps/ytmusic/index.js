// YouTube Music (see ../webapp.js). Google's sign-in pages stay in the window
require("../webapp.js")({
  dir: __dirname,
  title: "YouTube Music",
  url: "https://music.youtube.com/",
  domains: ["youtube.com", "google.com"],
  background: "#030303",
});
