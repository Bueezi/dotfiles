// KU Leuven's Toledo (see ../webapp.js). Its sign-in (idp.kuleuven.be) and course pages stay in the
// app; the icon is Toledo's favicon redrawn larger
require("../webapp.js")({
  dir: __dirname,
  title: "Toledo",
  url: "https://toledo.kuleuven.be/portal/",
  domains: ["kuleuven.be"],
  background: "#FFFFFF",
});
