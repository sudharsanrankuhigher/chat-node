const mongoose = require("mongoose");

const { CALL_STATUS, CALL_TYPE } = require("../config/constants");

const callSchema = new mongoose.Schema(
  {
    caller: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true
    },
    receiver: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true
    },
    type: {
      type: String,
      enum: Object.values(CALL_TYPE),
      required: true
    },
    status: {
      type: String,
      enum: Object.values(CALL_STATUS),
      default: CALL_STATUS.RINGING
    }
  },
  {
    timestamps: true,
    versionKey: false
  }
);

module.exports = mongoose.model("Call", callSchema);
