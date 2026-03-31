const { Server } = require("socket.io");
const jwt = require("jsonwebtoken");

const User = require("../models/User");
const Message = require("../models/Message");
const Call = require("../models/Call");
const walletService = require("../services/walletService");
const { MESSAGE_TYPE, CALL_STATUS, CALL_TYPE } = require("../config/constants");

function configureSocket(server) {
  const io = new Server(server, {
    cors: {
      origin: process.env.CLIENT_URL || "*",
      credentials: true
    }
  });

  io.use(async (socket, next) => {
    try {
      const token = socket.handshake.auth?.token;

      if (!token) {
        return next(new Error("Authentication token is required."));
      }

      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      const user = await User.findById(decoded.userId);

      if (!user) {
        return next(new Error("Invalid token."));
      }

      socket.user = user;
      next();
    } catch (error) {
      next(error);
    }
  });

  io.on("connection", (socket) => {
    const userRoom = `user:${socket.user._id}`;
    socket.join(userRoom);

    socket.on("message:send", async (payload) => {
      const message = await Message.create({
        sender: socket.user._id,
        receiver: payload.receiverId,
        message: payload.message || null,
        type: payload.type || MESSAGE_TYPE.TEXT,
        file: payload.file || null
      });

      await message.populate("sender receiver", "name mobile");

      io.to(`user:${payload.receiverId}`).emit("message:received", message);
      socket.emit("message:sent", message);
    });

    socket.on("call:start", async (payload) => {
      const call = await Call.create({
        caller: socket.user._id,
        receiver: payload.receiverId,
        type: payload.type || CALL_TYPE.AUDIO,
        status: CALL_STATUS.RINGING
      });

      await call.populate("caller receiver", "name mobile");
      io.to(`user:${payload.receiverId}`).emit("call:incoming", call);
    });

    socket.on("call:accept", async ({ callId }) => {
      const call = await Call.findById(callId).populate("caller receiver", "name mobile");

      if (!call) {
        return;
      }

      await walletService.deductForCall(call.caller._id);
      call.status = CALL_STATUS.ACCEPTED;
      await call.save();

      io.to(`user:${call.caller._id}`).emit("call:accepted", call);
      io.to(`user:${call.receiver._id}`).emit("call:accepted", call);
    });

    socket.on("call:end", async ({ callId }) => {
      const call = await Call.findById(callId).populate("caller receiver", "name mobile");

      if (!call) {
        return;
      }

      call.status = CALL_STATUS.ENDED;
      await call.save();

      io.to(`user:${call.caller._id}`).emit("call:ended", call);
      io.to(`user:${call.receiver._id}`).emit("call:ended", call);
    });
  });

  appIo(io);
  return io;
}

let ioInstance = null;

function appIo(io) {
  ioInstance = io;
}

configureSocket.getIO = function getIO() {
  return ioInstance;
};

module.exports = configureSocket;
