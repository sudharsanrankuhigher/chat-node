const User = require("../models/User");
const generateToken = require("../utils/generateToken");
const ApiError = require("../utils/apiError");
const { OTP } = require("../config/constants");

function normalizePhone(payload) {
  if (!payload) return "";

  const phone = payload.phone ?? payload.mobile ?? "";

  return typeof phone === "string"
    ? phone.trim()
    : String(phone).trim();
}

function formatAuthResponse(user, overrides = {}) {
  return {
    token: overrides.token || generateToken(user._id.toString()),
    isNewUser: !user.isRegistered,
    user: {
      _id: user._id,
      id: user._id,
      name: user.name,
      phone: user.mobile,
      mobile: user.mobile,
      walletBalance: user.walletBalance,
      isRegistered: user.isRegistered
    }
  };
}

async function sendOtp(req, res) {
  const phone = normalizePhone(req.body);

  if (!phone) {
    throw new ApiError(422, "Phone is required.");
  }

  let user = await User.findOne({ mobile: phone });

  if (!user) {
    user = await User.create({
      mobile: phone,
      otp: OTP
    });
  } else {
    user.otp = OTP;
    await user.save();
  }

  res.json({
    success: true,
    message: "OTP sent successfully.",
    data: {
      otp: OTP,
      user: formatAuthResponse(user, { token: "" }).user
    }
  });
}

async function verifyOtp(req, res) {
  const phone = normalizePhone(req.body);
  const { otp } = req.body;

  if (!phone || !otp) {
    throw new ApiError(422, "Phone and OTP are required.");
  }

  const user = await User.findOne({ mobile: phone });

  if (!user) {
    throw new ApiError(404, "User not found.");
  }

  if (otp !== user.otp) {
    throw new ApiError(422, "Invalid OTP.");
  }

  user.otp = null;
  user.otpVerifiedAt = new Date();
  await user.save();

  res.json({
    success: true,
    message: "OTP verified successfully.",
    data: formatAuthResponse(user)
  });
}

async function register(req, res) {
  const phone = normalizePhone(req.body);
  const { name } = req.body;

  if (!phone || !name) {
    throw new ApiError(422, "Phone and name are required.");
  }

  const user = await User.findOne({ mobile: phone });

  if (!user) {
    throw new ApiError(404, "User not found.");
  }

  user.name = String(name).trim();
  user.isRegistered = true;
  await user.save();

  res.json({
    success: true,
    message: "Registration completed successfully.",
    data: formatAuthResponse(user)
  });
}

module.exports = {
  sendOtp,
  verifyOtp,
  register
};
