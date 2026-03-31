const walletService = require("../services/walletService");
const ApiError = require("../utils/apiError");

async function addMoney(req, res) {
  const amount = Number(req.body.amount);

  if (!amount || amount <= 0) {
    throw new ApiError(422, "Valid amount is required.");
  }

  const user = await walletService.addMoney(req.user._id, amount);

  res.json({
    success: true,
    message: "Money added successfully.",
    data: {
      walletBalance: user.walletBalance
    }
  });
}

async function getWallet(req, res) {
  res.json({
    success: true,
    data: {
      walletBalance: req.user.walletBalance
    }
  });
}

module.exports = {
  addMoney,
  getWallet
};
