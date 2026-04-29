const Connection = require("../models/Connection");
const Message = require("../models/Message");
const ApiError = require("../utils/apiError");
const { CONNECTION_STATUS, MESSAGE_TYPE } = require("../config/constants");

function buildChatId(firstUserId, secondUserId) {
  return [String(firstUserId), String(secondUserId)].sort().join("_");
}

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

async function getContacts(req, res) {
  const connections = await Connection.find({
    status: CONNECTION_STATUS.ACCEPTED,
    $or: [{ sender: req.user._id }, { receiver: req.user._id }]
  }).populate("sender receiver", "name mobile walletBalance createdAt updatedAt");

  const data = connections.map((connection) => {
    const otherUser =
      String(connection.sender._id) === String(req.user._id)
        ? connection.receiver
        : connection.sender;

    return {
      _id: otherUser._id,
      id: otherUser._id,
      name: otherUser.name,
      phone: otherUser.mobile,
      mobile: otherUser.mobile,
      chatId: buildChatId(req.user._id, otherUser._id),
      walletBalance: otherUser.walletBalance
    };
  });

  res.json({
    success: true,
    data
  });
}

async function sendMessage(req, res) {
  const {
    senderId,
    receiverId,
    message,
    type = MESSAGE_TYPE.TEXT,
    file = null
  } = req.body;

  if (!receiverId) {
    throw new ApiError(422, "receiverId is required.");
  }

  if (senderId && String(senderId) !== String(req.user._id)) {
    throw new ApiError(403, "senderId does not match the authenticated user.");
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

  const chatId = buildChatId(req.user._id, receiverId);
  const createdMessage = await Message.create({
    sender: req.user._id,
    receiver: receiverId,
    chatId,
    message: message || null,
    type,
    file
  });

  await createdMessage.populate("sender receiver", "name mobile");

  const io = req.app.get("io");
  io.to(`user:${receiverId}`).emit("receive_message", createdMessage);
  io.to(`user:${receiverId}`).emit("message:received", createdMessage);
  io.to(`user:${req.user._id}`).emit("message:sent", createdMessage);

  res.status(201).json({
    success: true,
    message: "Message sent successfully.",
    data: createdMessage
  });
}

async function getMessages(req, res) {
  const { chatId } = req.params;

  if (!chatId) {
    throw new ApiError(422, "chatId is required.");
  }

  const participants = String(chatId).split("_");

  if (
    participants.length !== 2 ||
    !participants.includes(String(req.user._id))
  ) {
    throw new ApiError(403, "Invalid chatId for the authenticated user.");
  }

  const otherUserId = participants.find(
    (participant) => participant !== String(req.user._id)
  );

  await ensureConnected(req.user._id, otherUserId);

  const messages = await Message.find({ chatId })
    .populate("sender receiver", "name mobile")
    .sort({ createdAt: 1 });

  res.json({
    success: true,
    data: messages
  });
}

module.exports = {
  buildChatId,
  getContacts,
  sendMessage,
  getMessages,
  ensureConnected
};
