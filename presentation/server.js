const express = require("express");
const path = require("path");

const app = express();
const PORT = process.env.PORT || 8080;

const slides = require("./slides.json");

app.get("/api/slides", (_req, res) => {
  res.json(slides);
});

app.use(express.static(path.join(__dirname, "public")));

app.use((req, res, next) => {
  if (req.method !== "GET" || req.path.startsWith("/api/")) {
    return next();
  }
  res.sendFile(path.join(__dirname, "public", "index.html"));
});

app.listen(PORT, () => {
  console.log(`Presentation server running at http://localhost:${PORT}`);
});
