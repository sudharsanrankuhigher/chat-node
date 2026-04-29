const Call = require("../models/Call");
const ApiError = require("../utils/apiError");
const { CALL_STATUS, CALL_TYPE } = require("../config/constants");
const { ensureConnected } = require("./chatController");
const walletService = require("../services/walletService");

async function startCall(req, res) {
  const { receiverId, type } = req.body;

  if (!receiverId || !type) {
    throw new ApiError(422, "receiverId and type are required.");
  }

  if (!Object.values(CALL_TYPE).includes(type)) {
    throw new ApiError(422, "Invalid call type.");
  }

  await ensureConnected(req.user._id, receiverId);

  const call = await Call.create({
    caller: req.user._id,
    receiver: receiverId,
    type,
    status: CALL_STATUS.RINGING
  });

  await call.populate("caller receiver", "name mobile");

  const io = req.app.get("io");
  io.to(`user:${receiverId}`).emit("call:incoming", call);

  res.status(201).json({
    success: true,
    message: "Call started successfully.",
    data: call
  });
}

async function acceptCall(req, res) {
  const { callId } = req.body;

  const call = await Call.findOne({
    _id: callId,
    receiver: req.user._id,
    status: CALL_STATUS.RINGING
  }).populate("caller receiver", "name mobile walletBalance");

  if (!call) {
    throw new ApiError(404, "Active incoming call not found.");
  }

  await walletService.deductForCall(call.caller._id);

  call.status = CALL_STATUS.ACCEPTED;
  await call.save();

  const io = req.app.get("io");
  io.to(`user:${call.caller._id}`).emit("call:accepted", call);
  io.to(`user:${call.receiver._id}`).emit("call:accepted", call);

  res.json({
    success: true,
    message: "Call accepted successfully.",
    data: call
  });
}

async function rejectCall(req, res) {
  const { callId } = req.body;

  const call = await Call.findOne({
    _id: callId,
    receiver: req.user._id,
    status: CALL_STATUS.RINGING
  }).populate("caller receiver", "name mobile");

  if (!call) {
    throw new ApiError(404, "Active incoming call not found.");
  }

  call.status = CALL_STATUS.REJECTED;
  await call.save();

  const io = req.app.get("io");
  io.to(`user:${call.caller._id}`).emit("call:rejected", call);
  io.to(`user:${call.receiver._id}`).emit("call:rejected", call);

  res.json({
    success: true,
    message: "Call rejected successfully.",
    data: call
  });
}

async function endCall(req, res) {
  const { callId } = req.body;

  const call = await Call.findOne({
    _id: callId,
    $or: [{ caller: req.user._id }, { receiver: req.user._id }],
    status: { $in: [CALL_STATUS.RINGING, CALL_STATUS.ACCEPTED] }
  }).populate("caller receiver", "name mobile");

  if (!call) {
    throw new ApiError(404, "Call not found.");
  }

  call.status = CALL_STATUS.ENDED;
  await call.save();

  const io = req.app.get("io");
  io.to(`user:${call.caller._id}`).emit("call:ended", call);
  io.to(`user:${call.receiver._id}`).emit("call:ended", call);

  res.json({
    success: true,
    message: "Call ended successfully.",
    data: call
  });
}

module.exports = {
  startCall,
  acceptCall,
  rejectCall,
  endCall
};
