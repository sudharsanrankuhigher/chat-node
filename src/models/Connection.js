const mongoose = require("mongoose");

const { CONNECTION_STATUS } = require("../config/constants");

const connectionSchema = new mongoose.Schema(
  {
    sender: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true
    },
    receiver: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true
    },
    status: {
      type: String,
      enum: Object.values(CONNECTION_STATUS),
      default: CONNECTION_STATUS.PENDING
    }
  },
  {
    timestamps: true,
    versionKey: false
  }
);

connectionSchema.index({ sender: 1, receiver: 1 }, { unique: true });

module.exports = mongoose.model("Connection", connectionSchema);
