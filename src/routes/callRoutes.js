const router = require("express").Router();

const callController = require("../controllers/callController");

router.post("/start", callController.startCall);
router.post("/accept", callController.acceptCall);
router.post("/reject", callController.rejectCall);
router.post("/end", callController.endCall);

module.exports = router;
