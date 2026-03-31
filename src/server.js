require("dotenv").config();

const http = require("http");
const socketIo = require("socket.io");

const app = require("./app");
const connectDB = require("./config/db");

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

  io.on("connection", (socket) => {
    console.log(`Socket connected: ${socket.id}`);

    const initialUserId =
      socket.handshake.auth?.userId ||
      socket.handshake.query?.userId;

    if (initialUserId) {
      registerUser(socket, io, initialUserId);
    } else {
      emitOnlineUsers(io);
    }

    socket.on("register_user", (userId) => {
      registerUser(socket, io, userId);
    });

    socket.on("send_message", ({ senderId, receiverId, message } = {}) => {
      if (!senderId || !receiverId || typeof message === "undefined") {
        return;
      }

      const payload = {
        senderId,
        receiverId,
        message
      };

      const receiverSocketId = getUserSocketId(receiverId);

      if (receiverSocketId) {
        io.to(receiverSocketId).emit("receive_message", payload);
      }

      io.to(`user:${receiverId}`).emit("receive_message", payload);
    });

    socket.on("call_user", ({ from, to, offer } = {}) => {
      if (!from || !to || !offer) {
        return;
      }

      const payload = { from, to, offer };
      const receiverSocketId = getUserSocketId(to);

      if (receiverSocketId) {
        io.to(receiverSocketId).emit("incoming_call", payload);
      }

      io.to(`user:${to}`).emit("incoming_call", payload);
    });

    socket.on("answer_call", ({ from, to, answer } = {}) => {
      if (!to || !answer) {
        return;
      }

      const payload = {
        from: from || socketUsers.get(socket.id),
        to,
        answer
      };
      const receiverSocketId = getUserSocketId(to);

      if (receiverSocketId) {
        io.to(receiverSocketId).emit("call_accepted", payload);
      }

      io.to(`user:${to}`).emit("call_accepted", payload);
    });

    socket.on("end_call", ({ from, to } = {}) => {
      const callerId = from || socketUsers.get(socket.id);
      const payload = { from: callerId, to };

      if (to) {
        const receiverSocketId = getUserSocketId(to);

        if (receiverSocketId) {
          io.to(receiverSocketId).emit("call_ended", payload);
        }

        io.to(`user:${to}`).emit("call_ended", payload);
      }

      socket.emit("call_ended", payload);
    });

    socket.on("disconnect", () => {
      unregisterUser(socket, io);
    });
  });

  app.set("io", io);

  server.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
  });
}

bootstrap();
