async function getProfile(req, res) {
  res.json({
    success: true,
    data: req.user
  });
}

async function updateProfile(req, res) {
  const { name } = req.body;

  if (typeof name !== "undefined") {
    req.user.name = name;
  }

  await req.user.save();

  res.json({
    success: true,
    message: "Profile updated successfully.",
    data: req.user
  });
}

module.exports = {
  getProfile,
  updateProfile
};
