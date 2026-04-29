const User = require("../models/User");

async function getUsers(req, res) {
  const users = await User.find({
    _id: { $ne: req.user._id }
  })
    .select("name mobile walletBalance createdAt updatedAt")
    .sort({ createdAt: -1 });

  res.json({
    success: true,
    data: users
  });
}

module.exports = {
  getUsers
};
