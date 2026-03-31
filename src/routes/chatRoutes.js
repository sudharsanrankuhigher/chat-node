const router = require("express").Router();

const chatController = require("../controllers/chatController");

router.post("/send-message", chatController.sendMessage);
router.get("/history/:userId", chatController.getChatHistory);

module.exports = router;
