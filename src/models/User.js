const mongoose = require("mongoose");

const userSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      trim: true,
      default: null
    },
    mobile: {
      type: String,
      required: true,
      unique: true,
      trim: true
    },
    otp: {
      type: String,
      default: null
    },
    otpVerifiedAt: {
      type: Date,
      default: null
    },
    walletBalance: {
      type: Number,
      default: 0,
      min: 0
    }
  },
  {
    timestamps: true,
    versionKey: false,
    toJSON: {
      transform: (doc, ret) => {
        delete ret.otp;
        return ret;
      }
    }
  }
);

module.exports = mongoose.model("User", userSchema);
