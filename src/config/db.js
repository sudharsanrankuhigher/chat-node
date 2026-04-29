const mongoose = require("mongoose");

async function connectDB() {
  const uri = process.env.MONGODB_URI;
  const serverSelectionTimeoutMS = Number(
    process.env.MONGODB_SERVER_SELECTION_TIMEOUT_MS || 10000
  );

  if (!uri) {
    throw new Error("MONGODB_URI is not configured.");
  }

  await mongoose.connect(uri, {
    serverSelectionTimeoutMS
  });
  console.log("MongoDB connected");
}

module.exports = connectDB;
