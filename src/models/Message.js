const mongoose = require("mongoose");

const { MESSAGE_TYPE } = require("../config/constants");

const messageSchema = new mongoose.Schema(
  {
    sender: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      default: null
    },
    receiver: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      default: null
    },
    senderUserId: {
      type: String,
      default: null,
      trim: true
    },
    receiverUserId: {
      type: String,
      default: null,
      trim: true
    },
    chatId: {
      type: String,
      required: true,
      trim: true
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
messageSchema.index({ senderUserId: 1, receiverUserId: 1, createdAt: 1 });
messageSchema.index({ chatId: 1, createdAt: 1 });

module.exports = mongoose.model("Message", messageSchema);
