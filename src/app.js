require("express-async-errors");

const express = require("express");
const cors = require("cors");
const morgan = require("morgan");

const routes = require("./routes");
const errorHandler = require("./middlewares/errorHandler");

const app = express();

app.use(
  cors({
    origin: process.env.CLIENT_URL || "*",
    credentials: true
  })
);
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(morgan("dev"));

app.get("/health", (req, res) => {
  res.json({ success: true, message: "Chat Node API is running." });
});

app.use("/api", routes);
app.use(errorHandler);

module.exports = app;
