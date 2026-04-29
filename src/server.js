require("dotenv").config();

const http = require("http");
const socketIo = require("socket.io");
const jwt = require("jsonwebtoken");
const mongoose = require("mongoose");

const app = require("./app");
const connectDB = require("./config/db");
const {
  createSocketMessage,
  toSocketMessagePayload
} = require("./services/socketMessageService");
const User = require("./models/User");
const Call = require("./models/Call");
const { buildChatId } = require("./controllers/chatController");
const { CALL_STATUS } = require("./config/constants");

const PORT = process.env.PORT || 5000;
const users = new Map();
const socketUsers = new Map();

function emitOnlineUsers(io) {
  io.emit("online_users", Array.from(users.keys()));
}

function registerUser(socket, io, userId) {
  if (!userId) {
    return;
  }

  const normalizedUserId = String(userId);
  const previousUserId = socketUsers.get(socket.id);

  if (previousUserId) {
    users.delete(previousUserId);
    socket.leave(`user:${previousUserId}`);
  }

  users.set(normalizedUserId, socket.id);
  socketUsers.set(socket.id, normalizedUserId);
  socket.join(`user:${normalizedUserId}`);

  console.log(`User connected: ${normalizedUserId} (${socket.id})`);
  emitOnlineUsers(io);
}

function unregisterUser(socket, io) {
  const userId = socketUsers.get(socket.id);

  if (!userId) {
    console.log(`Socket disconnected: ${socket.id}`);
    return;
  }

  users.delete(userId);
  socketUsers.delete(socket.id);

  console.log(`User disconnected: ${userId} (${socket.id})`);
  emitOnlineUsers(io);
}

function getUserSocketId(userId) {
  return users.get(String(userId));
}

async function bootstrap() {
  await connectDB();

  const server = http.createServer(app);
  const io = socketIo(server, {
    cors: {
      origin: "*",
      credentials: true
    }
  });

  io.use(async (socket, next) => {
    try {
      const token = socket.handshake.auth?.token;

      if (token) {
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        const user = await User.findById(decoded.userId);

        if (!user) {
          return next(new Error("Invalid token."));
        }

        socket.user = user;
        registerUser(socket, io, user._id.toString());
        return next();
      }

      const initialUserId =
        socket.handshake.auth?.userId || socket.handshake.query?.userId;

      if (initialUserId) {
        registerUser(socket, io, initialUserId);
      }

      next();
    } catch (error) {
      next(error);
    }
  });

  io.on("connection", (socket) => {
    console.log(`Socket connected: ${socket.id}`);

    emitOnlineUsers(io);

    socket.on("register_user", (userId) => {
      registerUser(socket, io, userId);
    });

    socket.on("send_message", async ({ senderId, receiverId, message } = {}) => {
      if (!senderId || !receiverId || typeof message === "undefined") {
        return;
      }

      const createdMessage = await createSocketMessage({
        senderId,
        receiverId,
        message
      });

      if (!createdMessage) {
        return;
      }

      const payload = toSocketMessagePayload(createdMessage);

      const receiverSocketId = getUserSocketId(receiverId);

      if (receiverSocketId) {
        io.to(receiverSocketId).emit("receive_message", payload);
      }

      io.to(`user:${receiverId}`).emit("receive_message", payload);
      io.to(`user:${senderId}`).emit("message_sent", payload);
    });

    socket.on("callUser", async ({ from, to, offer, callType = "audio" } = {}) => {
      if (!from || !to || !offer) {
        return;
      }

      const call = await Call.create({
        caller: new mongoose.Types.ObjectId(String(from)),
        receiver: new mongoose.Types.ObjectId(String(to)),
        type: callType,
        status: CALL_STATUS.RINGING
      });

      const payload = {
        callId: call._id.toString(),
        chatId: buildChatId(from, to),
        from,
        to,
        offer,
        callType
      };
      const receiverSocketId = getUserSocketId(to);

      if (receiverSocketId) {
        io.to(receiverSocketId).emit("incomingCall", payload);
      }

      io.to(`user:${to}`).emit("incomingCall", payload);
      socket.emit("calling", payload);
    });

    socket.on("acceptCall", async ({ callId, from, to, answer } = {}) => {
      if (!to || !answer || !callId) {
        return;
      }

      await Call.findByIdAndUpdate(callId, {
        status: CALL_STATUS.ACCEPTED
      });

      const payload = {
        callId,
        from: from || socketUsers.get(socket.id),
        to,
        answer
      };
      const receiverSocketId = getUserSocketId(to);

      if (receiverSocketId) {
        io.to(receiverSocketId).emit("callAccepted", payload);
      }

      io.to(`user:${to}`).emit("callAccepted", payload);
    });

    socket.on("rejectCall", async ({ callId, from, to } = {}) => {
      if (!callId || !to) {
        return;
      }

      await Call.findByIdAndUpdate(callId, {
        status: CALL_STATUS.REJECTED
      });

      const payload = {
        callId,
        from: from || socketUsers.get(socket.id),
        to
      };

      const receiverSocketId = getUserSocketId(to);

      if (receiverSocketId) {
        io.to(receiverSocketId).emit("callRejected", payload);
      }

      io.to(`user:${to}`).emit("callRejected", payload);
      socket.emit("callRejected", payload);
    });

    socket.on("iceCandidate", ({ callId, from, to, candidate } = {}) => {
      if (!callId || !to || !candidate) {
        return;
      }

      const payload = {
        callId,
        from: from || socketUsers.get(socket.id),
        to,
        candidate
      };

      const receiverSocketId = getUserSocketId(to);

      if (receiverSocketId) {
        io.to(receiverSocketId).emit("iceCandidate", payload);
      }

      io.to(`user:${to}`).emit("iceCandidate", payload);
    });

    socket.on("endCall", async ({ callId, from, to } = {}) => {
      const callerId = from || socketUsers.get(socket.id);
      const payload = { callId, from: callerId, to };

      if (callId) {
        await Call.findByIdAndUpdate(callId, {
          status: CALL_STATUS.ENDED
        });
      }

      if (to) {
        const receiverSocketId = getUserSocketId(to);

        if (receiverSocketId) {
          io.to(receiverSocketId).emit("callEnded", payload);
        }

        io.to(`user:${to}`).emit("callEnded", payload);
      }

      socket.emit("callEnded", payload);
    });

    socket.on("disconnect", () => {
      unregisterUser(socket, io);
    });
  });

  app.set("io", io);

  server.listen(PORT, "0.0.0.0", () => {
    console.log(`Server running on http://192.168.0.175:${PORT}`);
  });
}

bootstrap();
