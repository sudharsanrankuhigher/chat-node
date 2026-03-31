const User = require("../models/User");
const generateToken = require("../utils/generateToken");
const ApiError = require("../utils/apiError");
const { OTP } = require("../config/constants");

async function sendOtp(req, res) {
  const { mobile, name } = req.body;

  if (!mobile) {
    throw new ApiError(422, "Mobile is required.");
  }

  let user = await User.findOne({ mobile });

  if (!user) {
    user = await User.create({
      mobile,
      name: name || `User ${mobile.slice(-4)}`,
      otp: OTP
    });
  } else {
    user.otp = OTP;
    if (name) {
      user.name = name;
    }
    await user.save();
  }

  res.json({
    success: true,
    message: "OTP sent successfully.",
    data: {
      otp: OTP,
      user
    }
  });
}

async function verifyOtp(req, res) {
  const { mobile, otp } = req.body;

  if (!mobile || !otp) {
    throw new ApiError(422, "Mobile and OTP are required.");
  }

  const user = await User.findOne({ mobile });

  if (!user) {
    throw new ApiError(404, "User not found.");
  }

  if (otp !== user.otp) {
    throw new ApiError(422, "Invalid OTP.");
  }

  user.otp = null;
  user.otpVerifiedAt = new Date();
  await user.save();

  const token = generateToken(user._id.toString());

  res.json({
    success: true,
    message: "OTP verified successfully.",
    data: {
      token,
      user
    }
  });
}

module.exports = {
  sendOtp,
  verifyOtp
};
