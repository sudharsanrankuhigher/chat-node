const Connection = require("../models/Connection");
const User = require("../models/User");
const ApiError = require("../utils/apiError");
const { CONNECTION_STATUS } = require("../config/constants");

async function sendRequest(req, res) {
  const { receiverId } = req.body;

  if (!receiverId) {
    throw new ApiError(422, "receiverId is required.");
  }

  if (receiverId === req.user.id) {
    throw new ApiError(422, "You cannot send a request to yourself.");
  }

  const receiver = await User.findById(receiverId);

  if (!receiver) {
    throw new ApiError(404, "Receiver not found.");
  }

  const existing = await Connection.findOne({
    $or: [
      { sender: req.user._id, receiver: receiverId },
      { sender: receiverId, receiver: req.user._id }
    ]
  });

  if (existing) {
    throw new ApiError(422, "Connection request already exists.");
  }

  const connection = await Connection.create({
    sender: req.user._id,
    receiver: receiverId
  });

  await connection.populate(["sender", "receiver"]);

  res.status(201).json({
    success: true,
    message: "Connection request sent.",
    data: connection
  });
}

async function respondRequest(req, res) {
  const { connectionId, status } = req.body;

  if (!connectionId || !status) {
    throw new ApiError(422, "connectionId and status are required.");
  }

  if (![CONNECTION_STATUS.ACCEPTED, CONNECTION_STATUS.REJECTED].includes(status)) {
    throw new ApiError(422, "Invalid status.");
  }

  const connection = await Connection.findOne({
    _id: connectionId,
    receiver: req.user._id,
    status: CONNECTION_STATUS.PENDING
  });

  if (!connection) {
    throw new ApiError(404, "Pending request not found.");
  }

  connection.status = status;
  await connection.save();
  await connection.populate(["sender", "receiver"]);

  res.json({
    success: true,
    message: "Connection request updated.",
    data: connection
  });
}

async function getPendingRequests(req, res) {
  const requests = await Connection.find({
    receiver: req.user._id,
    status: CONNECTION_STATUS.PENDING
  })
    .populate("sender", "name mobile walletBalance createdAt updatedAt")
    .sort({ createdAt: -1 });

  res.json({
    success: true,
    data: requests
  });
}

async function getConnections(req, res) {
  const connections = await Connection.find({
    status: CONNECTION_STATUS.ACCEPTED,
    $or: [{ sender: req.user._id }, { receiver: req.user._id }]
  })
    .populate("sender receiver", "name mobile walletBalance createdAt updatedAt")
    .sort({ createdAt: -1 });

  const users = connections.map((connection) => {
    const senderId = connection.sender._id.toString();
    return senderId === req.user.id ? connection.receiver : connection.sender;
  });

  res.json({
    success: true,
    data: users
  });
}

async function getInvitedConnections(req, res) {
  const connections = await Connection.find({ sender: req.user._id })
    .populate("receiver", "name mobile walletBalance createdAt updatedAt")
    .sort({ createdAt: -1 });

  res.json({
    success: true,
    data: connections
  });
}

async function cancelRequest(req, res) {
  const { connectionId } = req.body;

  if (!connectionId) {
    throw new ApiError(422, "connectionId is required.");
  }

  const connection = await Connection.findOneAndDelete({
    _id: connectionId,
    sender: req.user._id,
    status: CONNECTION_STATUS.PENDING
  }).populate("receiver", "name mobile walletBalance createdAt updatedAt");

  if (!connection) {
    throw new ApiError(404, "Pending invited request not found.");
  }

  res.json({
    success: true,
    message: "Connection request cancelled.",
    data: connection
  });
}

module.exports = {
  sendRequest,
  respondRequest,
  getPendingRequests,
  getConnections,
  getInvitedConnections,
  cancelRequest
};
