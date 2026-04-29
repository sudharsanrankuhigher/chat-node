const Message = require("../models/Message");
const { MESSAGE_TYPE } = require("../config/constants");

function buildChatId(senderId, receiverId) {
  return [String(senderId), String(receiverId)].sort().join("_");
}

async function createSocketMessage({ senderId, receiverId, message }) {
  const normalizedSenderId = String(senderId || "").trim();
  const normalizedReceiverId = String(receiverId || "").trim();
  const normalizedMessage = typeof message === "string" ? message.trim() : "";

  if (!normalizedSenderId || !normalizedReceiverId || !normalizedMessage) {
    return null;
  }

  return Message.create({
    senderUserId: normalizedSenderId,
    receiverUserId: normalizedReceiverId,
    chatId: buildChatId(normalizedSenderId, normalizedReceiverId),
    message: normalizedMessage,
    type: MESSAGE_TYPE.TEXT
  });
}

function toSocketMessagePayload(messageDoc) {
  if (!messageDoc) {
    return null;
  }

  return {
    id: messageDoc._id.toString(),
    chatId:
      messageDoc.chatId ||
      buildChatId(
        messageDoc.senderUserId || messageDoc.sender?.toString() || "",
        messageDoc.receiverUserId || messageDoc.receiver?.toString() || ""
      ),
    senderId: messageDoc.senderUserId || messageDoc.sender?.toString() || "",
    receiverId: messageDoc.receiverUserId || messageDoc.receiver?.toString() || "",
    message: messageDoc.message || "",
    timestamp: messageDoc.createdAt
      ? messageDoc.createdAt.toISOString()
      : new Date().toISOString()
  };
}

module.exports = {
  createSocketMessage,
  toSocketMessagePayload
};
