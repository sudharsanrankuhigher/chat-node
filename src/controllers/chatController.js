const Connection = require("../models/Connection");
const Message = require("../models/Message");
const ApiError = require("../utils/apiError");
const { CONNECTION_STATUS, MESSAGE_TYPE } = require("../config/constants");

async function ensureConnected(userId, otherUserId) {
  const connection = await Connection.findOne({
    status: CONNECTION_STATUS.ACCEPTED,
    $or: [
      { sender: userId, receiver: otherUserId },
      { sender: otherUserId, receiver: userId }
    ]
  });

  if (!connection) {
    throw new ApiError(403, "Users are not accepted connections.");
  }
}

async function sendMessage(req, res) {
  const { receiverId, message, type = MESSAGE_TYPE.TEXT, file = null } = req.body;

  if (!receiverId) {
    throw new ApiError(422, "receiverId is required.");
  }

  if (!Object.values(MESSAGE_TYPE).includes(type)) {
    throw new ApiError(422, "Invalid message type.");
  }

  if (type === MESSAGE_TYPE.TEXT && !message) {
    throw new ApiError(422, "message is required for text messages.");
  }

  if (type !== MESSAGE_TYPE.TEXT && !file) {
    throw new ApiError(422, "file is required for audio/video messages.");
  }

  await ensureConnected(req.user._id, receiverId);

  const createdMessage = await Message.create({
    sender: req.user._id,
    receiver: receiverId,
    message: message || null,
    type,
    file
  });

  await createdMessage.populate("sender receiver", "name mobile");

  const io = req.app.get("io");
  io.to(`user:${receiverId}`).emit("message:received", createdMessage);

  res.status(201).json({
    success: true,
    message: "Message sent successfully.",
    data: createdMessage
  });
}

async function getChatHistory(req, res) {
  const { userId } = req.params;

  await ensureConnected(req.user._id, userId);

  const messages = await Message.find({
    $or: [
      { sender: req.user._id, receiver: userId },
      { sender: userId, receiver: req.user._id }
    ]
  })
    .populate("sender receiver", "name mobile")
    .sort({ createdAt: 1 });

  res.json({
    success: true,
    data: messages
  });
}

module.exports = {
  sendMessage,
  getChatHistory,
  ensureConnected
};
