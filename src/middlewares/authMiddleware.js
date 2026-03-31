const jwt = require("jsonwebtoken");

const User = require("../models/User");
const ApiError = require("../utils/apiError");

async function authMiddleware(req, res, next) {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    throw new ApiError(401, "Authorization token is required.");
  }

  const token = authHeader.split(" ")[1];
  const decoded = jwt.verify(token, process.env.JWT_SECRET);
  const user = await User.findById(decoded.userId);

  if (!user) {
    throw new ApiError(401, "Invalid token.");
  }

  req.user = user;
  next();
}

module.exports = authMiddleware;
