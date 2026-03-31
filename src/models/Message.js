const mongoose = require("mongoose");

const { MESSAGE_TYPE } = require("../config/constants");

const messageSchema = new mongoose.Schema(
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
    message: {
      type: String,
      default: null,
      trim: true
    },
    type: {
      type: String,
      enum: Object.values(MESSAGE_TYPE),
      default: MESSAGE_TYPE.TEXT
    },
    file: {
      type: String,
      default: null
    }
  },
  {
    timestamps: true,
    versionKey: false
  }
);

messageSchema.index({ sender: 1, receiver: 1, createdAt: 1 });

module.exports = mongoose.model("Message", messageSchema);
