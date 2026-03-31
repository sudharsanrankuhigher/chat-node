const User = require("../models/User");
const ApiError = require("../utils/apiError");

async function addMoney(userId, amount) {
  const user = await User.findById(userId);
  user.walletBalance += amount;
  await user.save();
  return user;
}

async function deductForCall(userId, amount = Number(process.env.CALL_CONNECT_CHARGE || 10)) {
  const user = await User.findById(userId);

  if (!user) {
    throw new ApiError(404, "User not found.");
  }

  if (user.walletBalance < amount) {
    throw new ApiError(422, "Insufficient wallet balance.");
  }

  user.walletBalance -= amount;
  await user.save();
  return user;
}

module.exports = {
  addMoney,
  deductForCall
};
