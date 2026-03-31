module.exports = {
  OTP: process.env.STATIC_OTP || "00000",
  CONNECTION_STATUS: {
    PENDING: "pending",
    ACCEPTED: "accepted",
    REJECTED: "rejected"
  },
  MESSAGE_TYPE: {
    TEXT: "text",
    AUDIO: "audio",
    VIDEO: "video"
  },
  CALL_TYPE: {
    AUDIO: "audio",
    VIDEO: "video"
  },
  CALL_STATUS: {
    RINGING: "ringing",
    ACCEPTED: "accepted",
    ENDED: "ended"
  }
};
